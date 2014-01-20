module Tabula
  ##
  # a Glyph
  class TextElement < ZoneEntity
    attr_accessor :font, :font_size, :text, :width_of_space, :direction

    TOLERANCE_FACTOR = 0.25

    def initialize(top, left, width, height, font, font_size, text, width_of_space, direction=0)
      super(top, left, width, height)
      self.font = font
      self.font_size = font_size
      self.text = text
      self.width_of_space = width_of_space
      self.direction = direction
    end

    EMPTY = TextElement.new(0, 0, 0, 0, nil, 0, '', 0)

    ##
    # heuristically merge an iterable of TextElement into a list of TextChunk
    def self.merge_words(text_elements, options={})
      default_options = {:vertical_rulings => []}
      options = default_options.merge(options)
      vertical_ruling_locations = options[:vertical_rulings].map(&:left) if options[:vertical_rulings]

      return [] if text_elements.empty?

      text_chunks = [TextChunk.create_from_text_element(text_elements.shift)]

      text_elements.inject(text_chunks) do |chunks, char|
        current_chunk = chunks.last
        prev_char = current_chunk.text_elements.last

        # any vertical ruling goes across prev_char and char?
        across_vertical_ruling = vertical_ruling_locations.any? { |loc|
          prev_char.left < loc && char.left > loc
        }

        # should we add a space?
        if (prev_char.text != " ") && (char.text != " ") \
          && !across_vertical_ruling \
          && prev_char.should_add_space?(char)

          sp = self.new(prev_char.top,
                        prev_char.right,
                        prev_char.width_of_space,
                        prev_char.width_of_space, # width == height for spaces
                        prev_char.font,
                        prev_char.font_size,
                        ' ',
                        prev_char.width_of_space)
          chunks.last << sp
          prev_char = sp
        end

        # should_merge? isn't aware of vertical rulings, so even if two text elements are close enough
        # that they ought to be merged by that account.
        # we still shouldn't merge them if the two elements are on opposite sides of a vertical ruling.
        # Why are both of those `.left`?, you might ask. The intuition is that a letter
        # that starts on the left of a vertical ruling ought to remain on the left of it.
        if !across_vertical_ruling && prev_char.should_merge?(char)
          chunks.last << char
        else
          # create a new chunk
          chunks << TextChunk.create_from_text_element(char)
        end
        chunks
      end
    end

    # more or less returns True if distance < tolerance
    def should_merge?(other)
      raise TypeError, "argument is not a TextElement" unless other.instance_of?(TextElement)
      self.vertically_overlaps?(other) && self.horizontal_distance(other) < width_of_space * (1 + TOLERANCE_FACTOR) && !self.should_add_space?(other)
    end

    # more or less returns True if (tolerance <= distance < CHARACTER_DISTANCE_THRESHOLD*tolerance)
    def should_add_space?(other)
      raise TypeError, "argument is not a TextElement" unless other.instance_of?(TextElement)

      return false if self.width_of_space.nan?

      (self.vertically_overlaps?(other) &&
        self.horizontal_distance(other).abs.between?(self.width_of_space * (1 - TOLERANCE_FACTOR), self.width_of_space * (1 + TOLERANCE_FACTOR))) ||
      (self.vertical_distance(other) > self.height)
    end

    ##
    # merge this TextElement with another (adjust size and text content accordingly)
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
