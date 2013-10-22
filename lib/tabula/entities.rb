require_relative './core_ext'

module Tabula

  class ZoneEntity < java.awt.geom.Rectangle2D::Float

    attr_accessor :texts

    def initialize(top, left, width, height)
      super()
      # super(left, top, width, height)
      if left && top && width && height
        self.java_send :setRect, [Java::float, Java::float, Java::float, Java::float,], left, top, width, height
      end
      self.texts = []
    end

    def merge!(other)
      self.top    = [self.top, other.top].min
      self.left   = [self.left, other.left].min
      self.width  = [self.right, other.right].max - left
      self.height = [self.bottom, other.bottom].max - top
    end

    def to_json(options={})
      self.to_h.to_json
    end
  end

  class Page < ZoneEntity
    attr_reader :rotation, :number

    def initialize(width, height, rotation, number, texts=[])
      super(0, 0, width, height)
      @rotation = rotation
      @number = number
      self.texts = texts
    end

    # get text, optionally from a provided area in the page [top, left, bottom, right]
    def get_text(area=nil)
      area = [0, 0, width, height] if area.nil?

      # spaces are not detected, b/c they have height == 0
      # ze = ZoneEntity.new(area[0], area[1], area[3] - area[1], area[2] - area[0])
      # self.texts.select { |t| t.overlaps? ze }
      self.texts.select do |t|
        t.top > area[0] && t.top + t.height < area[2] && t.left > area[1] && t.left + t.width < area[3]
      end
    end

    def to_json(options={})
      { :width => self.width,
        :height => self.height,
        :number => self.number,
        :rotation => self.rotation,
        :texts => self.texts
      }.to_json(options)
    end

  end

  class TextElement < ZoneEntity
    attr_accessor :font, :font_size, :text, :width_of_space

    CHARACTER_DISTANCE_THRESHOLD = 1.5
    TOLERANCE_FACTOR = 0.3 #25

    def initialize(top, left, width, height, font, font_size, text, width_of_space)
      super(top, left, width, height)
      self.font = font
      self.font_size = font_size
      self.text = text
      self.width_of_space = width_of_space
    end

    EMPTY = TextElement.new(0, 0, 0, 0, nil, 0, '', 0)

    # def self.empty
    #   TextElement.new(0, 0, 0, 0, nil, 0, '', 0)
    # end

    # more or less returns True if distance < tolerance
    def should_merge?(other)
      raise TypeError, "argument is not a TextElement" unless other.instance_of?(TextElement)
      overlaps = self.vertically_overlaps?(other)

      tolerance = ((self.width + other.width) / 2) * TOLERANCE_FACTOR

      overlaps && self.horizontal_distance(other) < tolerance && !self.should_add_space?(other)
    end

    # more or less returns True if (tolerance <= distance < CHARACTER_DISTANCE_THRESHOLD*tolerance)
    def should_add_space?(other)
      raise TypeError, "argument is not a TextElement" unless other.instance_of?(TextElement)
