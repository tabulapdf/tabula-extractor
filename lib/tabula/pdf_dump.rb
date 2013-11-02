require 'observer'

require_relative './entities.rb'

require 'java'
require File.join(File.dirname(__FILE__), '../../target/', Tabula::PDFBOX)
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

      OPERATORS = {
        "b" => org.apache.pdfbox.util.operator.pagedrawer.CloseFillNonZeroAndStrokePath.new,
        "B" => org.apache.pdfbox.util.operator.pagedrawer.FillNonZeroAndStrokePath.new,
        "b*" => org.apache.pdfbox.util.operator.pagedrawer.CloseFillEvenOddAndStrokePath.new,
        "B*" => org.apache.pdfbox.util.operator.pagedrawer.FillEvenOddAndStrokePath.new,
        "BI" => org.apache.pdfbox.util.operator.pagedrawer.BeginInlineImage.new,
        "BT" => org.apache.pdfbox.util.operator.BeginText.new,
        "c" => org.apache.pdfbox.util.operator.pagedrawer.CurveTo.new,
        "cm" => org.apache.pdfbox.util.operator.Concatenate.new,
        "CS" => org.apache.pdfbox.util.operator.SetStrokingColorSpace.new,
        "cs" => org.apache.pdfbox.util.operator.SetNonStrokingColorSpace.new,
        "d" => org.apache.pdfbox.util.operator.pagedrawer.SetLineDashPattern.new,
        "Do" => org.apache.pdfbox.util.operator.pagedrawer.Invoke.new,
        "ET" => org.apache.pdfbox.util.operator.EndText.new,
        "f" => org.apache.pdfbox.util.operator.pagedrawer.FillNonZeroRule.new,
        "F" => org.apache.pdfbox.util.operator.pagedrawer.FillNonZeroRule.new,
        "f*" => org.apache.pdfbox.util.operator.pagedrawer.FillEvenOddRule.new,
        "G" => org.apache.pdfbox.util.operator.SetStrokingGrayColor.new,
        "g" => org.apache.pdfbox.util.operator.SetNonStrokingGrayColor.new,
        "gs" => org.apache.pdfbox.util.operator.SetGraphicsStateParameters.new,
        "h" => org.apache.pdfbox.util.operator.pagedrawer.ClosePath.new,
        "j" => org.apache.pdfbox.util.operator.pagedrawer.SetLineJoinStyle.new,
        "J" => org.apache.pdfbox.util.operator.pagedrawer.SetLineCapStyle.new,
        "K" => org.apache.pdfbox.util.operator.SetStrokingCMYKColor.new,
        "k" => org.apache.pdfbox.util.operator.SetNonStrokingCMYKColor.new,
        "l" => org.apache.pdfbox.util.operator.pagedrawer.LineTo.new,
        "m" => org.apache.pdfbox.util.operator.pagedrawer.MoveTo.new,
        "M" => org.apache.pdfbox.util.operator.pagedrawer.SetLineMiterLimit.new,
        "n" => org.apache.pdfbox.util.operator.pagedrawer.EndPath.new,
        "q" => org.apache.pdfbox.util.operator.GSave.new,
        "Q" => org.apache.pdfbox.util.operator.GRestore.new,
        "re" => org.apache.pdfbox.util.operator.pagedrawer.AppendRectangleToPath.new,
        "RG" => org.apache.pdfbox.util.operator.SetStrokingRGBColor.new,
        "rg" => org.apache.pdfbox.util.operator.SetNonStrokingRGBColor.new,
        "s" => org.apache.pdfbox.util.operator.CloseAndStrokePath.new,
        "S" => org.apache.pdfbox.util.operator.pagedrawer.StrokePath.new,
        "SC" => org.apache.pdfbox.util.operator.SetStrokingColor.new,
        "sc" => org.apache.pdfbox.util.operator.SetNonStrokingColor.new,
        "SCN" => org.apache.pdfbox.util.operator.SetStrokingColor.new,
        "scn" => org.apache.pdfbox.util.operator.SetNonStrokingColor.new,
        "sh" => org.apache.pdfbox.util.operator.pagedrawer.SHFill.new,
        "T*" => org.apache.pdfbox.util.operator.NextLine.new,
        "Tc" => org.apache.pdfbox.util.operator.SetCharSpacing.new,
        "Td" => org.apache.pdfbox.util.operator.MoveText.new,
        "TD" => org.apache.pdfbox.util.operator.MoveTextSetLeading.new,
        "Tf" => org.apache.pdfbox.util.operator.SetTextFont.new,
        "Tj" => org.apache.pdfbox.util.operator.ShowText.new,
        "TJ" => org.apache.pdfbox.util.operator.ShowTextGlyph.new,
        "TL" => org.apache.pdfbox.util.operator.SetTextLeading.new,
        "Tm" => org.apache.pdfbox.util.operator.SetMatrix.new,
        "Tr" => org.apache.pdfbox.util.operator.SetTextRenderingMode.new,
        "Ts" => org.apache.pdfbox.util.operator.SetTextRise.new,
        "Tw" => org.apache.pdfbox.util.operator.SetWordSpacing.new,
        "Tz" => org.apache.pdfbox.util.operator.SetHorizontalTextScaling.new,
        "v" => org.apache.pdfbox.util.operator.pagedrawer.CurveToReplicateInitialPoint.new,
        "w" => org.apache.pdfbox.util.operator.pagedrawer.SetLineWidth.new,
        "W" => org.apache.pdfbox.util.operator.pagedrawer.ClipNonZeroRule.new,
        "W*" => org.apache.pdfbox.util.operator.pagedrawer.ClipEvenOddRule.new,
        "y" => org.apache.pdfbox.util.operator.pagedrawer.CurveToReplicateFinalPoint.new,
        "'" => org.apache.pdfbox.util.operator.MoveAndShow.new,
        "\"" => org.apache.pdfbox.util.operator.SetMoveAndShow.new
      }
      attr_accessor :characters
      field_accessor :pageSize, :page, :graphics

      PRINTABLE_RE = /[[:print:]]/

      def initialize
        super
        OPERATORS.each { |k,v| self.registerOperatorProcessor(k,v) }
        self.characters = []
        @graphics = java.awt.Graphics2D
      end

      def clear!
        self.characters = []
      end

      def ensurePageSize!
        if self.pageSize.nil? && !self.page.nil?
          mediaBox = self.page.findMediaBox
          self.pageSize = mediaBox == nil ? nil : mediaBox.createDimension
          #(@pageSize = @pageSize).nil? ? DEFAULT_DIMENSION : pageSize;
        end
      end

      def drawPage(*args)
        if args.size == 1
          page = args.first
          ensurePageSize!
          self.page = page
          if !page.getContents.nil?
            resources = page.findResources
            ensurePageSize!
            self.processStream(page, page.findResources, page.getContents.getStream)
          end
        elsif args.size == 3
          self.graphics = args[0]
          self.page = args[1]
          self.pageSize = args[2]
        end
      end

      def extractText!(page)
        drawPage page
      end

      def setStroke(stroke)
        @basicStroke = stroke
      end

      def getStroke
        @basicStroke
      end

      def strokePath
      end

      def fillPath(windingRule)
      end

      def drawImage(image, at)
      end

      def processTextPosition(text)
        c = text.getCharacter
        te = Tabula::TextElement.new(text.getYDirAdj.round(2),
                                                     text.getXDirAdj.round(2),
                                                     text.getWidthDirAdj.round(2),
                                                     # ugly hack follows: we need spaces to have a height, so we can
                                                     # test for vertical overlap. height == width seems a safe bet.
                                                     c == ' ' ? text.getWidthDirAdj.round(2) : text.getHeightDir.round(2),
                                                     text.getFont,
                                                     text.getFontSize.round(2),
                                                     c,
                                                     # workaround a possible bug in PDFBox: https://issues.apache.org/jira/browse/PDFBOX-1755
                                                     text.getWidthOfSpace == 0 ? self.currentSpaceWidth : text.getWidthOfSpace)

        if c =~ PRINTABLE_RE && self.getGraphicsState.getCurrentClippingPath.intersects(te)
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

        spaceWidthText = font.getFontWidth([0x20].to_java(Java::byte), 0, 1)
        # puts "fontSizeText: #{fontSizeText}"
        # puts "spaceWidthText: #{spaceWidthText}"
        # puts "horizontalScalingText: #{horizontalScalingText}"
        # puts "textMatrix 0,0: #{self.textMatrix.getValue(0, 0)}"
        # puts "ctm 0,0: #{gs.getCurrentTransformationMatrix.getValue(0, 0)}"
        return (spaceWidthText/1000.0) * fontSizeText * horizontalScalingText * gs.getCurrentTransformationMatrix.getValue(0, 0)
      end
    end


    class PagesInfoExtractor
      def initialize(pdf_filename, password='')
        @pdf_file = Extraction.openPDF(pdf_filename, password)
        @all_pages = @pdf_file.getDocumentCatalog.getAllPages
      end

      def pages
        Enumerator.new do |y|
          begin
            @all_pages.each_with_index do |page, i|
              contents = page.getContents

              y.yield Tabula::Page.new(page.findCropBox.width,
                                       page.findCropBox.height,
                                       page.getRotation.to_i,
                                       i+1)
            end
          ensure
            @pdf_file.close
          end
        end
      end
    end


    class CharacterExtractor
      include Observable

      #N.B. pages can be :all, a list of pages or a range.
      def initialize(pdf_filename, pages=[1], password='')
        raise Errno::ENOENT unless File.exists?(pdf_filename)
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
              #@extractor.processStream(page, page.findResources, contents.getStream)
              @extractor.extractText! page
              y.yield Tabula::Page.new(page.findCropBox.width,
                                       page.findCropBox.height,
                                       page.getRotation.to_i,
                                       i+1,
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
