java_import Java::TechnologyTabula::TextChunk

##
# a "collection" of TextElements
# class TextChunk
#   attr_accessor :font, :font_size, :width_of_space

#   def inspect
#     "#<TextChunk: #{self.top.round(2)},#{self.left.round(2)},#{self.bottom.round(2)},#{right.round(2)} '#{self.text}'>"
#   end

#   def to_h
#     super.merge(:text => self.text)
#   end
# end


module Tabula
  TextChunk = Java::TechnologyTabula::TextChunk
end
