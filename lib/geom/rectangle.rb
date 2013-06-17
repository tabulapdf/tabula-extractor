#
# Cribbed shamelessly from Daniel Vartanov's [ruby-geometry](https://github.com/DanielVartanov/ruby-geometry/)
# MIT License (c) 2008 Daniel Vartanov, modifications (c) 2013 Jeremy B. Merrill
#


module Geometry
  class Rectangle < Struct.new(:point1, :point2)
    SIMILARITY_DIVISOR = 20

    def Rectangle.unionize(non_overlapping_rectangles, next_rect)
      #if next_rect doesn't overlap any of non_overlapping_rectangles
      if (overlapping = non_overlapping_rectangles.select{|r| next_rect.overlaps? r}) && !non_overlapping_rectangles.empty?
        #remove all of those that it overlaps from non_overlapping_rectangles and 
        non_overlapping_rectangles -= overlapping
        #add to non_overlapping_rectangles the bounding box of the overlapping rectangles.
        non_overlapping_rectangles << overlapping.inject(next_rect){|memo, overlap| memo.bounding_box(overlap) }
      
      else
        non_overlapping_rectangles << next_rect
      end
    end

    def self.new_by_x_y_dims(x, y, width, height)
      self.new( Point.new_by_array([x, y]), Point.new_by_array([x + width, y + height]) )
    end

    def x
      [point1.x, point2.x].min
    end

    alias_method :left, :x

    def y
      #puts "y: [#{point1.y} #{point2.y}].min" 
      [point1.y, point2.y].min
    end

    alias_method :top, :y

    def x2
      [point1.x, point2.x].max
    end

    alias_method :right, :x2

    def y2
      #puts "y2: [#{point1.y} #{point2.y}].max" 
      [point1.y, point2.y].max
    end

    alias_method :bottom, :y2


    def width
      (point1.x - point2.x).abs
    end

    def height
      (point1.y - point2.y).abs
    end

    def area
      self.width * self.height
    end

    def similarity_hash
      [self.x.to_i / SIMILARITY_DIVISOR, self.y.to_i / SIMILARITY_DIVISOR, self.width.to_i / SIMILARITY_DIVISOR, self.height.to_i / SIMILARITY_DIVISOR].to_s
    end

    def dims(*format)
      if format
        format.map{|method| self.send(method)}
      else
        [self.x, self.y, self.width, self.height]
      end
    end

    def contains?(other_x, other_y)
      (other_x <= x2 && other_x >= x ) && (other_y <= y2 && other_y > y)
    end

    def overlaps?(other_rect)
      return contains?(other_rect.x, other_rect.y) || contains?(other_rect.x2, other_rect.y2) || 
                contains?(other_rect.x, other_rect.y2) || contains?(other_rect.x2, other_rect.y) ||
                other_rect.contains?(x, y) || other_rect.contains?(x2, y2) || 
                other_rect.contains?(x, y2) || other_rect.contains?(x2, y)
    end 
    
    def bounding_box(other_rect)
      #new rect with bounding box of these two
      new_x1 = [x, other_rect.x].min
      new_y1 = [x, other_rect.y].min
      new_x2 = [x2, other_rect.x2].max
      new_y2 = [y2, other_rect.y2].max
      new_width = (new_x2 - new_x1).abs
      new_height = (new_y2 - new_y1).abs
      Rectangle.new_by_x_y_dims(new_x1, new_y1, new_width, new_height)
    end
  end
end