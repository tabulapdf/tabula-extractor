# -*- coding: utf-8 -*-
java_import org.apache.pdfbox.pdfparser.PDFParser
java_import org.apache.pdfbox.util.TextPosition
java_import org.apache.pdfbox.pdmodel.PDDocument
java_import org.apache.pdfbox.util.PDFTextStripper
java_import org.apache.pdfbox.pdmodel.encryption.StandardDecryptionMaterial
java_import java.awt.geom.AffineTransform

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

    class ObjectExtractor < org.apache.pdfbox.pdfviewer.PageDrawer

      attr_accessor :characters, :debug_text, :debug_clipping_paths, :clipping_paths, :options
      field_accessor :pageSize, :page

      PRINTABLE_RE = /[[:print:]]/
      DEFAULT_OPTIONS = {
        :line_color_filter => nil,
        :extract_ruling_lines => true
      }

      # TODO: the +pages+ constructor argument does not make sense
      # now that we have +extract_page+ and +extract_pages+
      def initialize(pdf_filename, pages=[1], password='', options={})
        raise Errno::ENOENT unless File.exists?(pdf_filename)
        @pdf_filename = pdf_filename
        @pdf_file = Extraction.openPDF(pdf_filename, password)
        @all_pages = @pdf_file.getDocumentCatalog.getAllPages
        @pages = pages == :all ?  (1..@all_pages.size) : pages

        super()

        self.options = DEFAULT_OPTIONS.merge(options)
        self.characters = []
        @debug_clipping_paths = false
        @clipping_path = nil
        @transformed_clipping_path = nil
        self.clipping_paths = []
        @rulings = []
        @min_char_width = @min_char_height = Float::MAX
      end

      def close!
        self.ensure_open!
        @pdf_file.close
        @pdf_file_closed = true
      end

      def ensure_open!
        raise "Document is closed" if @pdf_file_closed
      end

      ##
      # extract objects from a page. Returns an instance of +Tabula::Page+
      # (+page_number+ is 1-based. i.e., first page is number 1)
      def extract_page(page_number)
        self.ensure_open!

        if page_number-1 >= @all_pages.size || (page_number) < 0
          raise IndexError, "Page #{page_number} doesn't exist. Skipping. Valid pages are 1..#{@all_pages.size}"
        end

        page = @all_pages.get(page_number-1)
        contents = page.getContents
        return nil if contents.nil?

        self.clear!
        self.drawPage(page)
        Tabula::Page.new(@pdf_filename,
                         page.findCropBox.width,
                         page.findCropBox.height,
                         page.getRotation.to_i,
                         page_number, #one-indexed, just like +page_number+ is.
                         self.characters,
                         self.rulings,
                         @min_char_width,
                         @min_char_height)
      end

      def extract(pages=nil)
        self.ensure_open!
        pages = if pages == :all
                  (1..@all_pages.size)
                elsif pages.nil?
                  @pages
                else
                  pages
                end

        Enumerator.new do |y|
          pages.each do |i|
            y.yield self.extract_page(i)
          end
        end
      end

      def clear!
        self.characters.clear
        self.clipping_paths.clear
        @min_char_width = @min_char_height = Float::MAX
        @page_transform = nil
        @rulings.clear
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


      def strokePath(filter_by_color=nil)
        unless self.options[:extract_ruling_lines]
          self.getLinePath.reset
          return
        end

        path = self.pathToList(self.getLinePath)

        # skip paths whose first operation is not a MOVETO
        # or contains operations other than LINETO, MOVETO or CLOSE
        if path[0][0] != java.awt.geom.PathIterator::SEG_MOVETO \
           || path[1..-1].any? { |p|
            p.first != java.awt.geom.PathIterator::SEG_LINETO \
            && p.first != java.awt.geom.PathIterator::SEG_MOVETO \
            && p.first != java.awt.geom.PathIterator::SEG_CLOSE
          }
          self.getLinePath.reset
          return
        end

        ccp_bounds = self.currentClippingPath

        strokeColorComps = filter_by_color || self.getGraphicsState.getStrokingColor.getJavaColor.getRGBColorComponents(nil)
        color_filter = self.options[:line_color_filter]

        if !color_filter.nil? && !color_filter.call(strokeColorComps)
          self.getLinePath.reset
          return
        end

        # skip the first path operation save it as the starting position
        first = path.shift
        # last_move
        start_pos = last_move = java.awt.geom.Point2D::Float.new(first[1][0], first[1][1])

        end_pos = nil

        path.each do |p|
          case p[0]
          when java.awt.geom.PathIterator::SEG_LINETO
            end_pos = java.awt.geom.Point2D::Float.new(p[1][0], p[1][1])
            line = (start_pos <=> end_pos) == -1 \
                   ? java.awt.geom.Line2D::Float.new(start_pos, end_pos) \
                   : java.awt.geom.Line2D::Float.new(end_pos, start_pos)

            if line.intersects(ccp_bounds)
              # convert line to rectangle for clipping it to the current clippath
              # sucks, but awt doesn't have methods for this
              tmp = line.getBounds2D.createIntersection(ccp_bounds).getBounds2D
              @rulings << ::Tabula::Ruling.new(tmp.getY,
                                               tmp.getX,
                                               tmp.getWidth,
                                               tmp.getHeight,
                                               filter_by_color.to_a)
            end
          when java.awt.geom.PathIterator::SEG_MOVETO
            last_move = java.awt.geom.Point2D::Float.new(p[1][0], p[1][1])
          when java.awt.geom.PathIterator::SEG_CLOSE
            # according to PathIterator docs:
            # "the preceding subpath should be closed by appending a line segment
            # back to the point corresponding to the most recent SEG_MOVETO."

            line = (end_pos <=> last_move) == -1 \
                   ? java.awt.geom.Line2D::Float.new(end_pos, last_move) \
                   : java.awt.geom.Line2D::Float.new(last_move, end_pos)

            if line.intersects(ccp_bounds)
              # convert line to rectangle for clipping it to the current clippath
              # sucks, but awt doesn't have methods for this
              tmp = line.getBounds2D.createIntersection(ccp_bounds).getBounds2D
              @rulings << ::Tabula::Ruling.new(tmp.getY,
                                               tmp.getX,
                                               tmp.getWidth,
                                               tmp.getHeight,
                                               filter_by_color.to_a)
            end
          end
          start_pos = end_pos
        end
        self.getLinePath.reset
      end

      def fillPath(windingRule)
        self.strokePath(self.getGraphicsState.getNonStrokingColor.getJavaColor.getRGBColorComponents(nil))
      end

      def drawImage(image, at)
      end

      def transformPath(path)
        self.pageTransform.createTransformedShape(path)
      end

      def pageTransform
        unless @page_transform.nil?
          return @page_transform
        end

        cb = page.findCropBox
        if !([90, -270, -90, 270].include?(page.getRotation))
          @page_transform = AffineTransform.getScaleInstance(1, -1)
          @page_transform.translate(0, -cb.getHeight)
        else
          @page_transform = AffineTransform.getScaleInstance(-1, 1)
          @page_transform.rotate(page.getRotation * (Math::PI/180.0),
                                 cb.getLowerLeftX, cb.getLowerLeftY)
        end
        @page_transform
      end

      def currentClippingPath
        cp = self.getGraphicsState.getCurrentClippingPath

        if cp == @clipping_path
          return @transformed_clipping_path_bounds
        end

        @clipping_path = cp
        @transformed_clipping_path = self.transformPath(cp)
        @transformed_clipping_path_bounds = @transformed_clipping_path.getBounds

        return @transformed_clipping_path_bounds
      end

      def processTextPosition(text)
        c = text.getCharacter
        h = text.getHeightDir.round(2)

        if c == ' ' # replace non-breaking space for space
          c = ' '
        end

        te = Tabula::TextElement.new(text.getY.round(2) - h,
                                     text.getX.round(2),
                                     text.getWidthDirAdj,
                                     # ugly hack follows: we need spaces to have a height, so we can
                                     # test for vertical overlap. height == width seems a safe bet.
                                     text.getHeightDir,
                                     text.getFont,
                                     text.getFontSize,
                                     c,
                                     # workaround a possible bug in PDFBox: https://issues.apache.org/jira/browse/PDFBOX-1755
                                     (text.getWidthOfSpace.nan? || text.getWidthOfSpace == 0) ? self.currentSpaceWidth : text.getWidthOfSpace,
                                     text.getDir)

        ccp_bounds = self.currentClippingPath

        if self.debug_clipping_paths && !self.clipping_paths.include?(ccp_bounds)
          self.clipping_paths << java.awt.geom.Rectangle2D::Float.new_from_tlwh(ccp_bounds.getMinY,
                                                                                ccp_bounds.getMinX,
                                                                                ccp_bounds.getWidth,
                                                                                ccp_bounds.getHeight)
        end

        if te.width < @min_char_width
          @min_char_width = te.width
        end

        if te.height < @min_char_height
          @min_char_height = te.height
        end

        if c =~ PRINTABLE_RE && ccp_bounds.intersects(te)
          self.characters << te
        end
      end

      def page_count
        @all_pages.size
      end

      def rulings
        @rulings.reject { |l| (l.left == l.right && l.top == l.bottom) || [l.top, l.left, l.bottom, l.right].any? { |p| p < 0 } }
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
        iterator = path.getPathIterator(self.pageTransform)
        rv = []
        while !iterator.isDone do
          coords = Java::double[6].new
          segType = iterator.currentSegment(coords)
          rv << [segType, coords]
          iterator.next
        end
        rv
      end

      def debugPath(path)
        rv = ''
        pathToList(path).each do |segType, coords|
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
  end
end
