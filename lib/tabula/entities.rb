require_relative './core_ext'
require 'csv'

module Tabula

  class ZoneEntity < java.awt.geom.Rectangle2D::Float

    attr_accessor :texts

    def initialize(top, left, width, height)
      super()
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

      self.java_send :setRect, [Java::float, Java::float, Java::float, Java::float,], self.left, self.top, self.width, self.height
    end

    ##
    # default sorting order for ZoneEntity objects
    # is lexicographical (left to right, top to bottom)
    def <=>(other)
      return  1 if self.left > other.left
      return -1 if self.left < other.left
      return  1 if self.top  > other.top
      return -1 if self.top  < other.top
      return  0
    end

    def to_json(options={})
      self.to_h.to_json
    end

    def tlbr
      [top, left, bottom, right]
    end
  end

  class Page < ZoneEntity
    attr_reader :rotation, :number_one_indexed, :file_path

    def initialize(file_path, width, height, rotation, number, texts=[])
      super(0, 0, width, height)
      @rotation = rotation
      if number < 1
        raise ArgumentError, "Tabula::Page numbers are one-indexed; numbers < 1 are invalid."
      end
      @file_path = file_path
      @number_one_indexed = number
      self.texts = texts
      @ruling_lines = []
    end

    def number(indexing_base=:one_indexed)
      if indexing_base == :zero_indexed
        return @number_one_indexed - 1
      else
        return @number_one_indexed
      end
    end

    def ruling_lines(options={})
      if @ruling_lines.empty?
        @ruling_lines = get_ruling_lines(options)
      end
      @ruling_lines
    end

    #memoize the ruling lines, since getting them can hypothetically be expensive
    def get_ruling_lines(options={})
      options[:render_pdf] ||= false
      Tabula::Extraction::LineExtractor.lines_in_pdf_page(file_path, number(:zero_indexed), options)
    end

    # get text, optionally from a provided area in the page [top, left, bottom, right]
    ##
    # get text insidea area
    # area can be an Array ([top, left, width, height])
    # or a Rectangle2D
    def get_text(area=nil)
      # spaces are not detected, b/c they have height == 0
      # ze = ZoneEntity.new(area[0], area[1], area[3] - area[1], area[2] - area[0])
      # self.texts.select { |t| t.overlaps? ze }
      self.texts.select do |t|
        t.top > area[0] && t.top + t.height < area[2] && t.left > area[1] && t.left + t.width < area[3]
      end
    end

    def get_cell_text(area=nil)
      area = Rectangle2D::Float.new(0, 0, width, height) if area.nil?
      # puts ""

      texts = self.texts.select do |t|
        # if t.top >= 76.0 && t.bottom <= 84
        #   puts [t.text, t.top, t.bottom].inspect
        # end
        t.top.between?(area.top, area.bottom) &&
        #t.top >= area.top && t.vertical_midpoint <= area.bottom) && \
        t.horizontal_midpoint.between?(area.left, area.right)
        #t.horizontal_midpoint >= area.left && t.horizontal_midpoint <= area.right
      end
      # puts ""

      texts
    end

    def ruling_lines(options={})
      if @ruling_lines.empty?
        @ruling_lines = get_ruling_lines(options)
      end
      @ruling_lines
    end

    #memoize the ruling lines, since getting them can hypothetically be expensive
    def get_ruling_lines(options={})
      options[:render_pdf] ||= false
      Tabula::Extraction::LineExtractor.lines_in_pdf_page(file_path, number(:zero_indexed), options)
    end

    def get_cell_text(area=nil)
      area = Rectangle2D::Float.new(0, 0, width, height) if area.nil?
      # puts ""

      texts = self.texts.select do |t|
        # if t.top >= 76.0 && t.bottom <= 84
        #   puts [t.text, t.top, t.bottom].inspect
        # end
        t.top.between?(area.top, area.bottom) &&
        #t.top >= area.top && t.vertical_midpoint <= area.bottom) && \
        t.horizontal_midpoint.between?(area.left, area.right)
        #t.horizontal_midpoint >= area.left && t.horizontal_midpoint <= area.right
      end
      # puts ""

      texts
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

  ##
  # a "collection" of TextElements
  class TextChunk < ZoneEntity
    attr_accessor :font, :font_size, :text_elements, :width_of_space

    ##
    # initialize a new TextChunk from a TextElement
    def self.create_from_text_element(text_element)
      raise TypeError, "argument is not a TextElement" unless text_element.instance_of?(TextElement)
      tc = self.new(text_element.top, text_element.left, text_element.width, text_element.height)
      tc.text_elements = [text_element]
      return tc
    end

    ##
    # add a TextElement to this TextChunk
    def <<(text_element)
      self.text_elements << text_element
      self.merge!(text_element)
    end

    def merge!(other)
      if other.instance_of?(TextChunk)
        if self.horizontally_overlaps?(other) and other.top < self.top
          self.text_elements = other.text_elements + self.text_elements
        else
          self.text_elements = self.text_elements + other.text_elements
        end
      end
      super(other)
    end

    ##
    # split this TextChunk vertically
    # (in place, returns the remaining chunk)
    def split_vertically!(y)
      raise "Not Implemented"
    end

    ##
    # remove leading and trailing whitespace
    # (changes geometry accordingly)
    # TODO horrible implementation - fix.
    def strip!
      acc = 0
      new_te = self.text_elements.drop_while { |te|
        te.text == ' ' && acc += 1
      }
      self.left += self.text_elements.take(acc).inject(0) { |m, te| m += te.width }
      self.text_elements = new_te

      self.text_elements.reverse!
      acc = 0
      new_te = self.text_elements.drop_while { |te|
        te.text == ' ' && acc += 1
      }
      self.right -= self.text_elements.take(acc).inject(0) { |m, te| m += te.width }
      self.text_elements = new_te.reverse
      self
    end

    def text
      self.text_elements.map(&:text).join
    end

    def inspect
      "#<TextChunk: #{self.top.round(2)},#{self.left.round(2)},#{self.bottom.round(2)},#{right.round(2)} '#{self.text}'>"
    end

    def to_h
      super.merge(:text => self.text)
    end
  end

  ##
  # a Glyph
  class TextElement < ZoneEntity
    attr_accessor :font, :font_size, :text, :width_of_space

    TOLERANCE_FACTOR = 0.25

    def initialize(top, left, width, height, font, font_size, text, width_of_space)
      super(top, left, width, height)
      self.font = font
      self.font_size = font_size
      self.text = text
      self.width_of_space = width_of_space
    end

    EMPTY = TextElement.new(0, 0, 0, 0, nil, 0, '', 0)

    # more or less returns True if distance < tolerance
    def should_merge?(other)
      raise TypeError, "argument is not a TextElement" unless other.instance_of?(TextElement)

      self.vertically_overlaps?(other) && self.horizontal_distance(other) < width_of_space * 1.1 && !self.should_add_space?(other)
    end

    # more or less returns True if (tolerance <= distance < CHARACTER_DISTANCE_THRESHOLD*tolerance)
    def should_add_space?(other)
      raise TypeError, "argument is not a TextElement" unless other.instance_of?(TextElement)

      self.vertically_overlaps?(other) \
        && self.horizontal_distance(other).abs.between?(self.width_of_space * (1 - TOLERANCE_FACTOR), self.width_of_space * (1 + TOLERANCE_FACTOR))
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
      super.merge({:font => self.font, :text => self.text })
    end

    def inspect
      "#<TextElement: #{self.top.round(2)},#{self.left.round(2)},#{self.bottom.round(2)},#{right.round(2)} '#{self.text}'>"
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
        empties = line.text_elements.map{|t| t.nil? || t.text.empty? }
        min_leading_empty_strings = [min_leading_empty_strings, empties.index(false)].min
      end
      if min_leading_empty_strings == 0
        @lines
      else
        @lines.each{|line| line.text_elements = line.text_elements[min_leading_empty_strings..-1]}
        @lines
      end
    end
    def lstrip_lines!
      @lines = self.lstrip_lines
    end

    #used for testing, ignores separator locations (they'll sometimes be nil/empty)
    def ==(other)
      self.instance_variable_set(:@lines, self.lstrip_lines)
      other.instance_variable_set(:@lines, other.lstrip_lines)
      self.instance_variable_set(:@lines, self.lines.rpad(nil, other.lines.size))
      other.instance_variable_set(:@lines, other.lines.rpad(nil, self.lines.size))

      self.lines.zip(other.lines).all? { |my, yours| my == yours }

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
          # TODO: @jeremybmerill why? Commenting this out for now
