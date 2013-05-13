require 'java'
require 'rbconfig'

require 'ffi'

require_relative './entities'



java_import javax.imageio.ImageIO
java_import java.awt.image.BufferedImage

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

    # image to pixels: http://stackoverflow.com/questions/6524196/java-get-pixel-array-from-image
    def LSD.detect_lines(image_path)
      bimage = ImageIO.read(java.io.File.new(image_path))
      image = LSD.image_to_image_double(bimage)

      lines_found_ptr = FFI::MemoryPointer.new(:int, 1)

      out = lsd(lines_found_ptr, image, bimage.getWidth, bimage.getHeight)

      lines_found = lines_found_ptr.get_int

      rv = []
      lines_found.times do |i|
        # TODO generate and return Line objects
        a = out[7*8*i].read_array_of_type(:double, 7)
        rv << Tabula::Ruling.new(a[1],
                                 a[0],
                                 a[2] - a[0],
                                 a[3] - a[1])
      end
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
  puts Tabula::LSD.detect_lines ARGV[0]
end