#      return false if other == ' '
      overlaps = self.vertically_overlaps?(other)

      dist = self.horizontal_distance(other).abs
      overlaps && dist.between?(self.width_of_space * (1 - TOLERANCE_FACTOR), self.width_of_space * (1 + TOLERANCE_FACTOR))
    end

    def merge!(other)
      raise TypeError, "argument is not a TextElement" unless other.instance_of?(TextElement)
      if self.horizontally_overlaps?(other) and other.top < self.top
        self.text = other.text + self.text
      else
        self.text << other.text
      end
      super(other)
    end

    def to_h
      hash = super
      [:font, :text].each do |m|
        hash[m] = self.send(m)
      end
      hash
    end

    def ==(other)
      self.text.strip == other.text.strip
    end
  end

  class Table
    attr_reader :lines
    def initialize(line_count, separators)
      @separators = separators
      @lines = (0...line_count).inject([]) { |m| m << Line.new }
    end

    def add_text_element(text_element, i, j)
      if @lines.size <= i
        @lines[i] = Line.new
      end
      if @lines[i].text_elements[j]
        @lines[i].text_elements[j].merge!(text_element)
      else
        @lines[i].text_elements[j] = text_element
      end
    end

    #TODO: move to csv/tsv 'writer' methods here

    # create a new Table object from an array of arrays, representing a list of rows in a spreadsheet
    # probably only used for testing
    def self.new_from_array(array_of_rows)
      t = Table.new(array_of_rows.size, [])
      array_of_rows.each_with_index do |row, index|
        t.lines[index].text_elements = row.map{|cell| TextElement.new(nil, nil, nil, nil, nil, nil, cell, nil)}
      end
      t
    end

    #for equality testing, return @lines stripped of leading columns of empty strings
    #TODO: write a method to strip all totally-empty columns (or not?)
    def lstrip_lines
      return @lines if @lines.include?(nil)
      min_leading_empty_strings = Float::INFINITY
      @lines.each do |line|
        empties = line.text_elements.map{|t| t.text.empty? }
        min_leading_empty_strings = [min_leading_empty_strings, empties.index(false)].min
      end
      if min_leading_empty_strings == 0
        @lines
      else
        @lines.each{|line| line.text_elements = line.text_elements[min_leading_empty_strings..-1]}
        @lines
      end
    end

    #used for testing, ignores separator locations (they'll sometimes be nil/empty)
    def ==(other)
      puts other.lines.inspect
      self.instance_variable_set(:@lines, self.lstrip_lines)
      other.instance_variable_set(:@lines, other.lstrip_lines)
      puts other.lines.inspect
      self.instance_variable_set(:@lines, self.lines.rpad(nil, other.lines.size))
      other.instance_variable_set(:@lines, other.lines.rpad(nil, self.lines.size))
      puts other.lines.inspect

      self.lines.zip(other.lines).inject(true) do |memo, my_yours|
        my, yours = my_yours
        memo && my == yours
      end

    end
  end

  class Line < ZoneEntity
    attr_accessor :text_elements
    attr_reader :index

    def initialize(index=nil)
      @text_elements = []
      @index = index
    end

    def <<(t)
      if @text_elements.size == 0
        @text_elements << t
        self.top = t.top
        self.left = t.left
        self.width = t.width
        self.height = t.height
      else
        if in_same_column = @text_elements.find { |te| te.horizontally_overlaps?(t) }
          #sometimes a space needs to be added here
          unless in_same_column.vertically_overlaps?(t)
            t.text = " " + t.text
          end
          in_same_column.merge!(t)
        else
          self.text_elements << t
          self.merge!(t)
        end
      end
    end

    #used for testing, ignores text element stuff besides stripped text.
    def ==(other)
      return false if other.nil?
      self.text_elements = self.text_elements.rpad(TextElement::EMPTY, other.text_elements.size)
      other.text_elements = other.text_elements.rpad(TextElement::EMPTY, self.text_elements.size)
      self.text_elements.zip(other.text_elements).inject(true) do |memo, my_yours|
        my, yours = my_yours
        memo && my == yours
      end
    end
  end

  class Column < ZoneEntity
    attr_accessor :text_elements

    def initialize(left, width, text_elements=[])
      super(0, left, width, 0)
      @text_elements = text_elements
    end

    def <<(te)
      self.text_elements << te
      self.update_boundaries!(te)
      self.text_elements.sort_by! { |t| t.top }
    end

    def update_boundaries!(text_element)
      self.merge!(text_element)
    end

    # this column can be merged with other_column?
    def contains?(other_column)
      self.horizontally_overlaps?(other_column)
    end

    def average_line_distance
      # avg distance between lines
      # this might help to MERGE lines that are shouldn't be split
      # e.g. cells with > 1 lines of text
      1.upto(self.text_elements.size - 1).map { |i|
        self.text_elements[i].top - self.text_elements[i - 1].top
      }.inject{ |sum, el| sum + el }.to_f / self.text_elements.size
    end

    def inspect
      vars = (self.instance_variables - [:@text_elements]).map{ |v| "#{v}=#{instance_variable_get(v).inspect}" }
      texts = self.text_elements.sort_by { |te| te.top }.map { |te| te.text }
      "<#{self.class}: #{vars.join(', ')}, @text_elements=[#{texts.join('], [')}]>"
    end

  end

  require_relative './core_ext'

  class Ruling < ZoneEntity

    attr_accessor :stroking_color

    def initialize(top, left, width, height, stroking_color=nil)
      super(top, left, width, height)
      self.stroking_color = stroking_color
    end

    # 2D line intersection test taken from comp.graphics.algorithms FAQ
    def intersects?(other)
      r = ((self.top-other.top)*(other.right-other.left) - (self.left-other.left)*(other.bottom-other.top)) \
      / ((self.right-self.left)*(other.bottom-other.top)-(self.bottom-self.top)*(other.right-other.left))

        s = ((self.top-other.top)*(self.right-self.left) - (self.left-other.left)*(self.bottom-self.top)) \
            / ((self.right-self.left)*(other.bottom-other.top) - (self.bottom-self.top)*(other.right-other.left))

      r >= 0 and r < 1 and s >= 0 and s < 1
    end

    def length
      Math.sqrt( (self.right - self.left).abs ** 2 + (self.bottom - self.top).abs ** 2 )
    end

    def vertical?
      left == right
    end

    def horizontal?
      top == bottom
    end

    def right
      left + width
    end
    def bottom
      top + height
    end

    def to_json(arg)
      [left, top, right, bottom].to_json
    end

    def self.clean_rulings(rulings, max_distance=4)

      # merge horizontal and vertical lines
      # TODO this should be iterative

      skip = false

      horiz = rulings.select { |r| r.horizontal? }
        .group_by(&:top)
        .values.reduce([]) do |memo, rs|

        rs = rs.sort_by(&:left)
        if rs.size > 1
          memo +=
            rs.each_cons(2)
            .chunk { |p| p[1].left - p[0].right < 7 }
            .select { |c| c[0] }
            .map { |group|
            group = group.last.flatten.uniq
            Tabula::Ruling.new(group[0].top,
                               group[0].left,
                               group[-1].right - group[0].left,
                               0)
          }
          Tabula::Ruling.new(rs[0].top, rs[0].left, rs[-1].right - rs[0].left, 0)
        else
          memo << rs.first
        end
        memo
      end
        .sort_by(&:top)

      h = []
      horiz.size.times do |i|

        if i == horiz.size - 1
          h << horiz[-1]
          break
        end

        if skip
          skip = false;
          next
        end
        d = (horiz[i+1].top - horiz[i].top).abs

        h << if d < max_distance # THRESHOLD DISTANCE between horizontal lines
               skip = true
               Tabula::Ruling.new(horiz[i].top + d / 2, [horiz[i].left, horiz[i+1].left].min, [horiz[i+1].width.abs, horiz[i].width.abs].max, 0)
             else
               horiz[i]
             end
      end
      horiz = h

      vert = rulings.select { |r| r.vertical? }
        .group_by(&:left)
        .values
        .reduce([]) do |memo, rs|

        rs = rs.sort_by(&:top)

        if rs.size > 1
          # Here be dragons:
          # merge consecutive segments of lines that are close enough
          memo +=
            rs.each_cons(2)
            .chunk { |p| p[1].top - p[0].bottom < 7 }
            .select { |c| c[0] }
            .map { |group|
            group = group.last.flatten.uniq
            Tabula::Ruling.new(group[0].top,
                               group[0].left,
                               0,
                               group[-1].bottom - group[0].top)
          }
        else
          memo << rs.first
        end
        memo
      end.sort_by(&:left)

      return horiz += vert
    end




  end

end
