# -*- coding: utf-8 -*-
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

    def self.within(first, second, variance )
      second < first + variance && second > first - variance
    end

    def self.overlap(y1, height1, y2, height2, variance=0.1)
      within( y1, y2, variance) || (y2 <= y1 && y2 >= y1 - height1) \
      || (y1 <= y2 && y1 >= y2-height2)
    end


    ##
    # heuristically merge an iterable of TextElement into a list of TextChunk
    # lots of ideas taken from PDFBox's PDFTextStripper.writePage
    # here be dragons
    def self.merge_words(text_elements, options={})
      default_options = {:vertical_rulings => []}
      options = default_options.merge(options)
      vertical_ruling_locations = options[:vertical_rulings].map(&:left) if options[:vertical_rulings]

      return [] if text_elements.empty?

      text_chunks = [TextChunk.create_from_text_element(text_elements.shift)]


      endOfLastTextX = text_chunks.first.right
      maxYForLine = text_chunks.first.bottom
      maxHeightForLine = text_chunks.first.height
      minYTopForLine = text_chunks.first.top
      sp = nil

      char_widths_so_far = []
      word_spacings_so_far = []

      text_elements.inject(text_chunks) do |chunks, char|

        current_chunk = chunks.last
        prev_char = current_chunk.text_elements.last

        # Resets the character/spacing widths (used for averages) when we see a change in font
        # or a change in the font size
        if (char.font != prev_char.font) || (char.font_size != prev_char.font_size)
          char_widths_so_far = []
          word_spacings_so_far = []
        end

        # if same char AND overlapped, skip
        if (prev_char.text == char.text) && prev_char.overlaps_with_ratio?(char, 0.5)
          next chunks
        end

        # if char is a space that overlaps with the prev_char, skip
        if char.text == ' ' && prev_char.left == char.left && prev_char.top == char.top
          next chunks
        end

        # any vertical ruling goes across prev_char and char?
        across_vertical_ruling = vertical_ruling_locations.any? { |loc|
          prev_char.left < loc && char.left > loc
        }

        # Estimate the expected width of the space based on the
        # average width of the space character with some margin
        wordSpacing = char.width_of_space
        deltaSpace  = 0
        deltaSpace = if (wordSpacing.nan? || wordSpacing == 0)
                       ::Float::MAX
                     elsif word_spacings_so_far.empty?
                       wordSpacing * 0.5 # 0.5 == spacingTolerance
                     else
                       (word_spacings_so_far.reduce(&:+).to_f / word_spacings_so_far.size) * 0.5
                     end

        word_spacings_so_far << wordSpacing
        char_widths_so_far << (char.width / char.text.size)

        # Estimate the expected width of the space based on the
        # average character width with some margin. Based on experiments we also found that
        # .3 worked well.
        averageCharWidth = char_widths_so_far.reduce(&:+).to_f / char_widths_so_far.size

        deltaCharWidth = averageCharWidth * 0.3 # 0.3 == averageCharTolerance

        # Compares the values obtained by the average method and the wordSpacing method and picks
        # the smaller number.
        expectedStartOfNextWordX = -::Float::MAX

        if endOfLastTextX != -1
          expectedStartOfNextWordX = endOfLastTextX + [deltaCharWidth, deltaSpace].min
        end

        sameLine = true
        if !overlap(char.bottom, char.height, maxYForLine, maxHeightForLine)
          endOfLastTextX = -1
          expectedStartOfNextWordX = -::Float::MAX
          maxYForLine = -::Float::MAX
          maxHeightForLine = -1
          minYTopForLine = ::Float::MAX
          sameLine = false
        end

        # characters tend to be ordered by their left location
        # in determining whether to add a space, we need to know the distance
        # between the current character's left and the nearest character's 
        # right. The nearest character may not be the previous character, so we
        # need to keep track of the character with the greatest right x-axis
        # location -- that's endOfLastTextX
        # (in some fonts, one character may be completely "on top of"
        # another character, with the wider character starting to the left and 
        # ending to the right of the narrower character,  e.g. ANSI 
        # representations of some South Asian languages, see 
        # https://github.com/tabulapdf/tabula/issues/303)
        endOfLastTextX = [char.right, endOfLastTextX].max

        # should we add a space?
        if !across_vertical_ruling \
          && sameLine \
          && expectedStartOfNextWordX < char.left \
          && !prev_char.text.end_with?(' ')

          sp = self.new(prev_char.top,
                        prev_char.right,
                        expectedStartOfNextWordX - prev_char.right,
                        prev_char.height,
                        prev_char.font,
                        prev_char.font_size,
                        ' ',
                        prev_char.width_of_space)
          current_chunk << sp
        else
          sp = nil
        end

        maxYForLine = [char.bottom, maxYForLine].max
        maxHeightForLine = [maxHeightForLine, char.height].max
        minYTopForLine = [minYTopForLine, char.top].min

        # if sameLine
        #   puts "prev: #{prev_char.text} - char: #{char.text} - diff: #{char.left - prev_char.right} - space: #{[deltaCharWidth, deltaSpace].min} - spacing: #{wordSpacing} - sp: #{!sp.nil?}"
        # else
        #   puts
        # end


        dist = (char.left - (sp ? sp.right : prev_char.right))

        if !across_vertical_ruling \
           && sameLine \
           && (dist < 0 ? current_chunk.vertically_overlaps?(char) : dist < wordSpacing)
          current_chunk << char
        else
          # create a new chunk
          chunks << TextChunk.create_from_text_element(char)
        end

        chunks
      end.each{|chunk| chunk.text_elements.sort_by!{|char| char.left + char.right } }
    end

    ##
    # merge this TextElement with another (adjust size and text content accordingly)
    def merge!(other)
      raise TypeError, "argument is not a TextElement" unless other.instance_of?(TextElement)

      if (self <=> other) < 0
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
