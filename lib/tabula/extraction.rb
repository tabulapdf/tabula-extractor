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

      attr_accessor :characters, :debug_text, :debug_clipping_paths, :clipping_paths, :min_char_width, :min_char_height, :options
      field_accessor :pageSize, :page

      PRINTABLE_RE = /[[:print:]]/
      DEFAULT_OPTIONS = {
        :line_color_filter => nil,
        :extract_ruling_lines => true
      }

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
        self.min_char_width = self.min_char_height = 1000000
      end

      def extract
        Enumerator.new do |y|
          begin
            @pages.each do |i|
              page = @all_pages.get(i-1)
              contents = page.getContents
              next if contents.nil?

              self.clear!
              self.drawPage(page)
              y.yield Tabula::Page.new(@pdf_filename,
                                       page.findCropBox.width,
                                       page.findCropBox.height,
                                       page.getRotation.to_i,
                                       i, #one-indexed, just like `i` is.
                                       self.characters,
                                       self.rulings)
            end
          ensure
            @pdf_file.close
          end # begin
        end
      end

      def clear!
        self.characters.clear
        self.clipping_paths.clear
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

        if path[0][0] != java.awt.geom.PathIterator::SEG_MOVETO \
          || path[1..-1].any? { |p| p.first != java.awt.geom.PathIterator::SEG_LINETO && p.first != java.awt.geom.PathIterator::SEG_MOVETO }
          self.getLinePath.reset
          return
        end

        ccp_bounds = self.currentClippingPath

        strokeColorComps = filter_by_color || self.getGraphicsState.getStrokingColor.getJavaColor.getRGBColorComponents(nil)
        color_filter = self.options[:line_color_filter]

        first = path.shift
        start_pos = java.awt.geom.Point2D::Float.new(first[1][0], first[1][1])

        path.each do |p|
          end_pos = java.awt.geom.Point2D::Float.new(p[1][0], p[1][1])
          line = (start_pos <=> end_pos) == -1 \
            ? java.awt.geom.Line2D::Float.new(start_pos, end_pos) \
            : java.awt.geom.Line2D::Float.new(end_pos, start_pos)

          if p[0] == java.awt.geom.PathIterator::SEG_LINETO \
            && (color_filter.nil? ? true : color_filter.call(strokeColorComps)) \
            && line.intersects(ccp_bounds)
            # convert line to rectangle for clipping it to the current clippath
            # sucks, but awt doesn't have methods for this
            tmp = line.getBounds2D.createIntersection(ccp_bounds).getBounds2D
            @rulings << ::Tabula::Ruling.new(tmp.getY,
                                             tmp.getX,
                                             tmp.getWidth,
                                             tmp.getHeight,
                                             filter_by_color.to_a)
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

        ccp_bounds = self.currentClippingPath

        if self.debug_clipping_paths && !self.clipping_paths.include?(ccp_bounds)
          self.clipping_paths << ::Tabula::ZoneEntity.new(ccp_bounds.getMinY,
                                                          ccp_bounds.getMinX,
                                                          ccp_bounds.getWidth,
                                                          ccp_bounds.getHeight)
        end

        if te.width < self.min_char_width
          self.min_char_width = te.width
        end

        if te.height < self.min_char_height
          self.min_char_height = te.height
        end

        if c =~ PRINTABLE_RE && ccp_bounds.intersects(te)
          self.characters << te
        end

        def page_count
          @all_pages.size
        end
      end

      def rulings
        # TODO optimize
        return [] if @rulings.empty?
        r = @rulings.reject { |l| (l.left == l.right && l.top == l.bottom) || [l.top, l.left, l.bottom, l.right].any? { |p| p < 0 } }
        self.collapse_vertical_rulings(r.select(&:vertical?)) + self.collapse_horizontal_rulings(r.select(&:horizontal?))
      end

      def collapse_vertical_rulings(lines) #lines should all be of one orientation (i.e. horizontal, vertical)
        lines.sort! { |a, b| a.left != b.left ? a.left <=> b.left : a.top <=> b.top }
        lines.inject([lines.shift]) do |memo, next_line|
          last = memo.last
          if next_line.left == last.left && last.nearlyIntersects?(next_line)
            memo.last.top = next_line.top < last.top ? next_line.top : last.top
            memo.last.bottom = next_line.bottom < last.bottom ? last.bottom : next_line.bottom
            memo
          elsif (next_line.left - last.left) < self.min_char_width
            # merge parallel vertical lines that are close together (closer than the width of the narrowest char)
            memo.last.left += (next_line.left - last.left) / 2
            memo.last.right = last.left
            memo.last.top = next_line.top < last.top ? next_line.top : last.top
            memo.last.bottom = next_line.bottom < last.bottom ? last.bottom : next_line.bottom
            memo
          else
            memo << next_line
          end
        end
      end

      def collapse_horizontal_rulings(lines) #lines should all be of one orientation (i.e. horizontal, vertical)
        lines.sort! {|a, b| a.top != b.top ? a.top <=> b.top : a.left <=> b.left }
        lines.inject([lines.shift]) do |memo, next_line|
          last = memo.last
          if next_line.top == last.top && last.nearlyIntersects?(next_line)
            memo.last.left = next_line.left < last.left ? next_line.left : last.left
            memo.last.right = next_line.right < last.right ? last.right : next_line.right
            memo
          elsif (next_line.top - last.top) < self.min_char_height
            # merge parallel horizontal lines that are close together (closer than the width of the shortest char)
            memo.last.top += (next_line.top - last.top) / 2
            memo.last.bottom = last.top
            memo.last.left = next_line.left < last.left ? next_line.left : last.left
            memo.last.right = next_line.right < last.right ? last.right : next_line.right
            memo
          else
            memo << next_line
          end
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
