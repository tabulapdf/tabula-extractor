class Tabula::Line < Java::TechnologyTabula::Line
    attr_reader :index

    #used for testing, ignores text element stuff besides stripped text.
    def ==(other)
      return false if other.nil?
      self.text_elements = self.text_elements.rpad(Tabula::TextElement::EMPTY, other.text_elements.size)
      other.text_elements = other.text_elements.rpad(Tabula::TextElement::EMPTY, self.text_elements.size)
      self.text_elements.zip(other.text_elements).inject(true) do |memo, my_yours|
        my, yours = my_yours
        memo && my == yours
      end
    end
end
