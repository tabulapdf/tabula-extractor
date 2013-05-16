require 'java'

require File.join(File.dirname(__FILE__), '../../target/pdfbox-app-1.8.0.jar')
java_import org.apache.pdfbox.pdmodel.PDDocument
java_import org.apache.pdfbox.pdfviewer.PageDrawer
java_import java.awt.image.BufferedImage
java_import javax.imageio.ImageIO
java_import java.awt.Dimension
java_import java.awt.Color

module Tabula
  module Render

    # render a PDF page to a graphics context, but skip rendering the text
    class PageDrawerNoText < PageDrawer
      def processTextPosition(text)
      end
    end

    TRANSPARENT_WHITE = Color.new(255, 255, 255, 0)

    # 2048 width is important, if this is too small, thin lines won't be drawn.
    def self.pageToBufferedImage(page, width=2048, pageDrawerClass=PageDrawerNoText)
      cropbox = page.findCropBox
      widthPt, heightPt = cropbox.getWidth, cropbox.getHeight
      pageDimension = Dimension.new(widthPt, heightPt)

      scaling = width / widthPt
      widthPx, heightPx = java.lang.Math.round(widthPt * scaling), java.lang.Math.round(heightPt * scaling)
      
      rotation = java.lang.Math.toRadians(page.findRotation)
      retval = if rotation != 0
                 BufferedImage.new(heightPx, widthPx, BufferedImage::TYPE_BYTE_GRAY)
               else
                 BufferedImage.new(widthPx, heightPx, BufferedImage::TYPE_BYTE_GRAY)
               end
      graphics = retval.getGraphics()
      graphics.setBackground(TRANSPARENT_WHITE)
      graphics.clearRect(0, 0, retval.getWidth, retval.getHeight)
      if rotation != 0
        graphics.translate(retval.getWidth, 0.0)
        graphics.rotate(rotation)
      end
      graphics.scale(scaling, scaling)
      drawer = pageDrawerClass.new()
      drawer.drawPage(graphics,  page, pageDimension)
      graphics.dispose
      return retval
    end
  end
end

# testing
if __FILE__ == $0
  pdf_file = PDDocument.loadNonSeq(java.io.File.new(ARGV[0]), nil)
  bi = Tabula::Render.pageToBufferedImage(pdf_file.getDocumentCatalog.getAllPages[ARGV[1].to_i - 1])
  ImageIO.write(bi, 'png',
                java.io.File.new('notext.png'))
end

