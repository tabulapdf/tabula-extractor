java_import org.nerdpower.tabula.Ruling

class Ruling

  # some PDFs (garment factory audits, precise link TK) make tables by drawing lines that
  # very nearly intersect each other, but not quite. E.g. a horizontal line spans the table at a Y val of 100
  # and each vertical line (i.e. column separating ruling line) starts at 101 or 102.
  # this is very annoying. so we check if those lines nearly overlap by expanding each pair
  # by 2 pixels in each direction (so the vertical lines' top becomes 99 or 100, and then the expanded versions overlap)

  def to_json(arg)
    [left, top, right, bottom].to_json
  end

  def ==(other)
    return self.getX1 == other.getX1 && self.getY1 == other.getY1 && self.getX2 == other.getX2 && self.getY2 == other.getY2
  end


end

module Tabula
  Ruling = Ruling
end
