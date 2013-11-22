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
java_import java.awt.Color

require_relative './core_ext'
require_relative './line_segment_detector'
require_relative './entities'

class Tabula::Extraction::LineExtractor < org.apache.pdfbox.util.PDFStreamEngine

  attr_accessor :currentX, :currentY
  attr_accessor :currentPath
  attr_accessor :rulings
  attr_accessor :options
  field_accessor :page

  DETECT_LINES_DEFAULTS = {
    :snapping_grid_cell_size => 2
  }

  def self.collapse_vertical_rulings(lines) #lines should all be of one orientation (i.e. horizontal, vertical)
    lines.sort!{|a, b| a.left != b.left ? a.left <=> b.left : a.top <=> b.top }
    lines.inject([]) do |memo, next_line|
      if memo.last && next_line.left == memo.last.left && memo.last.nearlyIntersects?(next_line)
        memo.last.top = [next_line.top, memo.last.top].min
        memo.last.bottom = [next_line.bottom, memo.last.bottom].max
        memo
      else
        memo << next_line
      end
    end
  end

  def self.collapse_horizontal_rulings(lines) #lines should all be of one orientation (i.e. horizontal, vertical)
    lines.sort!{|a, b| a.top != b.top ? a.top <=> b.top : a.left <=> b.left }
    lines.inject([]) do |memo, next_line|
      if memo.last && next_line.top == memo.last.top && memo.last.nearlyIntersects?(next_line)
        memo.last.left = [next_line.left, memo.last.left].min
        memo.last.right = [next_line.right, memo.last.right].max
        memo
      else
        memo << next_line
      end
    end
  end

  #N.B. for merge `spreadsheets` into `text-extractor-refactor` --
  # only substantive change here is calling Tabula::Ruling::clean_rulings on LSD output in this method
  # the rest is readability changes.
  #page_number here is zero-indexed
  def self.lines_in_pdf_page(pdf_path, page_number, options={})
    options = options.merge!(DETECT_LINES_DEFAULTS)
    rulings = unless options[:render_pdf]
                pdf_file = ::Tabula::Extraction.openPDF(pdf_path)
                page = pdf_file.getDocumentCatalog.getAllPages[page_number]
                le = self.new(options)
                le.processStream(page, page.findResources, page.getContents.getStream)
                pdf_file.close
                le.rulings.map do |l|
                  top = [l.getP1.getY, l.getP2.getY].min
                  left = [l.getP1.getX, l.getP1.getX].min
                  ::Tabula::Ruling.new(top,
                                       left,
                                       (l.getP2.getX - l.getP1.getX).abs,
                                       (l.getP2.getY - l.getP1.getY).abs)
                end
              else
                Tabula::LSD::detect_lines_in_pdf_page(pdf_path, page_number, options)
              end
  end

  class LineToOperator < OperatorProcessor
    def process(operator, arguments)
      drawer = self.context
      x, y = arguments[0], arguments[1]
      ppos = drawer.TransformedPoint(x.floatValue, y.floatValue)

      l = java.awt.geom.Line2D::Float.new(drawer.currentX, drawer.currentY, ppos.getX, ppos.getY)

      drawer.currentPath << l if l.horizontal? or l.vertical?

      drawer.currentX, drawer.currentY = ppos.getX, ppos.getY
    end
  end

  class MoveToOperator < OperatorProcessor
    def process(operator, arguments)
      drawer = self.context
      x, y = arguments[0], arguments[1]

      ppos = drawer.TransformedPoint(x.floatValue, y.floatValue)

      drawer.currentX, drawer.currentY = ppos.getX, ppos.getY
    end
  end

  class AppendRectangleToPathOperator < OperatorProcessor
    def process(operator, arguments)

      drawer = self.context
      finalX, finalY, finalW, finalH = arguments.to_array.map(&:floatValue)

      ppos = drawer.TransformedPoint(finalX, finalY)
      psize = drawer.ScaledPoint(finalW, finalH)

      finalY = ppos.getY - psize.getY
      if finalY < 0
        finalY = 0
      end

      width = psize.getX.abs
      height = psize.getY.abs

      lines = if width > height && height < 2 # horizontal line, "thin" rectangle.
                [java.awt.geom.Line2D::Float.new(ppos.getX, finalY + psize.getY/2, ppos.getX + psize.getX, finalY + psize.getY/2)]
              elsif width < height && width < 2 # vertical line, "thin" rectangle
                [java.awt.geom.Line2D::Float.new(ppos.getX + psize.getX/2, finalY, ppos.getX + psize.getX/2, finalY + psize.getY)]
              else
                # add every edge of the rectangle to drawer.rulings
                [java.awt.geom.Line2D::Float.new(ppos.getX, finalY, ppos.getX + psize.getX, finalY),
                 java.awt.geom.Line2D::Float.new(ppos.getX, finalY, ppos.getX, finalY + psize.getY),
                 java.awt.geom.Line2D::Float.new(ppos.getX+psize.getX, finalY, ppos.getX + psize.getX, finalY + psize.getY),
                 java.awt.geom.Line2D::Float.new(ppos.getX, finalY+psize.getY, ppos.getX + psize.getX, finalY + psize.getY)]
              end

      drawer.currentPath += lines.select { |l| l.horizontal? or l.vertical? }

    end
  end

  class StrokePathOperator < OperatorProcessor
    def process(operator, arguments)
      drawer = self.context

      # pretty lame, but i've never seen white lines
      # should be safe to discard
      # NOTE: temporarily disabled.
      # strokeColorComps = drawer.getGraphicsState.getStrokingColor.getJavaColor.getRGBColorComponents(nil)
      #if strokeColorComps.any? { |c| c < 0.9 }
        drawer.currentPath.each { |segment| drawer.addRuling(segment) }
      #end

      drawer.currentPath = []
    end
  end

  class CloseFillNonZeroAndStrokePathOperator < OperatorProcessor
    def process(operator, arguments)
      drawer = self.context
      # NOTE: color check temporarily disabled
      #fillColorComps = drawer.getGraphicsState.getNonStrokingColor.getJavaColor.getRGBColorComponents(nil)