#          unless in_same_column.vertically_overlaps?(t)
#            t.text = " " + t.text
#          end
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

  require_relative './core_ext'

  # TODO make it a heir of java.awt.geom.Line2D::Float
  class Ruling < ZoneEntity

    attr_accessor :stroking_color
    EXPANSION_COEFFICIENT = 0.01
    PIXEL_BLOOP_AMOUNT = 2


    def initialize(top, left, width, height, stroking_color=nil)
      super(top, left, width, height)
      self.stroking_color = stroking_color
      normalize!
    end

    def normalize!
      # sometimes lines come out of LSD with top > bottom or left > right
      #this is, of course, nonsense, so here we fix it.
      if top > bottom
        bukkit = top
        self.top = bottom
        self.bottom = bukkit
      end
      if left > right
        bukkit = left
        self.left = right
        #right = wrong
        self.right = bukkit
      end
    end

    # 2D line intersection test taken from comp.graphics.algorithms FAQ
    def intersects?(other)
      r = ((self.top-other.top)*(other.right-other.left) - (self.left-other.left)*(other.bottom-other.top)) \
        / ((self.right-self.left)*(other.bottom-other.top)-(self.bottom-self.top)*(other.right-other.left))
      s = ((self.top-other.top)*(self.right-self.left) - (self.left-other.left)*(self.bottom-self.top)) \
        / ((self.right-self.left)*(other.bottom-other.top) - (self.bottom-self.top)*(other.right-other.left))
      r >= 0 && r < 1 && s >= 0 && s < 1
    end

    # ugh I can't come up with a good name for this
    # but what it does is expand each line outwards by EXPANSION_COEFFICIENT in each direction
    # then we can (in #nearlyIntersects?) check if lines nearly intersect -- i.e. if their blooped counterparts strictly intersect
    def bloop
      r = Ruling.new(self.top, self.left, self.width, self.height)
      if r.horizontal?
        r.left = r.left - PIXEL_BLOOP_AMOUNT #* (1 - EXPANSION_COEFFICIENT)
        r.right = (r.right + PIXEL_BLOOP_AMOUNT) #* (1 + EXPANSION_COEFFICIENT)
      elsif r.vertical?
        r.top = r.top - PIXEL_BLOOP_AMOUNT #* (1 - EXPANSION_COEFFICIENT)
        r.bottom = r.bottom + PIXEL_BLOOP_AMOUNT #* (1 + EXPANSION_COEFFICIENT)
      end
      r
    end

    def nearlyIntersects?(another)
      if self.to_line.intersectsLine(another.to_line)
        return true
      else
        result = self.bloop.to_line.intersectsLine(another.bloop.to_line)
        return result
      end
    end

    def intersect(area)
      i = self.createIntersection(area)
      self.top    = i.top
      self.left   = i.left
      self.bottom = i.bottom
      self.right  = i.right
      self
    end

    #for comparisons, deprecate when this inherits from Line2D
    def to_line
      java.awt.geom.Line2D::Float.new(left, top, right, bottom)
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

    # crop an enumerable of +Ruling+ to an +area+
    def self.crop_rulings_to_area(rulings, area)
      rulings.reduce([]) do |memo, r|
        if r.to_line.intersects(area)
          i = r.createIntersection(area)
          memo << self.new(i.getY, i.getX, i.getWidth, i.getHeight)
        end
        memo
      end
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

  class Cell < ZoneEntity
    attr_accessor :text_elements, :placeholder, :merged

    def initialize(top, left, width, height)
      super(top, left, width, height)
      @placeholder = false
      @merged = false
      @text_elements = []
    end

    def text(debug=false)
      return "placeholder" if @placeholder && debug
      output = ""
      text_elements.sort{|te1, te2| te1.top != te2.top ? te1.top <=> te2.top : te1.left <=> te2.left } #sort low to high, then tiebreak with left to right
      text_elements.each do |el|
        #output << " " if !output[-1].nil? && output[-1] != " " && el.text[0] != " "
        output << el.text
      end
      if output.empty? && debug
        output = "width: #{width} h: #{height}"
      end
      output
    end
  end

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
