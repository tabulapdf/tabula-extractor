module Tabula
  # a counterpart of Table, to be sure.
  # not sure yet what their relationship ought to be.

  # the both should implement `cells`, `rows`, `cols`, `extraction_method`

  class Spreadsheet < ZoneEntity
    include Tabula::Tabular
    attr_accessor :cells, :vertical_ruling_lines, :horizontal_ruling_lines, :cells_resolved
    attr_reader :extraction_method, :page

    def initialize(top, left, width, height, page, cells, vertical_ruling_lines, horizontal_ruling_lines) #, lines)
      super(top, left, width, height)
      @cells = cells
      @page = page
      @vertical_ruling_lines = vertical_ruling_lines
      @horizontal_ruling_lines = horizontal_ruling_lines
      @extraction_method = "spreadsheet"
    end

    def self.empty(page)
      Spreadsheet.new(0, 0, 0, 0, page, [], nil, nil) 
    end

    def ruling_lines
      @vertical_ruling_lines + @horizontal_ruling_lines
    end

    def ruling_lines=(lines)
      @vertical_ruling_lines = lines.select{|vl| vl.vertical? && spr.intersectsLine(vl) }
      @horizontal_ruling_lines = lines.select{|hl| hl.horizontal? && spr.intersectsLine(hl) }
    end

    # call `rows` with `evaluate_cells` as `false` to defer filling in the text in
    # each cell, which can be computationally intensive.
    def rows(evaluate_cells=true)
      if evaluate_cells
        fill_in_cells!
      end

      rows_hash = cells.group_by{|cell| cell.top.round(5) }
      array_of_rows = rows_hash.keys.sort.map do |key|
        rows_hash[key].sort_by(&:left)
      end


      #here, insert another kind of placeholder for empty corners
      # like in 01001523B_China.pdf
      #TODO: support placeholders for "empty" cells in rows other than row 1, and in #cols
      # puts array_of_rows[0].inspect
      if array_of_rows.size > 2
        if array_of_rows[0].map(&:left).uniq.size < array_of_rows[1].map(&:left).uniq.size
          missing_spots = array_of_rows[1].map(&:left) - array_of_rows[0].map(&:left)

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

      cols_hash = cells.group_by{|cell| cell.left.round(5) }
      cols_hash.keys.sort.map do |key|
        cols_hash[key].sort_by(&:top)
      end
    end

    #######################################################
    # Chapter 2 of Spreadsheet extraction, Spanning Cells #
    #######################################################
    #if c is a "spanning cell", that is
    #              if there are N>0 vertical lines strictly between this cell's left and right
    #insert N placeholder cells after it with zero size (but same top)
    def add_spanning_cells!
      #rounding: because Cell.new_from_points, using in #find_cells above, has
      # a float precision error where, for instance, a cell whose x2 coord is
      # supposed to be 160.137451171875 comes out as 160.13745498657227 because
      # of minus. :(
      vertical_uniq_locs = vertical_ruling_lines.map{|l| l.left.round(5)}.uniq    #already sorted
      horizontal_uniq_locs = horizontal_ruling_lines.map{|l| l.top.round(5)}.uniq #already sorted

      cells.each do |c|
        vertical_rulings_spanned_over = vertical_uniq_locs.select{|l| l > c.left.round(5) && l < c.right.round(5) }
        horizontal_rulings_spanned_over = horizontal_uniq_locs.select{|t| t > c.top.round(5) && t < c.bottom.round(5) }

        unless vertical_rulings_spanned_over.empty?
          c.spanning = true
          vertical_rulings_spanned_over.each do |spanned_over_line_loc|
            placeholder = Cell.new(c.top, spanned_over_line_loc, 0, c.height)
            placeholder.placeholder = true
            cells << placeholder
          end
        end
        unless horizontal_rulings_spanned_over.empty?
          c.spanning = true
          horizontal_rulings_spanned_over.each do |spanned_over_line_loc|
            placeholder = Cell.new(spanned_over_line_loc, c.left, c.width, 0)
            placeholder.placeholder = true
            cells << placeholder
          end
        end

        #if there's a spanning cell that's spans over both rows and columns, then it has "double placeholder" cells
        # e.g. -------------------
        #      | C |  C |  C | C |         (this is some pretty sweet ASCII art, eh?)
        #      |-----------------|
        #      | C |  C |  C | C |
        #      |-----------------|
        #      | C | SC    P | C |   where MC is the "spanning cell" that holds all the text within its bounds
        #      |----    +    ----|         P is a "placeholder" cell with either zero width or zero height
        #      | C | P    DP | C |         DP is a "double placeholder" cell with zero width and zero height
        #      |----    +    ----|         C is an ordinary cell.
        #      | C | P    DP | C |
        #      |-----------------|

        unless (double_placeholders = vertical_rulings_spanned_over.product(horizontal_rulings_spanned_over)).empty?
          double_placeholders.each do |vert_spanned_over, horiz_spanned_over|
            placeholder = Cell.new(horiz_spanned_over, vert_spanned_over, 0, 0)
            placeholder.placeholder = true
            cells << placeholder
          end
        end
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

    def to_json(*a)
      {
        'json_class'   => self.class.name,
        'extraction_method' => @extraction_method,
        'data' => rows,
      }.to_json(*a)
    end

    def +(other)
      raise ArgumentError, "Data can only be added if it's from the same PDF page" unless other.page == @page
      Spreadsheet.new(nil, nil, nil, nil, @page, @cells + other.cells, nil, nil )
    end

    protected
    def fill_in_cells!
      unless @cells_resolved
        @cells_resolved = true
        cells.each do |cell|
          cell.text_elements = @page.get_cell_text(cell)
        end
      end
    end
  end
end
