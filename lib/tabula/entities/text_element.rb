# -*- coding: utf-8 -*-
java_import org.nerdpower.tabula.TextElement

# reopen java class and add some methods
# eventually, most of these will be ported to java
class TextElement

  TOLERANCE_FACTOR = 0.25

  EMPTY = TextElement.new(0, 0, 0, 0, nil, 0, '', 0, 0)

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

    #first_te = text_elements.shift #remove(0)
    first_te = text_elements.remove(0.to_java(:int))
    text_chunks = [::Tabula::TextChunk.new(first_te)]

    previousAveCharWidth = text_chunks.first.width
    endOfLastTextX = text_chunks.first.right
    maxYForLine = text_chunks.first.bottom
    maxHeightForLine = text_chunks.first.height
    minYTopForLine = text_chunks.first.top
    lastWordSpacing = -1
    sp = nil

    # TODO get rid of this #inject and do a plain loop,
    # this method needs to return an ArrayList
    text_elements.inject(text_chunks) do |chunks, char|

      current_chunk = chunks.last
      prev_char = current_chunk.text_elements[current_chunk.text_elements.size - 1]

      # Resets the average character width when we see a change in font
      # or a change in the font size
      if (char.font != prev_char.font) || (char.font_size != prev_char.font_size)
        previousAveCharWidth = -1;
      end

      # if same char AND overlapped, skip
      if (prev_char.text == char.text) && (prev_char.overlap_ratio(char) >  0.5)
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
      # space character with some margin.
      wordSpacing = char.width_of_space
      deltaSpace  = 0
      deltaSpace = if (wordSpacing.nan? || wordSpacing == 0)
                     ::Float::MAX
                   elsif lastWordSpacing < 0
                     wordSpacing * 0.5 # 0.5 == spacingTolerance
                   else
                     ((wordSpacing + lastWordSpacing) / 2.0) * 0.5
                   end

      # Estimate the expected width of the space based on the
      # average character width with some margin. This calculation does not
      # make a true average (average of averages) but we found that it gave the
      # best results after numerous experiments. Based on experiments we also found that
      # .3 worked well.
      averageCharWidth = if previousAveCharWidth < 0
                           char.width / char.text.size
                         else
                           (previousAveCharWidth + (char.width / char.text.size)) / 2.0
                         end
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

      endOfLastTextX = char.right
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
        current_chunk.add(sp)
      else
        sp = nil
      end

      maxYForLine = [char.bottom, maxYForLine].max
      maxHeightForLine = [maxHeightForLine, char.height].max
      minYTopForLine = [minYTopForLine, char.top].min

      dist = (char.left - (sp ? sp.right : prev_char.right))

      if !across_vertical_ruling \
         && sameLine \
         && (dist < 0 ? current_chunk.vertically_overlaps?(char) : dist < wordSpacing)
        current_chunk.add(char)
      else
        # create a new chunk
        chunks << ::Tabula::TextChunk.new(char)
      end

      lastWordSpacing = wordSpacing
      previousAveCharWidth = sp ? (averageCharWidth + sp.width) / 2.0 : averageCharWidth

      chunks
    end
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

module Tabula
  ##
  # a Glyph
  TextElement = org.nerdpower.tabula.TextElement
end
