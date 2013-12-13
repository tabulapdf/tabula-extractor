require_relative './entities.rb'

require 'java'
java_import org.apache.pdfbox.pdfparser.PDFParser
java_import org.apache.pdfbox.util.TextPosition
java_import org.apache.pdfbox.pdmodel.PDDocument
java_import org.apache.pdfbox.util.PDFTextStripper
java_import org.apache.pdfbox.pdmodel.encryption.StandardDecryptionMaterial

module Tabula

  module Extraction

    def Extraction.openPDF(pdf_filename, password='')
      raise Errno::ENOENT unless File.exists?(pdf_filename)
      document = PDDocument.load(pdf_filename)
      if document.isEncrypted
        sdm = StandardDecryptionMaterial.new(password)
        document.openProtection(sdm)
      end
      document
    end

    class TextExtractor < org.apache.pdfbox.pdfviewer.PageDrawer

      attr_accessor :characters, :debug_text, :debug_clipping_paths, :clipping_paths, :lines
      field_accessor :pageSize, :page, :graphics

      PRINTABLE_RE = /[[:print:]]/

      def initialize
        super
        self.characters = []
        @graphics = java.awt.Graphics2D
        self.clipping_paths = []
        self.lines = []
      end

      def clear!
        self.characters = []
      end

      def ensurePageSize!
        if self.pageSize.nil? && !self.page.nil?
          mediaBox = self.page.findMediaBox
          self.pageSize = (mediaBox == nil ? nil : mediaBox.createDimension)
        end
      end

      def drawPage(page)
        self.page = page
        if !self.page.getContents.nil?
          ensurePageSize!
          self.processStream(self.page,
                             self.page.findResources,
                             self.page.getContents.getStream)
        end
      end

      def setStroke(stroke)
        @basicStroke = stroke
      end

      def getStroke
        @basicStroke
      end

      def strokePath
        # TODO FINISH IMPLEMENTING
        path = self.getLinePath
        puts "stroke"
        puts self.pathToList(path).inspect
        self.getLinePath.reset
      end

      def fillPath(windingRule)
        # TODO FINISH IMPLEMENTING
        path = self.getLinePath
        puts "fill"
        puts self.pathToList(path).inspect
        puts
        self.getLinePath.reset
      end

      def drawImage(image, at)
      end

      def transformClippingPath(cp)
        mb = self.page.getMediaBox

        if self.page.getRotation.nil? || !([90, -270, -90, 270].include?(self.page.getRotation))
          trans = AffineTransform.getScaleInstance(1, -1)
          trans.translate(0, -mb.getHeight)
          return cp.createTransformedShape(trans)
        end

        trans = AffineTransform.getScaleInstance(-1, 1)

        trans.rotate(self.page.getRotation * (Math::PI/180.0),
                     mb.getLowerLeftX, mb.getLowerLeftY)

        return cp.createTransformedShape(trans)

      end

      def processTextPosition(text)
        c = text.getCharacter
        h = c == ' ' ? text.getWidthDirAdj.round(2) : text.getHeightDir.round(2)

        te = Tabula::TextElement.new(text.getYDirAdj.round(2) - h,
                                     text.getXDirAdj.round(2),
                                     text.getWidthDirAdj.round(2),
                                     # ugly hack follows: we need spaces to have a height, so we can
                                     # test for vertical overlap. height == width seems a safe bet.
                                     h,
                                     text.getFont,
                                     text.getFontSize.round(2),
                                     c,
                                     # workaround a possible bug in PDFBox: https://issues.apache.org/jira/browse/PDFBOX-1755
                                     text.getWidthOfSpace == 0 ? self.currentSpaceWidth : text.getWidthOfSpace)
        ccp = self.getGraphicsState.getCurrentClippingPath

        if self.debug_clipping_paths && !self.clipping_paths.include?(self.transformClippingPath(ccp).getBounds2D)
          self.clipping_paths << self.transformClippingPath(ccp).getBounds2D
        end

        if c =~ PRINTABLE_RE && self.transformClippingPath(ccp).getBounds2D.intersects(te)
          self.characters << te
        end
      end

      protected

      # workaround a possible bug in PDFBox: https://issues.apache.org/jira/browse/PDFBOX-1755
      def currentSpaceWidth
        gs = self.getGraphicsState
        font = gs.getTextState.getFont

        fontSizeText = gs.getTextState.getFontSize
        horizontalScalingText = gs.getTextState.getHorizontalScalingPercent / 100.0

        if font.java_kind_of?(org.apache.pdfbox.pdmodel.font.PDType3Font)
          puts "TYPE3"
        end

        # idea from pdf.js
        # https://github.com/mozilla/pdf.js/blob/master/src/core/fonts.js#L4418
        spaceWidthText = spaceWidthText = [' ', '-', '1', 'i'] \
          .map { |c| font.getFontWidth(c.ord) } \
          .find { |w| w > 0 } || 1000

        ctm00 = gs.getCurrentTransformationMatrix.getValue(0, 0)

        return (spaceWidthText/1000.0) * fontSizeText * horizontalScalingText * (ctm00 == 0 ? 1 : ctm00)
      end

      def pathToList(path)
        iterator = path.getPathIterator(java.awt.geom.AffineTransform.new)
        coords = Java::double[6].new
        rv = []
        while !iterator.isDone do
          segType = iterator.currentSegment(coords)
          rv << [segType, coords]
          iterator.next
        end
        rv
      end

      def debugPath(path)
        rv = ''
        pathToList(path).each do |type, coords|
          case segType
          when java.awt.geom.PathIterator::SEG_MOVETO
            rv += "MOVE: #{coords[0]} #{coords[1]}\n"
          when java.awt.geom.PathIterator::SEG_LINETO
            rv += "LINE: #{coords[0]} #{coords[1]}\n"
          when java.awt.geom.PathIterator::SEG_CLOSE
            rv += "CLOSE\n\n"
          end
        end
        rv
      end
    end


    class PagesInfoExtractor
      def initialize(pdf_filename, password='')
        @pdf_filename = pdf_filename
        @pdf_file = Extraction.openPDF(pdf_filename, password)
        @all_pages = @pdf_file.getDocumentCatalog.getAllPages
      end

      def pages
        Enumerator.new do |y|
          begin
            @all_pages.each_with_index do |page, i|
              contents = page.getContents

              y.yield Tabula::Page.new(@pdf_filename,
                                       page.findCropBox.width,
                                       page.findCropBox.height,
                                       page.getRotation.to_i,
                                       i+1) #remember, these are one-indexed
            end
          ensure
            @pdf_file.close
          end
        end
      end
    end


    class CharacterExtractor
      #N.B. pages can be :all, a list of pages or a range.
      #     but if it's a list or a range, it's one-indexed
      def initialize(pdf_filename, pages=[1], password='', options={})
        raise Errno::ENOENT unless File.exists?(pdf_filename)
        @pdf_filename = pdf_filename
        @pdf_file = Extraction.openPDF(pdf_filename, password)
        @all_pages = @pdf_file.getDocumentCatalog.getAllPages
        @pages = pages == :all ?  (1..@all_pages.size) : pages
        @extractor = TextExtractor.new
      end

      def extract
        Enumerator.new do |y|
          begin
            @pages.each do |i|
              page = @all_pages.get(i-1)
              contents = page.getContents
              next if contents.nil?
              @extractor.clear!
              @extractor.drawPage page
              y.yield Tabula::Page.new(@pdf_filename,
                                       page.findCropBox.width,
                                       page.findCropBox.height,
                                       page.getRotation.to_i,
                                       i, #one-indexed, just like `i` is.
                                       @extractor.characters)
            end
          ensure
            @pdf_file.close
          end # begin
        end
      end
    end
  end
end
