module Tabula
  class Line < java.awt.geom.Rectangle2D::Float
    attr_accessor :text_elements
    attr_reader :index

    SPACE_RUN_MAX_LENGTH = 3

    def initialize(index=nil)
      super()
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
        self.text_elements << t
        self.merge!(t)
      end
    end

    ##
    # remove runs of the space char longer than SPACE_RUN_MAX_LENGTH
    # should not change dimensions of the container +Line+
    def remove_sequential_spaces!(seq_spaces_count=SPACE_RUN_MAX_LENGTH)
      self.text_elements = self.text_elements.reduce([]) do |memo, text_chunk|
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
      self
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
end
