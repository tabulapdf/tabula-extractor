require 'set'
java_import java.awt.Polygon
java_import java.awt.geom.Area

module Tabula
  # subclasses must define cells, vertical_ruling_lines, horizontal_ruling_lines accessors; ruling_lines reader
  module HasCells

    ARBITRARY_MAGIC_HEURISTIC_NUMBER = 0.65

    def is_tabular?
      ratio = heuristic_ratio
      return ratio > ARBITRARY_MAGIC_HEURISTIC_NUMBER && ratio < (1 / ARBITRARY_MAGIC_HEURISTIC_NUMBER)
    end

    def heuristic_ratio
      #spreadsheet extraction
      spreadsheet = spreadsheets.first
      return Float::NAN if spreadsheet.nil?
      rows_defined_by_lines = spreadsheet.rows.size #rows filled in automatically
      columns_defined_by_lines = spreadsheet.cols.size

      table = self.get_table
      columns_defined_without_lines = table.cols.size
      rows_defined_without_lines = table.rows.size
      ((columns_defined_by_lines.to_f / columns_defined_without_lines) + (rows_defined_by_lines.to_f / rows_defined_without_lines)) / 2
    end

    # finds cells from the ruling lines on the page.
    # implements Nurminen thesis algorithm cf. https://github.com/jazzido/tabula-extractor/issues/16
    # subclasses must define cells, vertical_ruling_lines, horizontal_ruling_lines accessors
    def find_cells!(horizontal_ruling_lines, vertical_ruling_lines, options={})
      # All lines need to been sorted from up to down,
      # and left to right in ascending order

      cellsFound = []

      intersection_points = Ruling.find_intersections(horizontal_ruling_lines, vertical_ruling_lines)

      # All crossing-points have been sorted from up to down,
      # and left to right in ascending order
      # depending on the Point2D default sort here.
      intersection_points_array = intersection_points.keys.sort

      intersection_points_array.each_with_index do |topLeft, i|
        # Fetch all points on the same vertical and horizontal
        # line with current crossing point
        horizontal, vertical = intersection_points[topLeft]

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
              btmRight = Point2D::Float.new(y_point.x, x_point.y)
              if intersection_points.include?(btmRight)
                btmRightHorizontal, btmRightVertical = intersection_points[btmRight]

                if btmRightHorizontal.colinear?( x_point ) &&
                    btmRightVertical.colinear?( y_point )
                  # Rectangle is confirmed to have 4 sides
                  cellsFound << Cell.new_from_points( topLeft, btmRight, options)
                  # Each crossing point can be the top left corner
                  # of only a single rectangle
                  #next crossing-point; we need to "next" out of the outer loop here
                  # to avoid creating non-minimal cells, I htink.
                  throw :cellCreated
                end
              end
            end
          end
        end #cellCreated
      end
      self.cells = cellsFound
      cellsFound
    end

    #TODO:
    #returns array of Spreadsheet objects constructed (or spreadsheet_areas => cells)
    #maybe placeholders should be added after cells is split into spreadsheets
    def find_spreadsheets_from_cells
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
