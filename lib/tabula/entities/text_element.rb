module Tabula
  ##
  # a Glyph
  #TextElement = org.nerdpower.tabula.TextElement
  class TextElement < org.nerdpower.tabula.TextElement

    EMPTY = TextElement.new(0, 0, 0, 0, nil, 0, '', 0, 0)

    def inspect
      "#<TextElement: #{self.top.round(2)},#{self.left.round(2)},#{self.bottom.round(2)},#{right.round(2)} '#{self.text}'>"
    end

    def ==(other)
      self.text.strip == other.text.strip
    end
  end

end
