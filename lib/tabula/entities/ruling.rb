module Tabula
  class Ruling < java.awt.geom.Line2D::Float

    attr_accessor :stroking_color

    def initialize(top, left, width, height, stroking_color=nil)
      super(left, top, left+width, top+height)
      self.stroking_color = stroking_color
    end

    alias :top :getY1
    alias :left :getX1
    alias :bottom :getY2
    alias :right :getX2

    def top=(v)
      self.java_send :setLine, [Java::float, Java::float, Java::float, Java::float,], left, v, right, bottom
    end

    def left=(v)
      self.java_send :setLine, [Java::float, Java::float, Java::float, Java::float,], v, top, right, bottom
    end

    def bottom=(v)
      self.java_send :setLine, [Java::float, Java::float, Java::float, Java::float,], left, top, right, v
    end

    def right=(v)
      self.java_send :setLine, [Java::float, Java::float, Java::float, Java::float,], left, top, v, bottom
    end

    def width
      right - left
    end

    def height
      bottom - top
    end

    # attributes that make sense only for non-oblique lines
    # these are used to have a single collapse method (in page, currently)

    ##
    # `x` (left) coordinate if line vertical, `y` (top) if horizontal
    def position
      raise NoMethodError, "Oblique line #{self.inspect} has no #position method." if oblique?
      vertical? ? left : top
    end
    def start
      raise NoMethodError, "Oblique line #{self.inspect} has no #start method." if oblique?
      vertical? ? top : left
    end
    def end
      raise NoMethodError, "Oblique line #{self.inspect} has no #end method." if oblique?
      vertical? ? bottom : right
    end
    def position=(coord)
      raise NoMethodError, "Oblique line #{self.inspect} has no #position= method." if oblique?
      if vertical?
        self.left = coord
        self.right = coord
      else
        self.top = coord
        self.bottom = coord
      end
    end
    def start=(coord)
      raise NoMethodError, "Oblique line #{self.inspect} has no #start= method." if oblique?
      if vertical?
        self.top = coord
      else
        self.left = coord
      end
    end
    def end=(coord)
      raise NoMethodError, "Oblique line #{self.inspect} has no #end= method." if oblique?
      if vertical?
        self.bottom = coord
      else
        self.right = coord
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
    # A total expansion amount of 2 is empirically verified to work sometimes. It's not a magic number from any
    # source other than a little bit of experience.)

    def nearlyIntersects?(another)
      if self.intersectsLine(another)
        true
      elsif self.perpendicular_to?(another)
        self.expand(PERPENDICULAR_PIXEL_EXPAND_AMOUNT).intersectsLine(another.expand(PERPENDICULAR_PIXEL_EXPAND_AMOUNT))
      else
        self.expand(COLINEAR_OR_PARALLEL_PIXEL_EXPAND_AMOUNT).intersectsLine(another.expand(COLINEAR_OR_PARALLEL_PIXEL_EXPAND_AMOUNT))
      end
    end

    ##
    # intersect this Ruling with a java.awt.geom.Rectangle2D
    def intersect(area)
      i = self.getBounds2D.createIntersection(area)
      self.java_send :setLine, [Java::float, Java::float, Java::float, Java::float,], i.getX, i.getY, i.getX + i.getWidth, i.getY + i.getHeight
      self
    end

    def expand(amt)
      raise NoMethodError, "Oblique line #{self.inspect} has no #expand method." if oblique?
      r = Ruling.new(self.top, self.left, self.width, self.height)
      r.start = r.start - amt
      r.end = r.end + amt
      r
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

    def oblique?
      !(vertical? || horizontal?)
    end

    def perpendicular_to?(other)
      return self.vertical? == other.horizontal?
    end

    def to_json(arg)
      [left, top, right, bottom].to_json
    end

    def colinear?(point)
      point.x >= left && point.x <= right &&
        point.y >= top && point.y <= bottom
    end

    def ==(other)
      return self.getX1 == other.getX1 && self.getY1 == other.getY1 && self.getX2 == other.getX2 && self.getY2 == other.getY2
    end

    ##
    # calculate the intersection point between +self+ and other Ruling
    def intersection_point(other)
      # algo taken from http://mathworld.wolfram.com/Line-LineIntersection.html

      #self and other should always be perpendicular, since one should be horizontal and one should be vertical
      self_l  = self.expand(PERPENDICULAR_PIXEL_EXPAND_AMOUNT)
      other_l = other.expand(PERPENDICULAR_PIXEL_EXPAND_AMOUNT)

      return nil if !self_l.intersectsLine(other_l)

      horizontal, vertical = if self_l.horizontal? && other_l.vertical?
                               [self_l, other]
                             elsif self_l.vertical? && other_l.horizontal?
                               [other_l, self_l]
                             else
                               raise ArgumentError, "must be orthogonal, horizontal and vertical"
                             end


      java.awt.geom.Point2D::Float.new(vertical.getX1, horizontal.getY1)

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
      construct_treemap_t_comparator = java.util.TreeMap.java_class.constructor(java.util.Comparator)
      tree = construct_treemap_t_comparator.new_instance(HSegmentComparator.new).to_java
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

    ##
    # crop an enumerable of +Ruling+ to an +area+
    def self.crop_rulings_to_area(rulings, area)
      rulings.reduce([]) do |memo, r|
        if r.intersects(area)
          memo << r.clone.intersect(area)
        end
        memo
      end
    end

    def self.collapse_oriented_rulings(lines)
      # lines must all be of one orientation (i.e. horizontal, vertical)

      if lines.empty?
        return []
      end

      lines.sort! {|a, b| a.position != b.position ? a.position <=> b.position : a.start <=> b.start }

      lines = lines.inject([lines.shift]) do |memo, next_line|
        last = memo.last

        # if current line colinear with next, and are "close enough": expand current line
        if next_line.position == last.position && last.nearlyIntersects?(next_line)
          memo.last.start = next_line.start < last.start ? next_line.start : last.start
          memo.last.end = next_line.end < last.end ? last.end : next_line.end
          memo
        # if next line has no length, ignore it
        elsif next_line.length == 0
          memo
        # otherwise, add it to the returned collection
        else
          memo << next_line
        end
      end
    end
  end
end
