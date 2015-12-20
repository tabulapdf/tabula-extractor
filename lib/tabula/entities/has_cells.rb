require 'set'
java_import java.awt.Polygon
java_import java.awt.geom.Area
java_import Java::TechnologyTabulaExtractors::SpreadsheetExtractionAlgorithm

module Tabula
  # subclasses must define cells, vertical_ruling_lines, horizontal_ruling_lines accessors; ruling_lines reader
  module HasCells

    ARBITRARY_MAGIC_HEURISTIC_NUMBER = 0.65

    def is_tabular?
      SpreadsheetExtractionAlgorithm.new.isTabular(self)
    end

    def find_cells!(horizontal_ruling_lines, vertical_ruling_lines, options={})
      self.cells = SpreadsheetExtractionAlgorithm.findCells(horizontal_ruling_lines, vertical_ruling_lines)
    end

    #TODO:
    #returns array of Spreadsheet objects constructed (or spreadsheet_areas => cells)
    #maybe placeholders should be added after cells is split into spreadsheets

    def find_spreadsheets_from_cells
      SpreadsheetExtractionAlgorithm.new.findSpreadsheetsFromCells(self.cells)
    end

  end
end
