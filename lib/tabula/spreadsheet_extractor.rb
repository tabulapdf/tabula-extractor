module Tabula
  module Extraction
    class SpreadsheetExtractor
      #N.B. pages can be :all, a list of pages or a range.
      #     but if it's a list or a range, it's one-indexed
      def initialize(pdf_filename, pages=[1], password='')
        raise Errno::ENOENT unless File.exists?(pdf_filename)
        @pdf_filename = pdf_filename
        @pdf_file = Extraction.openPDF(pdf_filename, password)
        @all_pages = @pdf_file.getDocumentCatalog.getAllPages
        @pages = pages == :all ?  (1..@all_pages.size) : pages
        @extractor = TextExtractor.new
      end

      # yields each spreadsheet and the page it corresponds to
      # because each page can contain an arbitrary number of spreadsheets, each page can be sent
      # to the block an arbitrary number of times.
      # so the extract.each_with_index trick will absolutely not work.
      def extract(options={})
        Enumerator.new do |y|
          begin
            @pages.each do |i|
              pdfbox_page = @all_pages.get(i-1) #TODO: this can error out ungracefully if you try to extract a page that doesn't exist (e.g. page 5 of a 4 page doc). we should catch and handle.
              contents = pdfbox_page.getContents
              next if contents.nil?
              @extractor.clear!
              @extractor.drawPage pdfbox_page

              page = Tabula::Page.new( @pdf_filename,
                                       pdfbox_page.findCropBox.width,
                                       pdfbox_page.findCropBox.height,
                                       pdfbox_page.getRotation.to_i,
                                       i, #one-indexed, just like `i` is.
                                       @extractor.characters)

              page.spreadsheets.each do |spreadsheet|
                spreadsheet.cells.each do |cell|
                  cell.text_elements = page.get_cell_text(cell)
                end
                y.yield page, spreadsheet

              end
            end
          ensure
            @pdf_file.close
          end # begin
        end
      end
    end
  end
end


#new plan:
# find all the cells on the page (lines -> minimal rects)
# find all the spreadsheets from the cells (minimal rects -> maximal rects)
