module Tabula
  class Page < ZoneEntity
    include Tabula::HasCells

    attr_reader :rotation, :number_one_indexed, :file_path
    attr_accessor :cells, :min_char_width, :min_char_height

    def initialize(file_path, width, height, rotation, number, texts=[], ruling_lines=[])
      super(0, 0, width, height)
      @rotation = rotation
      if number < 1
        raise ArgumentError, "Tabula::Page numbers are one-indexed; numbers < 1 are invalid."
      end
      @ruling_lines = ruling_lines
      @file_path = file_path
      @number_one_indexed = number
      self.texts = texts
      @cells = []
      @spreadsheets = nil
      @min_char_width = @min_char_height = 100000
    end

    def make_table(area, options={})
      options = {:vertical_rulings => []}.merge(options)
      if texts.empty?
        return []
      end

      text_elements = if area.nil?
                        self.texts # use whole page
                      elsif area.is_a?(Array)
                        top, left, bottom, right = area
                        self.get_text(Tabula::ZoneEntity.new(top, left,
                                                             right - left, bottom - top))
                      elsif area.is_a?(Tabula::ZoneEntity)
                        self.get_text(area)
                      end

      text_chunks = TextElement.merge_words(text_elements, options).sort

      lines = TextChunk.group_by_lines(text_chunks)

      unless options[:vertical_rulings].empty?
        columns = options[:vertical_rulings].map(&:left) #pixel locations, not entities
        separators = columns.sort.reverse
      else
        columns = TextChunk.column_positions(text_chunks)
        separators = columns[1..-1].sort.reverse
      end

      table = Table.new(lines.count, separators)
      lines.each_with_index do |line, i|
        line.text_elements.each do |te|
          j = separators.find_index { |s| te.left > s } || separators.count
          table.add_text_element(te, i, separators.count - j)
        end
      end

      table.lstrip_lines!

      table.lines.map do |l|
        l.text_elements.map! do |te|
          te || TextElement.new(nil, nil, nil, nil, nil, nil, '', nil)
        end
      end.sort_by { |l| l.map { |te| te.top or 0 }.max }
    end

    # returns the Spreadsheets; creating them if they're not memoized
    def spreadsheets(options={})
      unless @spreadsheets.nil?
        return @spreadsheets
      end
      get_ruling_lines!(options)
      self.find_cells!(options)

      spreadsheet_areas = find_spreadsheets_from_cells #literally, java.awt.geom.Area objects. lol sorry. polygons.

      #transform each spreadsheet area into a rectangle
      # and get the cells contained within it.
      spreadsheet_rectangle_areas = spreadsheet_areas.map{|a| a.getBounds } #getBounds2D is theoretically better, but returns a Rectangle2D.Double, which doesn't have our Ruby sugar on it.

      @spreadsheets = spreadsheet_rectangle_areas.map do |rect|
        spr = Spreadsheet.new(rect.y, rect.x,
                        rect.width, rect.height,
                        self,
                        #TODO: keep track of the cells, instead of getting them again inefficiently.
                        [],
                        vertical_ruling_lines.select{|vl| rect.intersectsLine(vl) },
                        horizontal_ruling_lines.select{|hl| rect.intersectsLine(hl) }
                        )
        spr.cells = @cells.select{|c| spr.overlaps?(c) }
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
          spreadsheet.cells_resolved = true
        end
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
      get_ruling_lines!
      @horizontal_ruling_lines.nil? ? [] : @horizontal_ruling_lines
    end

    def vertical_ruling_lines
      get_ruling_lines!
      @vertical_ruling_lines.nil? ? [] : @vertical_ruling_lines
    end

    #returns ruling lines, memoizes them in
    def get_ruling_lines!(options={})
      if !@ruling_lines.nil? && !@ruling_lines.empty?
        self.snap_points!
        @vertical_ruling_lines ||= self.collapse_oriented_rulings(@ruling_lines.select(&:vertical?))
        @horizontal_ruling_lines ||= self.collapse_oriented_rulings(@ruling_lines.select(&:horizontal?))
        @vertical_ruling_lines + @horizontal_ruling_lines
      else
        []
      end
    end

    ##
    # get text insidea area
    # area can be an Array ([top, left, width, height])
    # or a Rectangle2D
    def get_text(area=nil)
      if area.instance_of?(Array)
        top, left, bottom, right = area
        area = Tabula::ZoneEntity.new(top, left,
                                      right - left, bottom - top)
      end
      if area.nil?
        texts
      else
        texts.select do |t|
          area.contains(t)
        end
      end
    end

    def get_cell_text(area=nil)
      TextElement.merge_words(self.get_text(area))
    end

    def to_json(options={})
      { :width => self.width,
        :height => self.height,
        :number => self.number,
        :rotation => self.rotation,
        :texts => self.texts
      }.to_json(options)
    end

    def snap_points!
      x_sorted_points = points.sort_by(&:x)
      y_sorted_points = points.sort_by(&:y)

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

    def collapse_oriented_rulings(lines)
      # lines must all be of one orientation (i.e. horizontal, vertical)
      lines.sort! {|a, b| a.position != b.position ? a.position <=> b.position : a.start <=> b.start }

      lines = lines.inject([lines.shift]) do |memo, next_line|
        last = memo.last
        if next_line.position == last.position && last.nearlyIntersects?(next_line)
          memo.last.start = next_line.start < last.start ? next_line.start : last.start
          memo.last.end = next_line.end < last.end ? last.end : next_line.end
          memo
        elsif next_line.length == 0
          memo
        else
          memo << next_line
        end
      end

      lines
    end
  end

end
