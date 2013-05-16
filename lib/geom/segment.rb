#
# Cribbed shamelessly from Daniel Vartanov's [ruby-geometry](https://github.com/DanielVartanov/ruby-geometry/)
# MIT License (c) 2008 Daniel Vartanov, modifications (c) 2013 Jeremy B. Merrill
#


module Geometry
  include Math
  extend Math

  def Geometry.distance(point1, point2)
    hypot point1.x - point2.x, point1.y - point2.y
  end


  class Segment < Struct.new(:point1, :point2)
    def self.new_by_arrays(point1_coordinates, point2_coordinates)
      self.new(Point.new_by_array(point1_coordinates), 
               Point.new_by_array(point2_coordinates))
    end

    def scale!(scale_factor)
      self.point1.x = self.point1.x * scale_factor
      self.point1.y = self.point1.y * scale_factor
      self.point2.x = self.point2.x * scale_factor
      self.point2.y = self.point2.y * scale_factor
    end

    def vertical?
      point1.x == point2.x
    end

    def horizontal?
      point1.y == point2.y
    end

    def leftmost_endpoint
      ((point1.x <=> point2.x) == -1) ? point1 : point2
    end

    def rightmost_endpoint
      ((point1.x <=> point2.x) == 1) ? point1 : point2
    end

    def topmost_endpoint
      ((point1.y <=> point2.y) == 1) ? point1 : point2
    end

    def bottommost_endpoint
      ((point1.y <=> point2.y) == -1) ? point1 : point2
    end

    def top
      topmost_endpoint.y
    end

    def bottom
      bottommost_endpoint.y
    end
    def width
      (left - right).abs
    end
    def height
      (bottom - top).abs
    end

    def left
      leftmost_endpoint.x
    end

    def right
      rightmost_endpoint.x
    end
    def length      
      Geometry.distance(point1, point2)
    end
  end
end

def Segment(point1, point2)
  Geometry::Segment.new point1, point2
end
