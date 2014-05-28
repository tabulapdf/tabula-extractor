# -*- coding: utf-8 -*-
java_import org.nerdpower.tabula.TextElement

# reopen java class and add some methods
# eventually, most of these will be ported to java
class TextElement

  EMPTY = TextElement.new(0, 0, 0, 0, nil, 0, '', 0, 0)

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
