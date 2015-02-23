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
end

class Rectangle2D
  SIMILARITY_DIVISOR = 20

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

  # Various ways that rectangles can overlap one another
  #------------------------------


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
