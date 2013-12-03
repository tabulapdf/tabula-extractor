require 'set'
java_import java.awt.Polygon
java_import java.awt.geom.Area

module Tabula

  module HasCells

    #implement Nurminen thesis algorithm
    def find_cells(horizontal_ruling_lines, vertical_ruling_lines)
      # All lines need to been sorted from up to down,
      # and left to right in ascending order

      cells = []

      # puts "h lines"
      # puts horizontal_ruling_lines.select{|l| l.left <= 56.0 }
      # puts ""

      intersection_points = Ruling.find_intersections(horizontal_ruling_lines, vertical_ruling_lines)

      # All crossing-points have been sorted from up to down,
      # and left to right in ascending order
      # depending on the Point2D default sort here.
      intersection_points_array = intersection_points.keys.sort

      intersection_points.each_with_index do |(topLeft, ((horizontal, vertical))), i|
        # Fetch all points on the same vertical and horizontal
        # line with current crossing point

        # this lets us go to the next intersection_point in intersection_points_array
        # it is bad and I feel bad.
        catch :cellCreated do

          # CrossingPointsDirectlyBelow( topLeft );
          x_points = intersection_points_array[i..-1].select{|pt| pt.x == topLeft.x && pt.y > topLeft.y }
          # CrossingPointsDirectlyToTheRight( topLeft );
          y_points = intersection_points_array[i..-1].select{|pt| pt.y == topLeft.y && pt.x > topLeft.x }


          x_points.each do |x_point|
            #                                Skip to next crossing-point
            # if( NOT EdgeExistsBetween( topLeft, x_point)) next crossing-
            #                                                    point;
            next unless vertical.colinear?(x_point)
            y_points.each do |y_point|

              # if( NOT EdgeExistsBetween( topLeft, y_point)) next crossing-
              #                                                    point;
              next unless horizontal.colinear?(y_point)

              #Hypothetical bottom right point of rectangle
              btmRight = Point2D::Float.new( y_point.x, x_point.y )
              if intersection_points.include?(btmRight)
                intersection_points[btmRight].each do |btmRightHorizontal, btmRightVertical|
                  if btmRightHorizontal.colinear?( x_point ) &&
                    btmRightVertical.colinear?( y_point )
                    # Rectangle is confirmed to have 4 sides
                    cells << Cell.new_from_points( topLeft, btmRight)
                    # Each crossing point can be the top left corner
                    # of only a single rectangle
                    #next crossing-point; #Jeremy asks: we need to "next" out of the outer loop here
                       # to avoid creating non-minimal cells, I htink.
                    throw :cellCreated
                  end
                end
              end
            end
          end
        end #cellCreated
      end
      cells
    end


    # def find_cells_inefficiently!(horizontal_ruling_lines, vertical_ruling_lines)
    #   cells = []
    #   vertical_ruling_lines.each_with_index do |left_ruling, i|
    #     next if left_ruling.left == vertical_ruling_lines.last.left #skip the rightmost rulings (since they're no cell's left boundary)
    #     prev_top_ruling = nil
    #     horizontal_ruling_lines.each_with_index do |top_ruling, j|

    #       next if top_ruling.top == horizontal_ruling_lines.last.top  #skip the bottommost rulings (since they're no cell's top boundary)
    #       next unless top_ruling.nearlyIntersects?(left_ruling)

    #       #find the vertical line with (a) a left strictly greater than left_ruling's
    #       #                            (b) a top non-strictly smaller than top_ruling's
    #       #                            (c) the lowest left of all other vertical rulings that fit (a) and (b).
    #       #                            (d) if married and filing jointly, the subtract $6,100 (standard deduction) and amount from line 32 (adjusted gross income)
    #       candidate_right_rulings = vertical_ruling_lines[i+1..-1].select{|l| l.left > left_ruling.left } # (a)
    #       candidate_right_rulings.select!{|l| l.nearlyIntersects?(top_ruling) && l.bottom > top_ruling.top} #TODO make a better intersection function to check for this.
    #       if candidate_right_rulings.empty?
    #         # TODO: why does THIS ever happen?
    #         # Oh, presumably because there's a broken line at the end?
    #         # (But that doesn't make sense either.)
    #         next
    #       end
    #       right_ruling = candidate_right_rulings.sort_by{|l| l.left }[0] # (c)

    #       #random debug crap
    #       # if left_ruling.left == vertical_uniq_locs[0] && top_ruling.top == horizontal_uniq_locs[0]
    #       #   candidate_right_rulings = vertical_ruling_lines[i+1..-1].select{|l| l.left > left_ruling.left }.select{|l| l.left == 142.0 }
    #       #   puts candidate_right_rulings.map{|l| [l.left, l.nearlyIntersects?(top_ruling), top_ruling, l]}.inspect #TODO make a better intersection function to check for this.
    #       # end

    #       #find the horizontal line with (a) intersections with left_ruling and right_ruling
    #       #                              (b) the lowest top that is strictly greater than top_ruling's
    #       candidate_bottom_rulings = horizontal_ruling_lines[j+1..-1].select{|l| l.top > top_ruling.top }
    #       candidate_bottom_rulings.select!{|l| l.nearlyIntersects?(right_ruling) && l.nearlyIntersects?(left_ruling)}
    #       if candidate_bottom_rulings.empty?
    #         next
    #       end
    #       bottom_ruling = candidate_bottom_rulings.sort_by{|l| l.top }[0]

    #       cell_left = left_ruling.left
    #       cell_top = top_ruling.top
    #       cell_width = right_ruling.right - cell_left
    #       cell_height = bottom_ruling.bottom - cell_top

    #       c = Cell.new(cell_top, cell_left, cell_width, cell_height)
    #       cells << c
    #     end
    #   end
    #   cells
    # end

    ##########################
    # Chapter 2, Merged Cells
    ##########################
    #if c is a "merged cell", that is
    #              if there are N>0 vertical lines strictly between this cell's left and right
    #insert N placeholder cells after it with zero size (but same top)
    def add_merged_cells!(cells, horizontal_ruling_lines, vertical_ruling_lines)
      vertical_uniq_locs = vertical_ruling_lines.map(&:left).uniq    #already sorted
      horizontal_uniq_locs = horizontal_ruling_lines.map(&:top).uniq #already sorted

      cells.each do |c|

        vertical_rulings_merged_over = vertical_uniq_locs.select{|l| l > c.left && l < c.right }
        horizontal_rulings_merged_over = horizontal_uniq_locs.select{|t| t > c.top && t < c.bottom }

        unless vertical_rulings_merged_over.empty?
          c.merged = true
          vertical_rulings_merged_over.each do |merged_over_line_loc|
            placeholder = Cell.new(c.top, merged_over_line_loc, 0, c.height)
            placeholder.placeholder = true
            cells << placeholder
          end
        end
        unless horizontal_rulings_merged_over.empty?
          c.merged = true
          horizontal_rulings_merged_over.each do |merged_over_line_loc|
            placeholder = Cell.new(merged_over_line_loc, c.left, c.width, 0)
            placeholder.placeholder = true
            cells << placeholder
          end
        end

        #if there's a merged cell that's been merged over both rows and columns, then it has "double placeholder" cells
        # e.g. -------------------
        #      | C |  C |  C | C |         (this is some pretty sweet ASCII art, eh?)
        #      |-----------------|
        #      | C |  C |  C | C |
        #      |-----------------|
        #      | C | MC    P | C |   where MC is the "merged cell" that holds all the text within its bounds
        #      |----    +    ----|         P is a "placeholder" cell with either zero width or zero height
        #      | C | P    DP | C |         DP is a "double placeholder" cell with zero width and zero height
        #      |----    +    ----|         C is an ordinary cell.
        #      | C | P    DP | C |
        #      |-----------------|

        unless (double_placeholders = vertical_rulings_merged_over.product(horizontal_rulings_merged_over)).empty?
          double_placeholders.each do |vert_merged_over, horiz_merged_over|
            placeholder = Cell.new(horiz_merged_over, vert_merged_over, 0, 0)
            placeholder.placeholder = true
            cells << placeholder
          end
        end
      end
    end

    #TODO:
    #returns array of Spreadsheet objects constructed (or spreadsheet_areas => cells)
    #maybe placeholders should be added after cells is split into spreadsheets
    def find_spreadsheets_from_cells(cells)
      cells.sort!

      # via http://stackoverflow.com/questions/13746284/merging-multiple-adjacent-rectangles-into-one-polygon

      points = Set.new
      cells.each do |cell|
        #TODO: keep track of cells for each point here for more efficiently keeping track of cells inside a polygon
        cell.points.each do |pt|
          if points.include?(pt) # Shared vertex, remove it.
            points.delete(pt)
          else
            points << pt
          end
        end
      end
      points = points.to_a

      #x first sort
      points_sort_x = points.sort{ |s, other| s.x_first_cmp(other) }
      points_sort_y = points.sort

      edges_h = {}
      edges_v = {}

      i = 0
      while i < points.size do
        curr_y = points_sort_y[i].y
        while i < points.size && points_sort_y[i].y == curr_y do
          edges_h[points_sort_y[i]] = points_sort_y[i + 1]
          edges_h[points_sort_y[i + 1]] = points_sort_y[i]
          i += 2
        end
      end

      i = 0
      while i < points.size do
        curr_x = points_sort_x[i].x
        while i < points.size && points_sort_x[i].x == curr_x do
          edges_v[points_sort_x[i]] = points_sort_x[i + 1]
          edges_v[points_sort_x[i + 1]] = points_sort_x[i]
          i += 2
        end
      end

      # Get all the polygons.
      polygons = []
      while !edges_h.empty?
        # We can start with any point.
        #TODO: should the polygon be represented just by an ordered array of points?
        polygon = [[edges_h.shift[0], :horiz]] #popitem removes and returns a random key-value pair
        loop do
          curr, e = polygon.last
          if e == :horiz
            next_vertex = edges_v.delete(curr)
            polygon << [next_vertex, :vert]
          else
            next_vertex = edges_h.delete(curr) #pop removes and returns the value at key `curr`
            polygon << [next_vertex, :horiz]
          end
          if polygon[-1] == polygon[0]
            # Closed polygon
            polygon.pop()
            break
          end
        end

        # Remove implementation-markers (:horiz and :vert) from the polygon.
        polygon.map!{|point, _| point}
        polygon.each do |vertex|
          edges_h.delete(vertex) if edges_h.include?(vertex)
          edges_v.delete(vertex) if edges_v.include?(vertex)
        end
        polygons << polygon
      end

      # for efficiency's sake, we maybe ought to use java Polygon objects internally
      # for flexibility, we don't.

      polygons.map do |polygon|
        xpoints = []
        ypoints = []
        polygon.each do |pt|
          xpoints << pt.x
          ypoints << pt.y
        end
        Area.new(Polygon.new(xpoints.to_java(Java::int), ypoints.to_java(Java::int), xpoints.size)) #lol jruby
      end
    end
  end
end
