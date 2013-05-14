require 'java'
require 'rbconfig'

require 'ffi'

require_relative './entities'
require_relative './pdf_render'
require File.join(File.dirname(__FILE__), '../../target/pdfbox-app-1.8.0.jar')

java_import javax.imageio.ImageIO
java_import java.awt.image.BufferedImage
java_import org.apache.pdfbox.pdmodel.PDDocument

module Tabula
  module LSD
    extend FFI::Library
    ffi_lib File.expand_path('../../ext/' + case RbConfig::CONFIG['host_os']
                                            when /mswin|msys|mingw|cygwin|bccwin|wince|emc/
                                              'liblsd.dll'
                                            when /darwin|mac os/
                                              'liblsd.dylib'
                                            when /linux/
                                              'liblsd.so'
                                            else
                                              raise "unknown os: #{RbConfig::CONFIG['host_os']}"
                                            end,
                             File.dirname(__FILE__))

    attach_function :lsd, [ :pointer, :buffer_in, :int, :int ], :pointer
    attach_function :free, [:pointer], :void


    def LSD.detect_lines_in_pdf_page(pdf_path, page_number, scale_factor=1)
      pdf_file = PDDocument.loadNonSeq(java.io.File.new(pdf_path), nil)
      bi = Tabula::Render.pageToBufferedImage(pdf_file.getDocumentCatalog.getAllPages[page_number - 1])
      detect_lines(bi,scale_factor)
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
      image = LSD.image_to_image_double(bimage)

      lines_found_ptr = FFI::MemoryPointer.new(:int, 1)

      out = lsd(lines_found_ptr, image, bimage.getWidth, bimage.getHeight)

      lines_found = lines_found_ptr.get_int

      # minimum length of detected lines = 1% of page width/height, to play safe
      # (crude noise filter)
      minimum_length_h = bimage.getWidth * 0.01
      minimum_length_v = bimage.getHeight * 0.01

      rv = []
      lines_found.times do |i|
        a = out[7*8*i].read_array_of_type(:double, 7)

        a_round = a[0..3].map(&:round)
        p1, p2 = [[a_round[0], a_round[1]], [a_round[2], a_round[3]]]

        # discard short lines
        unless ((p1[0] != p2[0]) && (p1[0] - p2[0]).abs < minimum_length_h) || \
          ((p1[1] != p2[1]) && (p1[1] - p2[1]).abs < minimum_length_v)
          rv << Tabula::Ruling.new(p1[1] * scale_factor,
                                   p1[0] * scale_factor,
                                   (p2[0] - p1[0]) * scale_factor,
                                   (p2[1] - p1[1]) * scale_factor)
        end
      end

      free(out)
      bimage.flush
      bimage.getGraphics.dispose
      image = nil

      return rv
    end

    private
    def LSD.image_to_image_double(buffered_image)
      width = buffered_image.getWidth; height = buffered_image.getHeight
      raster_size = width * height

      image_double = FFI::MemoryPointer.new(:double, raster_size)
      pixels = Java::int[width * height].new
      buffered_image.getRGB(0, 0, width, height, pixels, 0, width)

      pixels.each_with_index { |p, i|
        # this sucks, memcpy() 8 bytes at a time.
        # but I couldn't find a better way to write a double[] (java array) into
        # the Memory Pointer
        break if i == raster_size
        image_double[i].write_double(p & 0xff)
      }
      image_double
    end

  end
end

if __FILE__ == $0
  puts Tabula::LSD.detect_lines_in_pdf_page ARGV[0], ARGV[1].to_i
end
