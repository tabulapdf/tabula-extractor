module Tabula
  ##
  # a "collection" of TextElements
  class TextChunk < ZoneEntity
    attr_accessor :font, :font_size, :text_elements, :width_of_space

    SPACE_RUN_MAX_LENGTH = 3

    ##
    # initialize a new TextChunk from a TextElement
    def self.create_from_text_element(text_element)
      raise TypeError, "argument is not a TextElement" unless text_element.instance_of?(TextElement)
      tc = self.new(text_element.top, text_element.left, text_element.width, text_element.height)
      tc.text_elements = [text_element]
      return tc
    end

    ##
    # group an iterable of TextChunk into a list of Line
    def self.group_by_lines(text_chunks)

      lines = text_chunks.inject([]) do |memo, te|
        next memo if te.text =~ ONLY_SPACES_RE
        l = memo.find { |line| line.horizontal_overlap_ratio(te) >= 0.01 }
        if l.nil?
          l = Line.new
          memo << l
        end
        l << te
        memo
      end

      # for each line, remove runs of the space char
      # should not change dimensions of the container +Line+
      lines.each do |l|
        l.text_elements = l.text_elements.reduce([]) do |memo, text_chunk|
          long_space_runs = text_chunk
            .text_elements
            .chunk { |te| te.text == ' '}  # detect runs of spaces...
            .select { |is_space, text_elements| # ...longer than SPACE_RUN_MAX_LENGTH
              is_space && !text_elements.nil? && text_elements.size >= SPACE_RUN_MAX_LENGTH
            }
            .map { |_, text_elements| text_elements }

          # no long runs of spaces
          # keep as it was and end iteration
          if long_space_runs.empty?
            memo << text_chunk
            next memo
          end

          ranges = long_space_runs.map { |lsr|
            idx = text_chunk
              .text_elements
              .index { |te| te.equal?(lsr.first) } # we need pointer comparison here
            (idx)..(idx+lsr.size-1)
          }

          in_run = false
          new_chunk = true
          text_chunk
            .text_elements
            .each_with_index do |te, i|
            if ranges.any? { |r| r.include?(i) } # te belongs to a run of spaces, skip
              in_run = true
            else
              if in_run || new_chunk
                memo << TextChunk.create_from_text_element(te)
              else
                memo.last << te
              end
              in_run = new_chunk = false
            end
          end
          memo
        end # reduce
      end # each
      lines
    end

    def <=>(other)
      yDifference = (self.bottom - other.bottom).abs
      if yDifference < 0.1 ||
          (other.bottom >= self.top && other.bottom <= self.bottom) ||
          (self.bottom >= other.top && self.bottom <= other.bottom)
        self.left <=> other.left
      else
        self.bottom <=> other.bottom
      end
    end

    ##
    # calculate estimated columns from an iterable of +Tabula::Line+
    def self.column_positions(lines)
      right = 0
      columns = []

      top = lines.min_by(&:top).top

      lines.map(&:text_elements).flatten.each do |te|
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
      columns
    end

    ##
    # add a TextElement to this TextChunk
    def <<(text_element)
      self.text_elements << text_element
      self.merge!(text_element)
    end

    def merge!(other)
      if other.instance_of?(TextChunk)
        if (self <=> other) < 0
          self.text_elements = self.text_elements + other.text_elements
        else
          self.text_elements = other.text_elements + self.text_elements
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
end
