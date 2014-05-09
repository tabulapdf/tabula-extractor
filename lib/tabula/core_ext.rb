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

  def top=(new_y)
    delta_height = new_y - self.y
    self.java_send :setRect, [Java::float, Java::float, Java::float, Java::float,], self.x, new_y, self.width, (self.height - delta_height)

    #used to be: (fixes test_vertical_rulings_splitting_words)
    # self.java_send :setRect, [Java::float, Java::float, Java::float, Java::float,], self.x, new_y, self.width, self.height
  end

  def bottom=(new_y2)
    self.java_send :setRect, [Java::float, Java::float, Java::float, Java::float,], self.x, self.y, self.width, new_y2 - self.y
  end

  def left=(new_x)
    delta_width = new_x - self.x
    self.java_send :setRect, [Java::float, Java::float, Java::float, Java::float,], new_x, self.y, (self.width - delta_width), self.height
    #used to be: (fixes test_vertical_rulings_splitting_words)
    # self.java_send :setRect, [Java::float, Java::float, Java::float, Java::float,], new_x, self.y, self.width, self.height
  end

  def right=(new_x2)
    self.java_send :setRect, [Java::float, Java::float, Java::float, Java::float,], self.x, self.y, new_x2 - self.x, self.height
  end

  def merge!(other)
    self.top    = [self.top, other.top].min
    self.left   = [self.left, other.left].min
    self.width  = [self.right, other.right].max - left
    self.height = [self.bottom, other.bottom].max - top

    self.java_send :setRect, [Java::float, Java::float, Java::float, Java::float,], self.left, self.top, self.width, self.height
    self
  end

  ##
  # default sorting order for ZoneEntity objects
  # is lexicographical (left to right, top to bottom)
  def <=>(other)
    yDifference = (self.bottom - other.bottom).abs
    if yDifference < 0.1 ||
       (other.bottom >= self.top && other.bottom <= self.bottom) ||
       (self.bottom >= other.top && self.bottom <= other.bottom)
      self.left <=> other.left
    else
      self.bottom <=> other.bottom
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

  def area
    self.width * self.height
  end

  # [x, y]
  def midpoint
    [horizontal_midpoint, vertical_midpoint]
  end

  def horizontal_midpoint
    self.left + (self.width / 2)
  end

  def vertical_midpoint
    self.top + (self.height / 2)
  end

  def horizontal_distance(other)
    (other.left - self.right).abs
  end

  def vertical_distance(other)
    (other.bottom - self.bottom).abs
  end


  # Various ways that rectangles can overlap one another
  #------------------------------

  # Roughly, detects if self and other belong to the same line
  def vertically_overlaps?(other)
    vertical_overlap = [0, [self.bottom, other.bottom].min - [self.top, other.top].max].max
    vertical_overlap > 0
  end

  # detects if self and other belong to the same column
  def horizontally_overlaps?(other)
    horizontal_overlap = [0, [self.right, other.right].min  - [self.left, other.left].max].max
    horizontal_overlap > 0
  end

  def overlaps?(other)
    self.intersects(*other.dims(:x, :y, :width, :height))
  end

  def overlaps_with_ratio?(other, ratio_tolerance=0.00001)
    self.overlap_ratio(other) > ratio_tolerance
  end

  def overlap_ratio(other)
    intersection_width = [0, [self.right, other.right].min  - [self.left, other.left].max].max
    intersection_height = [0, [self.bottom, other.bottom].min - [self.top, other.top].max].max
    intersection_area = [0, intersection_height * intersection_width].max

    union_area = self.area + other.area - intersection_area
    intersection_area / union_area
  end

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

  #used for "deduping" similar rectangles detected via CV.
  def similarity_hash
    [self.x.to_i / SIMILARITY_DIVISOR, self.y.to_i / SIMILARITY_DIVISOR, self.width.to_i / SIMILARITY_DIVISOR, self.height.to_i / SIMILARITY_DIVISOR].to_s
  end

  def self.unionize(non_overlapping_rectangles, next_rect)
    #if next_rect doesn't overlap any of non_overlapping_rectangles
    if !(overlapping = non_overlapping_rectangles.compact.select{|r| next_rect.overlaps? r}).empty? &&
       !non_overlapping_rectangles.empty?
      #remove all of those that it overlaps from non_overlapping_rectangles and
      non_overlapping_rectangles -= overlapping
      #add to non_overlapping_rectangles the bounding box of the overlapping rectangles.
      non_overlapping_rectangles << overlapping.inject(next_rect) do |memo, overlap|
        #all we're doing is unioning `overlap` and `memo` and setting that result to `memo`
        union(overlap, memo, memo) #I </3 Java.
        memo
      end
    else
      non_overlapping_rectangles << next_rect
    end
  end

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
