require 'java'
require 'rbconfig'

require 'ffi'

require_relative './entities'
require_relative './pdf_render'
require_relative './extraction'

java_import javax.imageio.ImageIO
java_import java.awt.image.BufferedImage
java_import org.apache.pdfbox.pdmodel.PDDocument

module Tabula
  module LSD
    extend FFI::Library
    ffi_lib File.expand_path('../../ext/' + case RbConfig::CONFIG['host_os']
                                            when /mswin|msys|mingw|cygwin|bccwin|wince|emc/
                                              if RbConfig::CONFIG['host_cpu'] == 'x86_64'
                                                'liblsd64.dll'
                                              else
                                                'liblsd.dll'
                                              end
                                            when /darwin|mac os/
                                              'liblsd.dylib'
                                            when /linux/
                                              if RbConfig::CONFIG['target_cpu'] == 'x86_64'
                                                'liblsd-linux64.so'
                                              else
                                                'liblsd-linux32.so'
                                              end
                                            else
                                              raise "unknown os: #{RbConfig::CONFIG['host_os']}"
                                            end,
                             File.dirname(__FILE__))

    attach_function :lsd, [ :pointer, :buffer_in, :int, :int ], :pointer
    attach_function :free_values, [ :pointer ], :void

    DETECT_LINES_DEFAULTS = {
      :scale_factor => nil,
      :image_size => 2048
    }

    def LSD.detect_lines_in_pdf(pdf_path, options={})
      options = DETECT_LINES_DEFAULTS.merge(options)

      pdf_file = PDDocument.loadNonSeq(java.io.File.new(pdf_path), nil)
      lines = pdf_file.getDocumentCatalog.getAllPages.to_a.map do |page|
        bi = Tabula::Render.pageToBufferedImage(page, options[:image_size])
        detect_lines(bi, options[:scale_factor] || (page.findCropBox.width / options[:image_size]))
      end
      pdf_file.close
      lines
    end

    #zero-indexed page_number
    def LSD.detect_lines_in_pdf_page(pdf_path, page_number, options={})
      options = DETECT_LINES_DEFAULTS.merge(options)

      pdf_file = Extraction.openPDF(pdf_path)
      page = pdf_file.getDocumentCatalog.getAllPages[page_number]
      bi = Tabula::Render.pageToBufferedImage(page,
                                              options[:image_size])
      pdf_file.close
      detect_lines(bi,
                   options[:scale_factor] || (page.findCropBox.width / options[:image_size]))
    end

    # image can be either a string (path to image) or a Java::JavaAwtImage::BufferedImage
    # image to pixels: http://stackoverflow.com/questions/6524196/java-get-pixel-array-from-image
    def LSD.detect_lines(image, scale_factor=1)

      bimage = if image.class == Java::JavaAwtImage::BufferedImage
                 image
               elsif image.class == String
                 ImageIO.read(java.io.File.new(image))
               else
                 raise ArgumentError, 'image must be a string or a BufferedImage'
               end

      image = LSD.image_to_image_float(bimage)

      lines_found_ptr = FFI::MemoryPointer.new(:int, 1)

      out = lsd(lines_found_ptr, image, bimage.getWidth, bimage.getHeight)

      lines_found = lines_found_ptr.get_int

      rv = []
      lines_found.times do |i|
        a = out[7*4*i].read_array_of_type(:float, 7)

        a_round = a[0..3].map(&:round)
        p1, p2 = [[a_round[0], a_round[1]], [a_round[2], a_round[3]]]

        rv << Tabula::Ruling.new(p1[1] * scale_factor,
                                 p1[0] * scale_factor,
                                 (p2[0] - p1[0]) * scale_factor,
                                 (p2[1] - p1[1]) * scale_factor)
      end

      free_values(out)
      bimage.flush
      bimage.getGraphics.dispose
      image = nil

      return rv
    end

    private

    def LSD.image_to_image_float(buffered_image)
      width = buffered_image.getWidth; height = buffered_image.getHeight
      raster_size = width * height

      image_float = FFI::MemoryPointer.new(:float, raster_size)
      pixels = Java::int[width * height].new
      buffered_image.getRGB(0, 0, width, height, pixels, 0, width)

      image_float.put_array_of_float 0, pixels.to_a
    end


  end
end

if __FILE__ == $0
  puts Tabula::LSD.detect_lines_in_pdf_page ARGV[0], ARGV[1].to_i
end
