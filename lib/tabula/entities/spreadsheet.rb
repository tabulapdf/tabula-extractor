module Tabula
  # a counterpart of Table, to be sure.
  # not sure yet what their relationship ought to be.
  class Spreadsheet < ZoneEntity
    include Tabula::HasCells
    attr_accessor :cells, :vertical_ruling_lines, :horizontal_ruling_lines, :cells_resolved

    def initialize(top, left, width, height, page, cells, vertical_ruling_lines, horizontal_ruling_lines) #, lines)
      super(top, left, width, height)
      @cells = cells
      @page = page
      @vertical_ruling_lines = vertical_ruling_lines
      @horizontal_ruling_lines = horizontal_ruling_lines
    end

    def ruling_lines
      @vertical_ruling_lines + @horizontal_ruling_lines
    end

    def ruling_lines=(lines)
      @vertical_ruling_lines = lines.select{|vl| vl.vertical? && spr.intersectsLine(vl) }
      @horizontal_ruling_lines = lines.select{|hl| hl.horizontal? && spr.intersectsLine(hl) }
    end

    def fill_in_cells!
      unless @cells_resolved
        @cells_resolved = true
        cells.each do |cell|
          cell.text_elements = @page.get_cell_text(cell)
        end
      end
    end

    # call `rows` with `evaluate_cells` as `false` to defer filling in the text in
    # each cell, which can be computationally intensive.
    def rows(evaluate_cells=true)
      if evaluate_cells
        fill_in_cells!
      end
      tops = cells.map(&:top).uniq.sort
      array_of_rows = tops.map do |top|
        cells.select{|c| c.top == top }.sort_by(&:left)
      end
      #here, insert another kind of placeholder for empty corners
      # like in 01001523B_China.pdf
      #TODO: support placeholders for "empty" cells in rows other than row 1, and in #cols
      # puts array_of_rows[0].inspect
      if array_of_rows.size > 2
        if array_of_rows[0].map(&:left).uniq.size < array_of_rows[1].map(&:left).uniq.size
          missing_spots = array_of_rows[1].map(&:left) - array_of_rows[0].map(&:left)
          # puts missing_spots.inspect
          missing_spots.each do |missing_spot|
            missing_spot_placeholder = Cell.new(array_of_rows[0][0].top, missing_spot, 0, 0)
            missing_spot_placeholder.placeholder = true
            array_of_rows[0] << missing_spot_placeholder
          end
        end
        array_of_rows[0].sort_by!(&:left)
      end
      array_of_rows
    end

    # call `cols` with `evaluate_cells` as `false` to defer filling in the text in
    # each cell, which can be computationally intensive.
    def cols(evaluate_cells=true)
      if evaluate_cells
        fill_in_cells!
      end
      lefts = cells.map(&:left).uniq.sort
      lefts.map do |left|
        cells.select{|c| c.left == left }.sort_by(&:top)
      end
    end

    def to_a
      fill_in_cells!
      rows.map{ |row_cells| row_cells.map(&:text) }
    end

    def to_csv
      out = StringIO.new
      Tabula::Writers.CSV(rows, out)
      out.string
    end

    def to_tsv
      out = StringIO.new
      Tabula::Writers.TSV(rows, out)
      out.string
    end
  end
end
