module Tabula
  module Extraction

    class SpreadsheetExtractor < Java::TabulaTechnologyExtractors::SpreadsheetExtractionAlgorithm

    end
  end
end


#new plan:
# find all the cells on the page (lines -> minimal rects)
# find all the spreadsheets from the cells (minimal rects -> maximal rects)
