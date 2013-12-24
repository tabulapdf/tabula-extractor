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

      top = lines.first.text_elements.map(&:top).min
      right = 0
      columns = []

      unless options[:vertical_rulings].empty?
        columns = options[:vertical_rulings].map(&:left) #pixel locations, not entities
        separators = columns.sort.reverse
      else
        text_chunks.each do |te|
          next if te.text =~ ONLY_SPACES_RE
          if te.top >= top
            left = te.left
            if (left > right)
              columns << right
              right = te.right
            elsif te.right > right
              right = te.right
            end
          end
        end
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
        spr.add_merged_cells!
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
        @vertical_ruling_lines ||= self.collapse_vertical_rulings(@ruling_lines.select(&:vertical?))
        @horizontal_ruling_lines ||= self.collapse_horizontal_rulings(@ruling_lines.select(&:horizontal?))
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




    def collapse_vertical_rulings(lines) #lines should all be of one orientation (i.e. horizontal, vertical)
      lines.sort! {|a, b| a.left != b.left ? a.left <=> b.left : a.top <=> b.top }

      #two-pass snap
      first = lines.shift
      grouped_lines = lines.inject( [[first]] ) do |memo, next_line|
        last = memo.last
        if (next_line.left - last.first.left).abs < self.min_char_width
          memo[-1] << next_line
        else
          memo << [next_line]
        end
        memo
      end
      snapped_lines = []
      grouped_lines.each do |group|
        uniq_locs = group.map(&:left).uniq
        avg_loc = uniq_locs.sum / uniq_locs.size
        group.each{|l| l.left = avg_loc; l.right = avg_loc; snapped_lines << l }
      end

      lines = snapped_lines.inject([lines.shift]) do |memo, next_line|
        last = memo.last
        if next_line.left == last.left && last.nearlyIntersects?(next_line)
          memo.last.top = next_line.top < last.top ? next_line.top : last.top
          memo.last.bottom = next_line.bottom < last.bottom ? last.bottom : next_line.bottom
          memo
        elsif next_line.length == 0
          memo
        else
          memo << next_line
        end
      end

      lines
    end

    def collapse_horizontal_rulings(lines) #lines should all be of one orientation (i.e. horizontal, vertical)
      # lines.each{|l| l.oriented_snap!(1, self.min_char_height)}

      lines.sort! {|a, b| a.top != b.top ? a.top <=> b.top : a.left <=> b.left }

      #two-pass snap
      first = lines.shift
      grouped_lines = lines.inject( [[first]] ) do |memo, next_line|
        last = memo.last
        if (next_line.top - last.first.top).abs < self.min_char_height
          memo[-1] << next_line
        else
          memo << [next_line]
        end
        memo
      end
      snapped_lines = []
      grouped_lines.each do |group|
        uniq_locs = group.map(&:top).uniq
        avg_loc = uniq_locs.sum / uniq_locs.size
        group.each{|l| l.top = avg_loc; l.bottom = avg_loc; snapped_lines << l }
      end

      lines = snapped_lines.inject([lines.shift]) do |memo, next_line|
        last = memo.last
        if next_line.top == last.top && last.nearlyIntersects?(next_line)
          memo.last.left = next_line.left < last.left ? next_line.left : last.left
          memo.last.right = next_line.right < last.right ? last.right : next_line.right
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
  
      #crappy snap

      # lines = lines.inject([lines.shift]) do |memo, next_line|
      #   last = memo.last
      #   if (next_line.top - last.top).abs < self.min_char_height
      #     if (next_line.left.between?(last.left, last.right) || next_line.right.between?(last.left, last.right))
      #     # memo.last.top += (next_line.top - last.top) / 2
      #     # memo.last.bottom = last.top
      #       memo.last.left = next_line.left < last.left ? next_line.left : last.left
      #       memo.last.right = next_line.right < last.right ? last.right : next_line.right
      #       memo
      #     else
      #       next_line.top  = last.top
      #       next_line.bottom = next_line.top
      #       memo << next_line
      #     end
      #   else
      #     memo << next_line
      #   end
      # end
      # puts lines.map(&:top).inspect

      #old collapse

      # lines = lines.inject([lines.shift]) do |memo, next_line|
      #   last = memo.last
      #   if next_line.top == last.top && last.nearlyIntersects?(next_line)
      #     memo.last.left = next_line.left < last.left ? next_line.left : last.left
      #     memo.last.right = next_line.right < last.right ? last.right : next_line.right
      #     memo
      #   # elsif (next_line.top - last.top) < self.min_char_height 
      #   #   # merge parallel horizontal lines that are close together (closer than the width of the shortest char)
      #   #   memo.last.top += (next_line.top - last.top) / 2
      #   #   memo.last.bottom = last.top
      #   #   memo.last.left = next_line.left < last.left ? next_line.left : last.left
      #   #   memo.last.right = next_line.right < last.right ? last.right : next_line.right
      #   #   memo
      #   elsif next_line.length == 0
      #     memo
      #   else
      #     memo << next_line
      #   end
      # end