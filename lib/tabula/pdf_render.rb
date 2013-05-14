require 'java'

require File.join(File.dirname(__FILE__), '../../target/pdfbox-app-1.8.0.jar')
java_import org.apache.pdfbox.pdfparser.PDFParser
java_import org.apache.pdfbox.pdmodel.PDDocument
java_import org.apache.pdfbox.util.PDFTextStripper
java_import org.apache.pdfbox.pdfviewer.PageDrawer
java_import java.awt.Dimension

# render a PDF page to a graphics context, but skip rendering the text
class PageDrawerNoText < PageDrawer
  def processTextPosition(text)
  end
end

# PDRectangle cropBox = findCropBox();
#         float widthPt = cropBox.getWidth();
#         float heightPt = cropBox.getHeight();
#         float scaling = resolution / (float)DEFAULT_USER_SPACE_UNIT_DPI;
#         int widthPx = Math.round(widthPt * scaling);
#         int heightPx = Math.round(heightPt * scaling);
#         //TODO The following reduces accuracy. It should really be a Dimension2D.Float.
#         Dimension pageDimension = new Dimension( (int)widthPt, (int)heightPt );
#         BufferedImage retval = null;
#         float rotation = (float)Math.toRadians(findRotation());
#         if (rotation != 0)
#         {
#             retval = new BufferedImage( heightPx, widthPx, imageType );
#         }
#         else
#         {
#             retval = new BufferedImage( widthPx, heightPx, imageType );
#         }
#         Graphics2D graphics = (Graphics2D)retval.getGraphics();
#         graphics.setBackground( TRANSPARENT_WHITE );
#         graphics.clearRect( 0, 0, retval.getWidth(), retval.getHeight() );
#         if (rotation != 0)
#         {
#             graphics.translate(retval.getWidth(), 0.0f);
#             graphics.rotate(rotation);
#         }
#         graphics.scale( scaling, scaling );
#         PageDrawer drawer = new PageDrawer();
#         drawer.drawPage( graphics, this, pageDimension );
#         return retval;

TRANSPARENT_WHITE = Color.new(255, 255, 255, 0)

def pageToBufferedImage(page, width=2048, pageDrawerClass=PageDrawerNoText)
  cropbox = page.findCropBox
  widthPt, heightPt = cropbox.getWidth, cropbox.getHeight
  pageDimension = Dimension.new(widthPt, heightPt)
  
  rotation = java.lang.Math.toRadians(page.findRotation)
  retval = if rotation != 0
             BufferedImage.new(heightPx, widthPx, BufferedImage.TYPE_BYTE_GRAY)
           else
             BufferedImage.new(widthPx, heightPx, BufferedImage.TYPE_BYTE_GRAY)
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
  return retval
end



