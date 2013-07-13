require 'java'
require File.join(File.dirname(__FILE__), '../../target/', Tabula::PDFBOX)

java_import org.apache.pdfbox.util.operator.OperatorProcessor
java_import org.apache.pdfbox.pdfparser.PDFParser
java_import org.apache.pdfbox.util.PDFStreamEngine
java_import org.apache.pdfbox.util.ResourceLoader

java_import java.awt.geom.PathIterator
java_import java.awt.geom.Point2D
java_import java.awt.geom.GeneralPath
java_import java.awt.geom.AffineTransform

require_relative './core_ext'


class Tabula::Extraction::LineExtractor < org.apache.pdfbox.util.PDFStreamEngine

  attr_accessor :currentX, :currentY
  attr_accessor :rulings
  field_accessor :page

  class LineToOperator < org.apache.pdfbox.util.operator.OperatorProcessor
    def process(operator, arguments)
      drawer = self.context
      x, y = arguments[0], arguments[1]
      ppos = drawer.TransformedPoint(x.doubleValue, y.doubleValue)

      drawer.addRuling java.awt.geom.Line2D::Double.new(drawer.currentX, drawer.currentY, ppos.getX, ppos.getY)

      drawer.currentX, drawer.currentY = ppos.getX, ppos.getY
    end
  end

  class MoveToOperator < org.apache.pdfbox.util.operator.OperatorProcessor
    def process(operator, arguments)

      drawer = self.context
      x, y = arguments[0], arguments[1]

      ppos = drawer.TransformedPoint(x.doubleValue, y.doubleValue)

      drawer.currentX, drawer.currentY = ppos.getX, ppos.getY
    end
  end

  class AppendRectangleToPathOperator < org.apache.pdfbox.util.operator.OperatorProcessor
    def process(operator, arguments)
      drawer = self.context
      finalX, finalY, finalW, finalH = arguments.to_array.map(&:doubleValue)

      ppos = drawer.TransformedPoint(finalX, finalY)
      psize = drawer.ScaledPoint(finalW, finalH)

      finalY = ppos.getY - psize.getY
      if finalY < 0
        finalY = 0
      end

      # add every edge of the rectangle to drawer.rulings
      drawer.addRuling java.awt.geom.Line2D::Double.new(ppos.getX, finalY, ppos.getX + psize.getX, finalY)
      drawer.addRuling java.awt.geom.Line2D::Double.new(ppos.getX, finalY, ppos.getX, finalY + psize.getY)
      drawer.addRuling java.awt.geom.Line2D::Double.new(ppos.getX+psize.getX, finalY, ppos.getX + psize.getX, finalY + psize.getY)
      drawer.addRuling java.awt.geom.Line2D::Double.new(ppos.getX, finalY+psize.getY, ppos.getX + psize.getX, finalY + psize.getY)

    end
  end

  DETECT_LINES_DEFAULTS = {}

  def self.lines_in_pdf_page(pdf_path, page_number, options={})
    options = DETECT_LINES_DEFAULTS.merge(options)

    pdf_file = ::Tabula::Extraction.openPDF(pdf_path)
    page = pdf_file.getDocumentCatalog.getAllPages[page_number]
    le = self.new
    le.processStream(page, page.findResources, page.getContents.getStream)

    return le.rulings
  end

  OPERATOR_PROCESSORS = {
    'm' => MoveToOperator.new,
    're' => AppendRectangleToPathOperator.new,
    'l' => LineToOperator.new,
    'BT' => org.apache.pdfbox.util.operator.BeginText.new,
    'cm' => org.apache.pdfbox.util.operator.Concatenate.new,
    'CS' => org.apache.pdfbox.util.operator.SetStrokingColorSpace.new,
    'cs' => org.apache.pdfbox.util.operator.SetNonStrokingColorSpace.new,
    'ET' => org.apache.pdfbox.util.operator.EndText.new,
    'G' => org.apache.pdfbox.util.operator.SetStrokingGrayColor.new,
    'g' => org.apache.pdfbox.util.operator.SetNonStrokingGrayColor.new,
    'gs' => org.apache.pdfbox.util.operator.SetGraphicsStateParameters.new,
    'K' => org.apache.pdfbox.util.operator.SetStrokingCMYKColor.new,
    'k' => org.apache.pdfbox.util.operator.SetNonStrokingCMYKColor.new,
    'q' => org.apache.pdfbox.util.operator.GSave.new,
    'Q' => org.apache.pdfbox.util.operator.GRestore.new,
    'RG' => org.apache.pdfbox.util.operator.SetStrokingRGBColor.new,
    'rg' => org.apache.pdfbox.util.operator.SetNonStrokingRGBColor.new,
    's' => org.apache.pdfbox.util.operator.CloseAndStrokePath.new,
    'SC' => org.apache.pdfbox.util.operator.SetStrokingColor.new,
    'sc' => org.apache.pdfbox.util.operator.SetNonStrokingColor.new,
    'SCN' => org.apache.pdfbox.util.operator.SetStrokingColor.new,
    'scn' => org.apache.pdfbox.util.operator.SetNonStrokingColor.new,
    'T*' => org.apache.pdfbox.util.operator.NextLine.new,
    'Tc' => org.apache.pdfbox.util.operator.SetCharSpacing.new,
    'Td' => org.apache.pdfbox.util.operator.MoveText.new,
    'TD' => org.apache.pdfbox.util.operator.MoveTextSetLeading.new,
    'Tf' => org.apache.pdfbox.util.operator.SetTextFont.new,
    'Tj' => org.apache.pdfbox.util.operator.ShowText.new,
    'TJ' => org.apache.pdfbox.util.operator.ShowTextGlyph.new,
    'TL' => org.apache.pdfbox.util.operator.SetTextLeading.new,
    'Tm' => org.apache.pdfbox.util.operator.SetMatrix.new,
    'Tr' => org.apache.pdfbox.util.operator.SetTextRenderingMode.new,
    'Ts' => org.apache.pdfbox.util.operator.SetTextRise.new,
    'Tw' => org.apache.pdfbox.util.operator.SetWordSpacing.new,
    'Tz' => org.apache.pdfbox.util.operator.SetHorizontalTextScaling.new,
    "\'" => org.apache.pdfbox.util.operator.MoveAndShow.new,
    '\"' => org.apache.pdfbox.util.operator.SetMoveAndShow.new,
  }


  def initialize
    super
    self.clear!
    OPERATOR_PROCESSORS.each { |k,v| registerOperatorProcessor(k, v) }
  end

  def clear!
    self.rulings = []
    self.currentX = -1; self.currentY = -1
    @pageSize = nil
  end

  def addRuling(ruling)
    if !page.getRotation.nil? and [90, -270, -90, 270].include?(page.getRotation)

      mb = page.getMediaBox
      affine_transform = AffineTransform.getQuadrantRotateInstance(self.page.getRotation / 90, mb.getLowerLeftX, mb.getLowerLeftY)

      trans = if page.getRotation == 90 || page.getRotation == -270
                AffineTransform.getTranslateInstance(mb.getHeight, 0)
              else
                AffineTransform.getTranslateInstance(0, mb.getWidth)
              end
      scale = AffineTransform.getScaleInstance(mb.getWidth / mb.getHeight,
                                               mb.getWidth / mb.getHeight)
      trans.concatenate(affine_transform)
      scale.concatenate(trans)
      self.rulings << ruling.transform!(scale)
    else
      self.rulings << ruling
    end
  end

  ##
  # get current page size
  def pageSize
    @pageSize ||= self.page.findMediaBox.createDimension
  end

  ##
  # fix the Y coordinate based on page rotation
  def fixY(y)
    pageSize.getHeight - y
  end

  def ScaledPoint(*args)
    x, y = args[0], args[1]

    # if scale factor not provided, get it from current transformation matrix
    if args.size == 2
      ctm = getGraphicsState.getCurrentTransformationMatrix
      at = ctm.createAffineTransform
      scaleX = at.getScaleX; scaleY = at.getScaleY
    else
      scaleX = args[2]; scaleY = args[3]
    end

    finalX = 0.0;
    finalY = 0.0;

    if scaleX > 0
      finalX = x * scaleX;
    end
    if scaleY > 0
      finalY = y * scaleY;
    end

    return java.awt.geom.Point2D::Double.new(finalX, finalY);

  end

  def TransformedPoint(x, y)
    position = [x,y].to_java(:double)
    at = self.getGraphicsState.getCurrentTransformationMatrix.createAffineTransform
    at.transform(position, 0, position, 0, 1)
    position[1] = fixY(position[1])
    java.awt.geom.Point2D::Double.new(position[0], position[1])
  end

end
