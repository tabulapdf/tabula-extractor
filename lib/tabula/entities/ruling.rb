java_import org.nerdpower.tabula.Ruling

class Ruling
  def width
    right - left
  end

  def height
    bottom - top
  end

  # some PDFs (garment factory audits, precise link TK) make tables by drawing lines that
  # very nearly intersect each other, but not quite. E.g. a horizontal line spans the table at a Y val of 100
  # and each vertical line (i.e. column separating ruling line) starts at 101 or 102.
  # this is very annoying. so we check if those lines nearly overlap by expanding each pair
  # by 2 pixels in each direction (so the vertical lines' top becomes 99 or 100, and then the expanded versions overlap)

  PERPENDICULAR_PIXEL_EXPAND_AMOUNT = 2
  COLINEAR_OR_PARALLEL_PIXEL_EXPAND_AMOUNT = 1

  def to_json(arg)
    [left, top, right, bottom].to_json
  end

  def ==(other)
    return self.getX1 == other.getX1 && self.getY1 == other.getY1 && self.getX2 == other.getX2 && self.getY2 == other.getY2
  end

  class HSegmentComparator
    include java.util.Comparator
    def compare(o1, o2)
      o1.top <=> o2.top
    end
  end

  ##
  # log(n) implementation of find_intersections
  # based on http://people.csail.mit.edu/indyk/6.838-old/handouts/lec2.pdf
  def self.find_intersections(horizontals, verticals)
    tree = java.util.TreeMap.new(HSegmentComparator.new)
    sort_obj = Struct.new(:type, :pos, :obj)

    (horizontals + verticals)
      .flat_map { |r|
        r.vertical? ? sort_obj.new(:v, r.left, r) : [sort_obj.new(:hl, r.left, r),
                                                     sort_obj.new(:hr, r.right, r)]
      }
      .sort { |a,b|
        if a.pos == b.pos
          if a.type == :v && b.type == :hl
            1
          elsif a.type == :v && b.type == :hr
            -1
          elsif a.type == :hl && b.type == :v
            -1
          elsif a.type == :hr && b.type == :v
            1
          else
            a.pos <=> b.pos
          end
        else
          a.pos <=> b.pos
        end
      }
      .inject({}) { |memo, e|
        case e.type
          when :v
          tree.each { |h,_|
            i = h.intersection_point(e.obj)
            next memo if i.nil?
            memo[i] = [h.expand(PERPENDICULAR_PIXEL_EXPAND_AMOUNT),
                       e.obj.expand(PERPENDICULAR_PIXEL_EXPAND_AMOUNT)]
          }
          when :hr
            tree.remove(e.obj)
          when :hl
            tree[e.obj] = 1
        end
        memo
      }
  end

end

module Tabula
  Ruling = Ruling
end
