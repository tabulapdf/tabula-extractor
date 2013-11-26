module Tabula
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

      (self.vertically_overlaps?(other) &&
        self.horizontal_distance(other).abs.between?(self.width_of_space * (1 - TOLERANCE_FACTOR), self.width_of_space * (1 + TOLERANCE_FACTOR))) ||
      (self.vertical_distance(other) > self.height)
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
end
