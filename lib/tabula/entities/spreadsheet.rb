module Tabula
  # a counterpart of Table, to be sure.
  # not sure yet what their relationship ought to be.
  class Spreadsheet < ZoneEntity
    attr_accessor :cells, :vertical_ruling_lines, :horizontal_ruling_lines

    def initialize(top, left, width, height, lines)
      super(top, left, width, height)

      @vertical_ruling_lines = lines.select(&:vertical?).sort_by(&:left)
      @horizontal_ruling_lines = lines.select(&:horizontal?).sort_by(&:top)
      @cells = []

      vertical_uniq_locs = @vertical_ruling_lines.map(&:left).uniq    #already sorted
      horizontal_uniq_locs = @horizontal_ruling_lines.map(&:top).uniq #already sorted

      #TODO: replace this O(n^20) algo with the Bentley-Ottman Algorithm
      @vertical_ruling_lines.each_with_index do |left_ruling, i|
        next if left_ruling.left == vertical_uniq_locs.last #skip the last ruling
        prev_top_ruling = nil
        @horizontal_ruling_lines.each_with_index do |top_ruling, j|

          next if top_ruling.top == horizontal_uniq_locs.last
          next unless top_ruling.nearlyIntersects?(left_ruling)

          #find the vertical line with (a) a left strictly greater than left_ruling's
          #                            (b) a top non-strictly smaller than top_ruling's
          #                            (c) the lowest left of all other vertical rulings that fit (a) and (b).
          #                            (d) if married and filing jointly, the subtract $6,100 (standard deduction) and amount from line 32 (adjusted gross income)
          candidate_right_rulings = @vertical_ruling_lines[i+1..-1].select{|l| l.left > left_ruling.left } # (a)
          candidate_right_rulings.select!{|l| l.nearlyIntersects?(top_ruling) && l.bottom > top_ruling.top} #TODO make a better intersection function to check for this.
          if candidate_right_rulings.empty?
            # TODO: why does THIS ever happen?
            # Oh, presumably because there's a broken line at the end?
            # (But that doesn't make sense either.)
            next
          end
          right_ruling = candidate_right_rulings.sort_by{|l| l.left }[0] # (c)

          #random debug crap
          # if left_ruling.left == vertical_uniq_locs[0] && top_ruling.top == horizontal_uniq_locs[0]
          #   candidate_right_rulings = @vertical_ruling_lines[i+1..-1].select{|l| l.left > left_ruling.left }.select{|l| l.left == 142.0 }
          #   puts candidate_right_rulings.map{|l| [l.left, l.nearlyIntersects?(top_ruling), top_ruling, l]}.inspect #TODO make a better intersection function to check for this.
          # end

          #find the horizontal line with (a) intersections with left_ruling and right_ruling
          #                              (b) the lowest top that is strictly greater than top_ruling's
          candidate_bottom_rulings = @horizontal_ruling_lines[j+1..-1].select{|l| l.top > top_ruling.top }
          candidate_bottom_rulings.select!{|l| l.nearlyIntersects?(right_ruling) && l.nearlyIntersects?(left_ruling)}
          if candidate_bottom_rulings.empty?
            next
          end
          bottom_ruling = candidate_bottom_rulings.sort_by{|l| l.top }[0]

          cell_left = left_ruling.left
          cell_top = top_ruling.top
          cell_width = right_ruling.right - cell_left
          cell_height = bottom_ruling.bottom - cell_top

          c = Cell.new(cell_top, cell_left, cell_width, cell_height)
          @cells << c

          ##########################
          # Chapter 2, Merged Cells
          ##########################
          #if c is a "merged cell", that is
          #              if there are N>0 vertical lines strictly between this cell's left and right
          #insert N placeholder cells after it with zero size (but same top)
          vertical_rulings_merged_over = vertical_uniq_locs.select{|l| l > c.left && l < c.right }
          horizontal_rulings_merged_over = horizontal_uniq_locs.select{|t| t > c.top && t < c.bottom }

          unless vertical_rulings_merged_over.empty?
            c.merged = true
            vertical_rulings_merged_over.each do |merged_over_line_loc|
              placeholder = Cell.new(c.top, merged_over_line_loc, 0, c.height)
              placeholder.placeholder = true
              @cells << placeholder
            end
          end
          unless horizontal_rulings_merged_over.empty?
            c.merged = true
            horizontal_rulings_merged_over.each do |merged_over_line_loc|
              placeholder = Cell.new(merged_over_line_loc, c.left, c.width, 0)
              placeholder.placeholder = true
              @cells << placeholder
            end
          end

          #if there's a merged cell that's been merged over both rows and columns, then it has "double placeholder" cells
          # e.g. -------------------
          #      | C |  C |  C | C |         (this is some pretty sweet ASCII art, eh?)
          #      |-----------------|
          #      | C |  C |  C | C |
          #      |-----------------|
          #      | C | MC    P | C |   where MC is the "merged cell" that holds all the text within its bounds
          #      |----    +    ----|         P is a "placeholder" cell with either zero width or zero height
          #      | C | P    DP | C |         DP is a "double placeholder" cell with zero width and zero height
          #      |----    +    ----|         C is an ordinary cell.
          #      | C | P    DP | C |
          #      |-----------------|

          unless (double_placeholders = vertical_rulings_merged_over.product(horizontal_rulings_merged_over)).empty?
            double_placeholders.each do |vert_merged_over, horiz_merged_over|
              placeholder = Cell.new(horiz_merged_over, vert_merged_over, 0, 0)
              placeholder.placeholder = true
              @cells << placeholder
            end
          end


        end
      end
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
      rows.map{|row| row.map(&:text)}
    end

    def to_csv
      rows.map do |row|
        CSV.generate_line(row.map(&:text), row_sep: "\r\n")
      end.join('')
    end
    def to_tsv
      rows.map do |row|
        CSV.generate_line(row.map(&:text), col_sep: "\t", row_sep: "\r\n")
      end.join('')
    end
  end
end
