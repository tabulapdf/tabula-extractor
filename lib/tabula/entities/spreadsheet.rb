#java_import Java::TechnologyTabula::TableWithRulingLines

class Java::TechnologyTabula::TableWithRulingLines
  attr_accessor :vertical_ruling_lines, :horizontal_ruling_lines, :cells_resolved
  attr_reader :extraction_method, :page

  def self.empty(page)
    Spreadsheet.new(0, 0, 0, 0, page, [], nil, nil)
  end

  # def ruling_lines=(lines)
  #   @vertical_ruling_lines = lines.select{|vl| vl.vertical? && spr.intersectsLine(vl) }
  #   @horizontal_ruling_lines = lines.select{|hl| hl.horizontal? && spr.intersectsLine(hl) }
  # end

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

  # I don't think this is ever used in the new, thin-wrapper version of tabula-extractor. (that is, its functionality is contained entirely in tabula-java )
  # #######################################################
  # # Chapter 2 of Spreadsheet extraction, Spanning Cells #
  # #######################################################
  # #if c is a "spanning cell", that is
  # #              if there are N>0 vertical lines strictly between this cell's left and right
  # #insert N placeholder cells after it with zero size (but same top)
  # def add_spanning_cells!
  #   #rounding: because Cell.new_from_points, using in #find_cells above, has
  #   # a float precision error where, for instance, a cell whose x2 coord is
  #   # supposed to be 160.137451171875 comes out as 160.13745498657227 because
  #   # of minus. :(
  #   vertical_uniq_locs = vertical_ruling_lines.map{|l| l.left.round(5)}.uniq    #already sorted
  #   horizontal_uniq_locs = horizontal_ruling_lines.map{|l| l.top.round(5)}.uniq #already sorted

  #   cells.each do |c|
  #     vertical_rulings_spanned_over = vertical_uniq_locs.select{|l| l > c.left.round(5) && l < c.right.round(5) }
  #     horizontal_rulings_spanned_over = horizontal_uniq_locs.select{|t| t > c.top.round(5) && t < c.bottom.round(5) }

  #     unless vertical_rulings_spanned_over.empty?
  #       c.spanning = true
  #       vertical_rulings_spanned_over.each do |spanned_over_line_loc|
  #         placeholder = Cell.new(c.top, spanned_over_line_loc, 0, c.height)
  #         placeholder.placeholder = true
  #         cells << placeholder
  #       end
  #     end
  #     unless horizontal_rulings_spanned_over.empty?
  #       c.spanning = true
  #       horizontal_rulings_spanned_over.each do |spanned_over_line_loc|
  #         placeholder = Cell.new(spanned_over_line_loc, c.left, c.width, 0)
  #         placeholder.placeholder = true
  #         cells << placeholder
  #       end
  #     end

  #     #if there's a spanning cell that's spans over both rows and columns, then it has "double placeholder" cells
  #     # e.g. -------------------
  #     #      | C |  C |  C | C |         (this is some pretty sweet ASCII art, eh?)
  #     #      |-----------------|
  #     #      | C |  C |  C | C |
  #     #      |-----------------|
  #     #      | C | SC    P | C |   where MC is the "spanning cell" that holds all the text within its bounds
  #     #      |----    +    ----|         P is a "placeholder" cell with either zero width or zero height
  #     #      | C | P    DP | C |         DP is a "double placeholder" cell with zero width and zero height
  #     #      |----    +    ----|         C is an ordinary cell.
  #     #      | C | P    DP | C |
  #     #      |-----------------|

  #     unless (double_placeholders = vertical_rulings_spanned_over.product(horizontal_rulings_spanned_over)).empty?
  #       double_placeholders.each do |vert_spanned_over, horiz_spanned_over|
  #         placeholder = Cell.new(horiz_spanned_over, vert_spanned_over, 0, 0)
  #         placeholder.placeholder = true
  #         cells << placeholder
  #       end
  #     end
  #   end
  # end

  def to_a
    rows.map{ |row_cells| row_cells.map(&:text) }
  end

  def +(other)
    raise ArgumentError, "Data can only be added if it's from the same PDF page" unless other.page == @page
    t = self.class.new(Java::TechnologyTabula::Utils.bounds(java.util.ArrayList.new([self, other])),
                       @page,
                       java.util.ArrayList.new(self.getCells + other.getCells), nil, nil)
    t.setExtractionAlgorithm(Java::TechnologyTabulaExtractors::SpreadsheetExtractionAlgorithm.new)
    t
  end
end

module Tabula
  Spreadsheet = Java::TechnologyTabulaTableWithRulingLines
end
