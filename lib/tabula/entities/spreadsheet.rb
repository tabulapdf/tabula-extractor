module Tabula
  # a counterpart of Table, to be sure.
  # not sure yet what their relationship ought to be.
  class Spreadsheet < ZoneEntity
    attr_accessor :cells, :vertical_ruling_lines, :horizontal_ruling_lines

    def initialize(top, left, width, height, cells) #, lines)
      super(top, left, width, height)
      @cells = cells
      # @vertical_ruling_lines = lines.select(&:vertical?).sort_by(&:left)
      # @horizontal_ruling_lines = lines.select(&:horizontal?).sort_by(&:top)

      # @cells = find_cells(@vertical_ruling_lines, @horizontal_ruling_lines)
      # add_merged_cells!(@cells, @vertical_ruling_lines,  @horizontal_ruling_lines)
    end

    def rows
      tops = cells.map(&:top).uniq.sort
      array_of_rows = tops.map do |top|
        cells.select{|c| c.top == top }.sort_by(&:left)
      end
      #here, insert another kind of placeholder for empty corners
      # like in 01001523B_China.pdf
      #TODO: support placeholders for "empty" cells in rows other than row 1
      zerozero =  array_of_rows[0]
      # puts array_of_rows[0].inspect
      if array_of_rows.size > 2
        if array_of_rows[0].map(&:left).uniq.size < array_of_rows[1].map(&:left).uniq.size
          missing_spots = array_of_rows[1].map(&:left) - array_of_rows[0].map(&:left)
          # puts missing_spots.inspect
          missing_spots.each do |missing_spot|
            array_of_rows[0] << Cell.new(array_of_rows[0][0].top, missing_spot, 0, 0)
          end
        end
        array_of_rows[0].sort_by!(&:left)
      end
      array_of_rows
    end

    def cols
      lefts = cells.map(&:left).uniq.sort
      lefts.map do |left|
        cells.select{|c| c.left == left }.sort_by(&:top)
      end
    end

    def to_a
      rows.map{|row_cells| row_cells.map(&:text)}
    end

    def to_csv
      rows.map do |row_cells|
        #row_cells.each{|c| c.options = {:use_line_returns => true}}
        CSV.generate_line(row_cells.map(&:text), row_sep: "\r\n")
      end.join('')
    end
    def to_tsv
      rows.map do |row_cells|
        CSV.generate_line(row_cells.map(&:text), col_sep: "\t", row_sep: "\r\n")
      end.join('')
    end
  end
end