#      if fillColorComps.any? { |c| c < 0.9 }
        drawer.currentPath.each { |segment| drawer.addRuling(segment) }
#      end
      drawer.currentPath = []
    end
  end

  class CloseAndStrokePathOperator < OperatorProcessor
    def process(operator, arguments)
      drawer = self.context
      drawer.currentPath.each { |segment| drawer.addRuling(segment) }
      drawer.currentPath = []
    end
  end

  class EndPathOperator < OperatorProcessor
    def process(operator, arguments)
      drawer = self.context
      # end without stroke, we don't care about it. discard it
      drawer.currentPath = []
    end
  end

  class FillNonZeroRuleOperator < OperatorProcessor
    def process(operator, arguments)
      drawer = self.context
      # end without stroke, we don't care about it. discard it
      drawer.currentPath = []
    end
  end

  OPERATOR_PROCESSORS = {
    'm' => MoveToOperator.new,
    're' => AppendRectangleToPathOperator.new,
    'l' => LineToOperator.new,
    'S' => StrokePathOperator.new,
    's' => StrokePathOperator.new,
    'n' => EndPathOperator.new,
    'b' => CloseFillNonZeroAndStrokePathOperator.new,
    'b*' => CloseFillNonZeroAndStrokePathOperator.new,
    'f' => CloseFillNonZeroAndStrokePathOperator.new,
    'f*' => CloseFillNonZeroAndStrokePathOperator.new,
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

  def initialize(options={})
    super()
    @options = options.merge!(DETECT_LINES_DEFAULTS)
    self.clear!
    OPERATOR_PROCESSORS.each { |k,v| registerOperatorProcessor(k, v) }
  end

  def clear!
    self.rulings = []
    self.currentX = -1
    self.currentY = -1
    self.currentPath = []
    @pageSize = nil
  end

  def addRuling(ruling)
    if !page.getRotation.nil? && [90, -270, -90, 270].include?(page.getRotation)

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
      ruling.transform!(scale)
    end

    # snapping to grid and joining lines that are close together
    ruling.snap!(options[:snapping_grid_cell_size])

    # merge lines, still not finished
    # close_rulings = self.rulings.find_all { |r|
    #   (ruling.vertical? && r.vertical? || ruling.horizontal? && r.horizontal?) \
    #   && (r.getP2.distance(ruling.getP1) <= options[:snapping_grid_cell_size] \
    #       || r.getP1.distance(ruling.getP2) <= options[:snapping_grid_cell_size])
    # }

    self.rulings << ruling

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

    return java.awt.geom.Point2D::Float.new(finalX, finalY);

  end

  def TransformedPoint(x, y)
    position = [x,y].to_java(:float)
    at = self.getGraphicsState.getCurrentTransformationMatrix.createAffineTransform
    at.transform(position, 0, position, 0, 1)
    position[1] = fixY(position[1])
    java.awt.geom.Point2D::Float.new(position[0], position[1])
  end

end
