java_import org.nerdpower.tabula.Page

class Page
  include Tabula::HasCells
  attr_accessor :file_path, :cells

  #returns a Table object
  def get_table(options={})
    options = {:vertical_rulings => []}.merge(options)
    if texts.empty?
      return Tabula::Table.new(0, [])
    end

    text_chunks = Tabula::TextElement.merge_words(self.texts,
                                                  options[:vertical_rulings])

    lines = Tabula::TextChunk.group_by_lines(text_chunks)

    columns = unless options[:vertical_rulings].empty?
                options[:vertical_rulings].map(&:left).sort #pixel locations, not entities
              else
                Tabula::TextChunk.column_positions(lines).sort
              end

    table = Tabula::Table.new(lines.count, columns)
    lines.each_with_index do |line, i|
      line.text_elements.select { |te| te.text !~ Tabula::ONLY_SPACES_RE }.each do |te|
        j = columns.find_index { |s| te.left <= s } || columns.count
        table.add_text_element(te, i, j)
      end
    end

    table
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

    self.snap_points!

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

  def snap_points!
    lines_to_points = {}
    points = []

    @ruling_lines.each do |line|
      point1 = line.p1 #comptooters are the wurst
      point2 = line.p2
      # for a given line, each call to #p1 and #p2 creates a new
      # Point2D::Float object, rather than returning the same one over and
      # over again.
      # so we have to get it, store it in memory as `point1` and `point2`
      # and then store those in various places (and now, modifying one will
      # modify the reference and thereby modify the other)
      lines_to_points[line] = [point1, point2]
      points += [point1, point2]
    end

    # lines are stored separately from their constituent points
    # so you can't modify the points and then modify the lines.
    # ah, but perhaps I can stick the points in a hash AND in an array
    # and then modify the lines by means of the points in the hash.

    [[:x, :x=, self.min_char_width], [:y, :y=, self.min_char_height]].each do |getter, setter, cell_size|
      sorted_points = points.sort_by(&getter)
      first_point = sorted_points.shift
      grouped_points = sorted_points.inject([[first_point]] ) do |memo, next_point|
        last = memo.last

        if (next_point.send(getter) - last.first.send(getter)).abs < cell_size
          memo[-1] << next_point
        else
          memo << [next_point]
        end
        memo
      end
      grouped_points.each do |group|
        uniq_locs = group.map(&getter).uniq
        avg_loc = uniq_locs.sum / uniq_locs.size
        group.each{|p| p.send(setter, avg_loc) }
      end
    end

    lines_to_points.each do |l, p1_p2|
      l.java_send :setLine, [java.awt.geom.Point2D, java.awt.geom.Point2D], p1_p2[0], p1_p2[1]
    end
  end
end

module Tabula
  Page = ::Page
end
