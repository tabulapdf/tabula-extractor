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

class java.awt.geom.Line2D::Float
  def to_json(*args)
    [self.getX1, self.getY1, self.getX2, self.getY2].to_json(*args)
  end

  def transform!(affine_transform)
    newP1, newP2 = java.awt.geom.Point2D::Float.new, java.awt.geom.Point2D::Float.new
    affine_transform.transform(self.getP1, newP1)
    affine_transform.transform(self.getP2, newP2)
    setLine(newP1, newP2)
    self
  end

  def snap!(cell_size)
    newP1, newP2 = java.awt.geom.Point2D::Float.new, java.awt.geom.Point2D::Float.new
    newP1.setLocation((self.getX1 / cell_size).round * cell_size,
                      (self.getY1 / cell_size).round * cell_size)
    newP2.setLocation((self.getX2 / cell_size).round * cell_size,
                      (self.getY2 / cell_size).round * cell_size)
    setLine(newP1, newP2)
  end

  def horizontal?(threshold=0.00001)
    (self.getY2 - self.getY2).abs < threshold
  end

  def vertical?(threshold=0.00001)
    (self.getX2 - self.getX1).abs < threshold
  end

end
