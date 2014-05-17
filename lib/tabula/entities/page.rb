java_import org.nerdpower.tabula.Page
java_import org.nerdpower.tabula.extractors.BasicExtractionAlgorithm

class Page
  include Tabula::HasCells
  attr_accessor :file_path, :cells

  #returns a Table object
  def get_table(options={})
    options = {:vertical_rulings => []}.merge(options)

    tables = if options[:vertical_rulings].empty?
               BasicExtractionAlgorithm.new.extract(self)
             else
               BasicExtractionAlgorithm.new(options[:vertical_rulings]).extract(self)
             end

    tables.first

  end

  #for API backwards-compatibility reasons, this returns an array of arrays.
  def make_table(options={})
    get_table(options).rows
  end

  # returns the Spreadsheets; creating them if they're not memoized
  def spreadsheets(options={})
    unless @spreadsheets.nil?
      return @spreadsheets
    end
    get_ruling_lines!

    self.find_cells!(self.horizontal_ruling_lines, self.vertical_ruling_lines, options)

    spreadsheet_areas = find_spreadsheets_from_cells #literally, java.awt.geom.Area objects. lol sorry. polygons.

    #transform each spreadsheet area into a rectangle
    # and get the cells contained within it.
    spreadsheet_rectangle_areas = spreadsheet_areas.map{ |a| a.getBounds2D }

    @spreadsheets = spreadsheet_rectangle_areas.map do |rect|
      spr = Tabula::Spreadsheet.new(rect.y, rect.x,
                            rect.width, rect.height,
                            self,
                            #TODO: keep track of the cells, instead of getting them again inefficiently.
                            [],
                            vertical_ruling_lines.select{|vl| rect.intersectsLine(vl) },
                            horizontal_ruling_lines.select{|hl| rect.intersectsLine(hl) }
                           )
      spr.cells = @cells.select{ |c| spr.intersects(c) }
      spr.add_spanning_cells!
      spr
    end
    if options[:fill_in_cells]
      fill_in_cells!
    end
    spreadsheets
  end

  def fill_in_cells!(options={})
    spreadsheets(options).each do |spreadsheet|
      spreadsheet.cells.each do |cell|
        cell.text_elements = page.get_cell_text(cell)
      end
      spreadsheet.cells_resolved = true
    end
  end

  def number(indexing_base=:one_indexed)
    if indexing_base == :zero_indexed
      return @number_one_indexed - 1
    else
      return @number_one_indexed
    end
  end

  # TODO no need for this, let's choose one name
  def ruling_lines
    get_ruling_lines!
  end

  def horizontal_ruling_lines
#    get_ruling_lines!
    @horizontal_ruling_lines
  end

  def vertical_ruling_lines
    get_ruling_lines!
    return @vertical_ruling_lines
  end

  #returns ruling lines, memoizes them in
  def get_ruling_lines!

    unless @ruling_lines.nil?
      return @ruling_lines
    end

    if self.getRulings.nil? || self.getRulings.empty?
      return []
    end

    @ruling_lines = self.getRulings

    self.snap_points

    @vertical_ruling_lines = ::Tabula::Ruling.collapse_oriented_rulings(@ruling_lines.select(&:vertical?))

    @horizontal_ruling_lines = ::Tabula::Ruling.collapse_oriented_rulings(@ruling_lines.select(&:horizontal?))

    rv = []
    # yes, I know, this is awful
    # it should be return vertical_ruling_lines + horizontal_ruling_lines
    # but it seems that the `+` method is modifying its first argument in place
    @vertical_ruling_lines.each { |v| rv << v }
    @horizontal_ruling_lines.each { |h| rv << h }
    rv
  end

  def get_cell_text(area=nil)
    TextElement.merge_words(self.get_text(area))
  end

  def to_json(options={})
    { :width => self.width,
      :height => self.height,
      :number => self.number,
      :rotation => self.rotation,
      :texts => self.text
    }.to_json(options)
  end
end

module Tabula
  Page = ::Page
end
