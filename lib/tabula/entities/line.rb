module Tabula
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
        self.text_elements << t
        self.merge!(t)
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
end
