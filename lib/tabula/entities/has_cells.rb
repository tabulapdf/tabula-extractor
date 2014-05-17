require 'set'
java_import java.awt.Polygon
java_import java.awt.geom.Area
java_import org.nerdpower.tabula.extractors.SpreadsheetExtractionAlgorithm

module Tabula
  # subclasses must define cells, vertical_ruling_lines, horizontal_ruling_lines accessors; ruling_lines reader
  module HasCells

    ARBITRARY_MAGIC_HEURISTIC_NUMBER = 0.65

    def is_tabular?
      ratio = heuristic_ratio
      return ratio > ARBITRARY_MAGIC_HEURISTIC_NUMBER && ratio < (1 / ARBITRARY_MAGIC_HEURISTIC_NUMBER)
    end

    def heuristic_ratio
      #spreadsheet extraction
      spreadsheet = spreadsheets.first
      return Float::NAN if spreadsheet.nil?
      rows_defined_by_lines = spreadsheet.rows.size #rows filled in automatically
      columns_defined_by_lines = spreadsheet.cols.size

      table = self.get_table
      columns_defined_without_lines = table.cols.size
      rows_defined_without_lines = table.rows.size
      ((columns_defined_by_lines.to_f / columns_defined_without_lines) + (rows_defined_by_lines.to_f / rows_defined_without_lines)) / 2
    end

    def find_cells!(horizontal_ruling_lines, vertical_ruling_lines, options={})
      self.cells = SpreadsheetExtractionAlgorithm.new.findCells(horizontal_ruling_lines, vertical_ruling_lines)
      self.cells
    end

    #TODO:
    #returns array of Spreadsheet objects constructed (or spreadsheet_areas => cells)
    #maybe placeholders should be added after cells is split into spreadsheets

    def find_spreadsheets_from_cells
      SpreadsheetExtractionAlgorithm.new.findSpreadsheetsFromCells(self.cells)
    end

  end
end
