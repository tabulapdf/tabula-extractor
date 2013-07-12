require 'java'
require File.join(File.dirname(__FILE__), '../../target/', Tabula::PDFBOX)
java_import org.apache.pdfbox.util.operator.OperatorProcessor
java_import org.apache.pdfbox.pdfparser.PDFParser
java_import org.apache.pdfbox.util.PDFStreamEngine
java_import org.apache.pdfbox.util.ResourceLoader

java_import java.awt.geom.PathIterator
java_import java.awt.geom.Point2D
java_import java.awt.geom.Rectangle2D
java_import java.awt.geom.GeneralPath

class Tabula::Extraction::LineExtractor < org.apache.pdfbox.util.PDFStreamEngine

  # TODO: reuse Tabula::ZoneEntity
  class GenericSegment < Struct.new(:x1, :y1, :x2, :y2)
    alias_method :lower_left_x, :x1
    alias_method :lower_left_y, :y1
    alias_method :upper_right_x, :x2
    alias_method :upper_right_y, :y2

    def initialize(*args)
      super(*args)
      # correct negative dimensions
      if self.x1 > self.x2
        temp = self.x1
        self.x1 = self.x2
        self.x2 = temp
      end

      if self.y1 > self.y2
        temp = self.y1
        self.y1 = self.y2
        self.y2 = temp
      end
    end

    def to_xml
      attrs = [:x1, :x2, :y1, :y2].map { |k|
        "#{k.to_s}=\"#{self.send(k)}\""
      }.join(' ')
      "<#{self.class} #{attrs} />"
    end

    def rotate(*args)
      if args.size == 3

        pointX, pointY, amount = args

        px1 = self.x1 - pointX; px2 = self.x2 - pointX
        py1 = self.y1 - pointY; py2 = self.y2 - pointY

        if (amount == 90 || amount == -270)
          self.x1 = pointX - py2; self.x2 = pointX - py1;
          self.y1 = pointY + px1; y2 = pointY + px2;
        elsif (amount == 270 || amount == -90)
          self.x1 = pointX + py1; self.x2 = pointX + py2;
          self.y1 = pointY - px2; self.y2 = pointY - px1;
        end
      elsif args.size == 1
        page = args.first
        mediaBox = page.getMediaBox
        if !page.getRotation.nil?
          rotate(mediaBox.getLowerLeftX, mediaBox.getLowerLeftY, page.getRotation);
          if (page.getRotation == 90 || page.getRotation == -270)
            self.x1 = x1 + mediaBox.getHeight()
            self.x2 = x2 + mediaBox.getHeight()
          elsif (page.getRotation() == 270 || page.getRotation() == -90)
            self.y1 = y1 + mediaBox.getWidth()
            self.y2 = y2 + mediaBox.getWidth()
          end
        end
      end
    end
  end

  class LineSegment < GenericSegment
  end

  class RectSegment < GenericSegment

    ##
    # returns an array of the component lines of this rectangle
    def to_lines
      raise "TODO: Not Implemented!"
    end
  end


  attr_accessor :lineSubPaths, :linePath, :lineList, :rectList, :currentLines, :currentRects, :linesToAdd,  :rectsToAdd, :strokingColor
  attr_accessor :newPath, :pathContainsCurve, :pathBeginSet, :pathClosed
  attr_accessor :currentX, :currentY
  field_accessor :page


  class LineToOperator < org.apache.pdfbox.util.operator.OperatorProcessor
    def process(operator, arguments)
      drawer = self.context
      x, y = arguments[0], arguments[1]
      ppos = drawer.TransformedPoint(x.doubleValue, y.doubleValue)
      puts "LINE TO #{ppos.getX}, #{ppos.getY}"
      drawer.linePath.lineTo(ppos.getX, ppos.getY)
