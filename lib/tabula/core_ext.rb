java_import java.awt.geom.Point2D
java_import java.awt.geom.Line2D


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
