java_import java.awt.geom.Point2D
java_import java.awt.geom.Line2D
java_import java.awt.geom.Rectangle2D
java_import java.awt.Rectangle


def debug_text_elements(text_elements)
  require 'csv'
  m = [:text, :top, :left, :bottom, :right, :width_of_space]
  CSV($stderr) { |csv|
    text_elements.each { |te|
      csv << m.map { |method|
        te.send(method)
      }
    }
  }
end


class Array
  def rpad(padding, target_size)
    if self.size < target_size
      self + [padding] * (target_size - self.size)
    else
      self
    end
  end
end


module Enumerable

  def sum
    self.inject(0){|accum, i| accum + i }
  end

  def mean
    self.sum/self.length.to_f
  end

end

class Point2D::Float
  def inspect
    toString
  end

  def to_json(*args)
    [self.getX, self.getY].to_json(*args)
  end

  def hash
    "#{self.getX},#{self.getY}".hash
  end

  def <=>(other)
    return  1 if self.y > other.y
    return -1 if self.y < other.y
    return  1 if self.x  > other.x
    return -1 if self.x  < other.x
    return  0
  end

  def x_first_cmp(other)
    return  1 if self.x  > other.x
    return -1 if self.x  < other.x
    return  1 if self.y > other.y
    return -1 if self.y < other.y
    return  0
  end

  def ==(other)
    return self.x == other.x && self.y == other.y
  end

end

class Line2D::Float
  def to_json(*args)
    [self.getX1, self.getY1, self.getX2, self.getY2].to_json(*args)
  end

  def inspect
    "<Line2D::Float[(#{self.getX1},#{self.getY1}),(#{self.getX2},#{self.getY2})]>"
  end
end

class Rectangle2D
  SIMILARITY_DIVISOR = 20

  alias_method :top, :minY
  alias_method :right, :maxX
  alias_method :left, :minX
  alias_method :bottom, :maxY

  def self.new_from_tlwh(top, left, width, height)
    r = self.new()
    r.java_send :setRect, [Java::float, Java::float, Java::float, Java::float], left, top, width, height
    r
  end

  # Implement geometry stuff
  #-------------------------

  def dims(*format)
    if format
      format.map{|method| self.send(method)}
    else
      [self.x, self.y, self.width, self.height]
    end
  end

  def to_json(options={})
    self.to_h.to_json
  end

  def tlbr
    [top, left, bottom, right]
  end

  def tlwh
    [top, left, width, height]
  end

  def points
    [ Point2D::Float.new(left, top),
      Point2D::Float.new(right, top),
      Point2D::Float.new(right, bottom),
      Point2D::Float.new(left, bottom) ]
  end

  # Various ways that rectangles can overlap one another
  #------------------------------

  # as defined by PDF-TREX paper
  def horizontal_overlap_ratio(other)
    delta = [self.bottom - self.top, other.bottom - other.top].min
    if other.top <= self.top && self.top <= other.bottom && other.bottom <= self.bottom
      (other.bottom - self.top) / delta
    elsif self.top <= other.top && other.top <= self.bottom && self.bottom <= other.bottom
      (self.bottom - other.top) / delta
    elsif self.top <= other.top && other.top <= other.bottom && other.bottom <= self.bottom
      (other.bottom - other.top) / delta
    elsif other.top <= self.top && self.top <= self.bottom && self.bottom <= other.bottom
      (self.bottom - self.top) / delta
    else
      0
    end
  end


  # Funky custom methods (i.e. not just geometry)
  #----------------------------------------------

  def to_h
    hash = {}
    [:top, :left, :width, :height].each do |m|
      hash[m] = self.send(m)
    end
    hash
  end

  def inspect
    "#<Rectangle2D dims:[#{top}, #{left}, #{bottom}, #{right}]>"
  end

end

# used only in GetBounds2D in an intermediate step in HasCells#find_spreadsheets_from_cells
class Rectangle #java.awt.Rectangle
  def inspect
    "#<Rectangle dims:[x:#{x}, y:#{y}, w:#{width}, h:#{height}]>"
  end
end