#      drawer.simple_line_to!(x.doubleValue, y.doubleValue)
    end
  end

  class MoveToOperator < org.apache.pdfbox.util.operator.OperatorProcessor
    def process(operator, arguments)

      drawer = self.context
      x, y = arguments[0], arguments[1]

      drawer.lineSubPaths << drawer.linePath
      newPath = java.awt.geom.GeneralPath.new
      ppos = drawer.TransformedPoint(x.doubleValue, y.doubleValue)

      puts "MOVE TO #{ppos.getX}, #{ppos.getY}"

      newPath.moveTo(ppos.getX, ppos.getY)
      drawer.linePath = newPath
      drawer.simple_move_to!(x.doubleValue, y.doubleValue)
    end
  end

  class AppendRectangleToPathOperator < org.apache.pdfbox.util.operator.OperatorProcessor
    def process(operator, arguments)
      drawer = self.context
      x, y, w, h = arguments.to_array
      finalX, finalY, finalW, finalH = x.doubleValue, y.doubleValue, w.doubleValue, h.doubleValue
      ppos = drawer.TransformedPoint(finalX, finalY)
      psize = drawer.ScaledPoint(finalW, finalH)

      finalY = ppos.getY - psize.getY
      if finalY < 0
        finalY = 0
      end

      rect = java.awt.geom.Rectangle2D::Double.new(ppos.getX, finalY, psize.getX, psize.getY)
      drawer.linePath.reset
      drawer.linePath.append(rect, false)

      drawer.new_path!
      drawer.simple_add_rect!(ppos.get_x, finalY, psize.getX, psize.getY)
    end
  end

  def initialize
    super
    self.clear!
    registerOperatorProcessor('m', MoveToOperator.new)
    registerOperatorProcessor('re', AppendRectangleToPathOperator.new)
    registerOperatorProcessor('l', LineToOperator.new)
    registerOperatorProcessor('BT', org.apache.pdfbox.util.operator.BeginText.new)
    registerOperatorProcessor('cm', org.apache.pdfbox.util.operator.Concatenate.new)
    registerOperatorProcessor('CS', org.apache.pdfbox.util.operator.SetStrokingColorSpace.new)
    registerOperatorProcessor('cs', org.apache.pdfbox.util.operator.SetNonStrokingColorSpace.new)
    registerOperatorProcessor('ET', org.apache.pdfbox.util.operator.EndText.new)
    registerOperatorProcessor('G', org.apache.pdfbox.util.operator.SetStrokingGrayColor.new)
    registerOperatorProcessor('g', org.apache.pdfbox.util.operator.SetNonStrokingGrayColor.new)
    registerOperatorProcessor('gs', org.apache.pdfbox.util.operator.SetGraphicsStateParameters.new)
    registerOperatorProcessor('K', org.apache.pdfbox.util.operator.SetStrokingCMYKColor.new)
    registerOperatorProcessor('k', org.apache.pdfbox.util.operator.SetNonStrokingCMYKColor.new)
    registerOperatorProcessor('q', org.apache.pdfbox.util.operator.GSave.new)
    registerOperatorProcessor('Q', org.apache.pdfbox.util.operator.GRestore.new)
    registerOperatorProcessor('RG', org.apache.pdfbox.util.operator.SetStrokingRGBColor.new)
    registerOperatorProcessor('rg', org.apache.pdfbox.util.operator.SetNonStrokingRGBColor.new)
    registerOperatorProcessor('s', org.apache.pdfbox.util.operator.CloseAndStrokePath.new)
    registerOperatorProcessor('SC', org.apache.pdfbox.util.operator.SetStrokingColor.new)
    registerOperatorProcessor('sc', org.apache.pdfbox.util.operator.SetNonStrokingColor.new)
    registerOperatorProcessor('SCN', org.apache.pdfbox.util.operator.SetStrokingColor.new)
    registerOperatorProcessor('scn', org.apache.pdfbox.util.operator.SetNonStrokingColor.new)
    registerOperatorProcessor('T*', org.apache.pdfbox.util.operator.NextLine.new)
    registerOperatorProcessor('Tc', org.apache.pdfbox.util.operator.SetCharSpacing.new)
    registerOperatorProcessor('Td', org.apache.pdfbox.util.operator.MoveText.new)
    registerOperatorProcessor('TD', org.apache.pdfbox.util.operator.MoveTextSetLeading.new)
    registerOperatorProcessor('Tf', org.apache.pdfbox.util.operator.SetTextFont.new)
    registerOperatorProcessor('Tj', org.apache.pdfbox.util.operator.ShowText.new)
    registerOperatorProcessor('TJ', org.apache.pdfbox.util.operator.ShowTextGlyph.new)
    registerOperatorProcessor('TL', org.apache.pdfbox.util.operator.SetTextLeading.new)
    registerOperatorProcessor('Tm', org.apache.pdfbox.util.operator.SetMatrix.new)
    registerOperatorProcessor('Tr', org.apache.pdfbox.util.operator.SetTextRenderingMode.new)
    registerOperatorProcessor('Ts', org.apache.pdfbox.util.operator.SetTextRise.new)
    registerOperatorProcessor('Tw', org.apache.pdfbox.util.operator.SetWordSpacing.new)
    registerOperatorProcessor('Tz', org.apache.pdfbox.util.operator.SetHorizontalTextScaling.new)
    registerOperatorProcessor("\'", org.apache.pdfbox.util.operator.MoveAndShow.new)
    registerOperatorProcessor('\"', org.apache.pdfbox.util.operator.SetMoveAndShow.new)
  end

  def clear!
    self.lineSubPaths = []
    self.linePath = java.awt.geom.GeneralPath.new
    self.lineList = []
    self.rectList = []
    self.currentLines = []
    self.currentRects = []
    self.linesToAdd = []
    self.rectsToAdd = []
    self.newPath = false
    self.currentX = -1; self.currentY = -1
  end

  def new_path!
    self.linesToAdd += currentLines
    self.rectsToAdd += currentRects
    self.newPath = true
    self.pathContainsCurve = false
    self.pathBeginSet = false
    self.pathClosed = false
    self.currentLines = []
    self.currentRects = []
  end

  def simple_move_to!(x, y)
    ppos = self.TransformedPoint(x, y)
    self.currentX, self.currentY = ppos.getX, ppos.getY
  end

  def simple_line_to!(x, y)
    # TODO include color
    # comp = strokingColor.getRGBColorComponents(nil)
    pto = self.TransformedPoint(x, y)

    newLine = LineSegment.new(currentX, currentY, pto.getX, pto.getY)
    newLine.rotate(self.page)
    self.linesToAdd << newLine
    self.currentX = pto.getX; self.currentY = pto.getY
#    puts "line from: (#{newLine.x1}, #{newLine.y1}) -> (#{newLine.x2}, #{newLine.y2})"
  end

  def simple_add_rect!(x, y, w, h)
    # TODO include color
    # comp = getStrokingColor.getRGBColorComponents(nil)
    newRect = RectSegment.new(x, x+w, y, y+h)
    newRect.rotate(self.page)
    self.rectsToAdd << newRect
    self.currentX = x
    self.currentY = y
    #puts "rectangle (#{newRect.x1}, #{newRect.y1}) -> (#{newRect.x2}, #{newRect.y2})"
#    puts newRect.to_xml
  end

  ##
  # get current page size
  def pageSize
    self.page.findMediaBox.createDimension
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
    self.getGraphicsState.getCurrentTransformationMatrix.createAffineTransform.transform(position, 0, position, 0, 1)
    position[1] = fixY(position[1])
    java.awt.geom.Point2D::Double.new(position[0], position[1])
  end



end
