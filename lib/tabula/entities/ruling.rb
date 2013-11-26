module Tabula
  # TODO make it a heir of java.awt.geom.Line2D::Float
  class Ruling < ZoneEntity

    attr_accessor :stroking_color
    EXPANSION_COEFFICIENT = 0.01
    def initialize(top, left, width, height, stroking_color=nil)
      super(top, left, width, height)
      self.stroking_color = stroking_color
      normalize!
    end

    def normalize!
      # sometimes lines come out of LSD with top > bottom or left > right
      #this is, of course, nonsense, so here we fix it.
      if top > bottom
        bukkit = top
        self.top = bottom
        self.bottom = bukkit
      end
      if left > right
        bukkit = left
        self.left = right
        #right = wrong
        self.right = bukkit
      end
    end

    #ok wtf are you doing, Jeremy?
    # some PDFs (garment factory audits, precise link TK) make tables by drawing lines that
    # very nearly intersect each other, but not quite. E.g. a horizontal line spans the table at a Y val of 100
    # and each vertical line (i.e. column separating ruling line) starts at 101 or 102.
    # this is very annoying. so we check if those lines nearly overlap by expanding each pair
    # by 2 pixels in each direction (so the vertical lines' top becomes 99 or 100, and then the expanded versions overlap)

    PERPENDICULAR_PIXEL_EXPAND_AMOUNT = 2
    COLINEAR_OR_PARALLEL_PIXEL_EXPAND_AMOUNT = 1

    # if the lines we're comparing are colinear or parallel, we expand them by a only 1 pixel,
    # because the expansions are additive
    # (e.g. two vertical lines, at x = 100, with one having y2 of 98 and the other having y1 of 102 would
    # erroneously be said to nearlyIntersect if they were each expanded by 2 (since they'd both terminate at 100).
    # The COLINEAR_OR_PARALLEL_PIXEL_EXPAND_AMOUNT is only 1 so the total expansion is 2.
    # A total expansion amount of 2 is empirically verified to work sometime. It's not a magic number from any
    # source other than a little bit of experience.)

    def nearlyIntersects?(another)
      if self.to_line.intersectsLine(another.to_line)
        return true
      else
        if self.perpendicular_to?(another)
          result = self.expand(PERPENDICULAR_PIXEL_EXPAND_AMOUNT).to_line.intersectsLine(another.expand(PERPENDICULAR_PIXEL_EXPAND_AMOUNT).to_line)
        else
          result = self.expand(COLINEAR_OR_PARALLEL_PIXEL_EXPAND_AMOUNT).to_line.intersectsLine(another.expand(COLINEAR_OR_PARALLEL_PIXEL_EXPAND_AMOUNT).to_line)
        end
        return result
      end
    end

    def intersect(area)
      i = self.createIntersection(area)
      self.top    = i.top
      self.left   = i.left
      self.bottom = i.bottom
      self.right  = i.right
      self
    end

    def expand(amt)
      r = Ruling.new(self.top, self.left, self.width, self.height)
      if r.horizontal?
        r.left = r.left - amt
        r.right = (r.right + amt)
      elsif r.vertical?
        r.top = r.top - amt
        r.bottom = r.bottom + amt
      end
      r
    end

    #for comparisons, deprecate when this inherits from Line2D
    def to_line
      java.awt.geom.Line2D::Float.new(left, top, right, bottom)
    end

    def length
      Math.sqrt( (self.right - self.left).abs ** 2 + (self.bottom - self.top).abs ** 2 )
    end

    def vertical?
      left == right
    end

    def horizontal?
      top == bottom
    end

    def perpendicular_to?(other)
      return self.vertical? == other.horizontal?
    end

    def right
      left + width
    end

    def bottom
      top + height
    end

    def to_json(arg)
      [left, top, right, bottom].to_json
    end

    def intersection_point(other)
      # algo taken from http://mathworld.wolfram.com/Line-LineIntersection.html
      self_l  = self.to_line
      other_l = other.to_line

      return nil if !self_l.intersectsLine(other_l)

      x1 = self_l.getX1; y1 = self_l.getY1
      x2 = self_l.getX2; y2 = self_l.getY2
      x3 = other_l.getX1; y3 = other_l.getY1
      x4 = other_l.getX2; y4 = other_l.getY2

      det = lambda { |a,b,c,d| a * d - b * c }

      int_x = det.call(det.call(x1, y1, x2, y2), x1 - x2, det.call(x3, y3, x4, y4), x3 - x4) /
        det.call(x1 - x2, y1 - y2, x3 - x4, y3 - y4)

      int_y = det.call(det.call(x1, y1, x2, y2), y1 - y2,
                       det.call(x3, y3, x4, y4), y3 - y4) /
        det.call(x1 - x2, y1 - y2, x3 - x4, y3 - y4)

      return nil if int_x.nan? || int_y.nan? # TODO is this right?

      java.awt.geom.Point2D::Float.new(int_x, int_y)
    end

    # Find all intersection points between two list of +Ruling+
    # (+horizontals+ and +verticals+)
    # TODO: this is O(n^2) - optimize.
    def self.find_intersections(horizontals, verticals)
      horizontals.product(verticals).inject({}) { |memo, (h, v)|
        ip = h.intersection_point(v)
        unless ip.nil?
          memo[ip] ||= []
          memo[ip] << [h, v]
        end
        memo
      }
    end

    # crop an enumerable of +Ruling+ to an +area+
    def self.crop_rulings_to_area(rulings, area)
      rulings.reduce([]) do |memo, r|
        if r.to_line.intersects(area)
          i = r.createIntersection(area)
          memo << self.new(i.getY, i.getX, i.getWidth, i.getHeight)
        end
        memo
      end
    end

    def self.clean_rulings(rulings, max_distance=4)

      # merge horizontal and vertical lines
      # TODO this should be iterative

      skip = false

      horiz = rulings.select { |r| r.horizontal? }
        .group_by(&:top)
        .values.reduce([]) do |memo, rs|

        rs = rs.sort_by(&:left)
        if rs.size > 1
          memo +=
            rs.each_cons(2)
            .chunk { |p| p[1].left - p[0].right < 7 }
            .select { |c| c[0] }
            .map { |group|
            group = group.last.flatten.uniq
            Tabula::Ruling.new(group[0].top,
                               group[0].left,
                               group[-1].right - group[0].left,
                               0)
          }
          Tabula::Ruling.new(rs[0].top, rs[0].left, rs[-1].right - rs[0].left, 0)
        else
          memo << rs.first
        end
        memo
      end
        .sort_by(&:top)

      h = []
      horiz.size.times do |i|

        if i == horiz.size - 1
          h << horiz[-1]
          break
        end

        if skip
          skip = false;
          next
        end
        d = (horiz[i+1].top - horiz[i].top).abs

        h << if d < max_distance # THRESHOLD DISTANCE between horizontal lines
               skip = true
               Tabula::Ruling.new(horiz[i].top + d / 2, [horiz[i].left, horiz[i+1].left].min, [horiz[i+1].width.abs, horiz[i].width.abs].max, 0)
             else
               horiz[i]
             end
      end
      horiz = h

      vert = rulings.select { |r| r.vertical? }
        .group_by(&:left)
        .values
        .reduce([]) do |memo, rs|

        rs = rs.sort_by(&:top)

        if rs.size > 1
          # Here be dragons:
          # merge consecutive segments of lines that are close enough
          memo +=
            rs.each_cons(2)
            .chunk { |p| p[1].top - p[0].bottom < 7 }
            .select { |c| c[0] }
            .map { |group|
            group = group.last.flatten.uniq
            Tabula::Ruling.new(group[0].top,
                               group[0].left,
                               0,
                               group[-1].bottom - group[0].top)
          }
        else
          memo << rs.first
        end
        memo
      end.sort_by(&:left)

      return horiz += vert
    end
  end
end
