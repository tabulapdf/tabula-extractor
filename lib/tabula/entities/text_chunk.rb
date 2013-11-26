module Tabula
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
        if self.horizontally_overlaps?(other) && other.top < self.top
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
end
