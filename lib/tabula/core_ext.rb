java_import java.awt.geom.Point2D
java_import java.awt.geom.Line2D
java_import java.awt.geom.Rectangle2D

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

  def sample_variance
    m = self.mean
    sum = self.inject(0) {|accum, i| accum + (i-m)**2 }
    sum/(self.length - 1).to_f
  end

  def standard_deviation
    return Math.sqrt(self.sample_variance)
  end

  def sorted?
    each_cons(2).all? { |a, b| (a <=> b) <= 0 }
  end

end

class Point2D::Float
  def inspect
    toString
  end

  def to_json(*args)
    [self.getX, self.getY].to_json(*args)
  end
end

class Line2D::Float
  def to_json(*args)
    [self.getX1, self.getY1, self.getX2, self.getY2].to_json(*args)
  end

  def inspect
    "<Line2D::Float[(#{self.getX1},#{self.getY1}),(#{self.getX2},#{self.getY2})]>"
  end

  def rotate!(pointX, pointY, amount)
    px1 = self.getX1 - pointX; px2 = self.getX2 - pointX
    py1 = self.getY1 - pointY; py2 = self.getY2 - pointY

    if amount == 90 || amount == -270
      setLine(pointX - py2, pointY + px1,
              pointX - py1, pointY + px2)
    elsif amount == 270 || amount == -90
      setLine(pointX + py1, pointY - px2,
              pointX + py2, pointY - px1)

    end

  end

  def transform!(affine_transform)
    newP1, newP2 = Point2D::Float.new, Point2D::Float.new
    affine_transform.transform(self.getP1, newP1)
    affine_transform.transform(self.getP2, newP2)
    setLine(newP1, newP2)
    self
  end

  def snap!(cell_size)
    newP1, newP2 = Point2D::Float.new, Point2D::Float.new
    newP1.setLocation((self.getX1 / cell_size).round * cell_size,
                      (self.getY1 / cell_size).round * cell_size)
    newP2.setLocation((self.getX2 / cell_size).round * cell_size,
                      (self.getY2 / cell_size).round * cell_size)
    setLine(newP1, newP2)
  end

  def horizontal?(threshold=0.00001)
    (self.getY2 - self.getY1).abs < threshold
  end

  def vertical?(threshold=0.00001)
    (self.getX2 - self.getX1).abs < threshold
  end

end

class Rectangle2D::Float
  SIMILARITY_DIVISOR = 20

  alias_method :top, :minY
  alias_method :right, :maxX
  alias_method :left, :minX
  alias_method :bottom, :maxY


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
    self.java_send :setRect, [Java::float, Java::float, Java::float, Java::float,], self.x, new_y, self.width, self.height
  end

  def left=(new_x)
    self.java_send :setRect, [Java::float, Java::float, Java::float, Java::float,], new_x, self.y, self.width, self.height
  end

  def bottom=(new_y2)
    self.java_send :setRect, [Java::float, Java::float, Java::float, Java::float,], self.x, self.y, self.width, new_y2 - self.y
  end

  def right=(new_x2)
    self.java_send :setRect, [Java::float, Java::float, Java::float, Java::float,], self.x, self.y, new_x2 - self.x, self.height
  end

  def area
    self.width * self.height
  end

  # [x, y]
  def midpoint
    [self.left + (self.width / 2), self.top + (self.height / 2)]
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
    if [other.top, self.top, other.bottom, self.bottom].sorted?
      (other.bottom - self.top) / delta
    elsif [self.top, other.top, self.bottom, other.bottom].sorted?
      (self.bottom - other.top) / delta
    elsif [self.top, other.top, other.bottom, self.bottom].sorted?
      (other.bottom - other.top) / delta
    elsif [other.top, self.top, self.bottom, other.bottom].sorted?
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
