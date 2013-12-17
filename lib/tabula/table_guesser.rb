require 'json'

warn 'Tabula::TableGuesser is DEPRECATED and will be removed'

module Tabula
  module TableGuesser

    def TableGuesser.find_and_write_rects(filename, output_dir)
      #writes to JSON the rectangles on each page in the specified PDF.
      open(File.join(output_dir, "tables.json"), 'w') do |f|
        f.write( JSON.dump(find_rects(filename).map{|a| a.map{|r| r.dims.map(&:to_i) }} ))
      end
    end

    def TableGuesser.find_rects(filename)
      pdf = load_pdfbox_pdf(filename)

      if pdf.getNumberOfPages == 0
        puts "not a pdf!"
        exit
      end

      puts "pages: " + pdf.getNumberOfPages.to_s

      tables = []
      pdf.getNumberOfPages.times do |i|
        #gotcha: with PDFView, PDF pages are 1-indexed. If you ask for page 0 and then page 1, you'll get the first page twice. So start with index 1.
        tables << find_rects_on_page(pdf, i + 1)
      end
      tables
    end

    def TableGuesser.find_lines(filename)
      if pdf.getNumberOfPages == 0
        puts "not a pdf!"
        exit
      end

      puts "pages: " + pdf.getNumberOfPages.to_s

      lines = []
      pdf.getNumberOfPages.times do |i|
        lines << detect_lines_in_pdf_page(filename, i)
      end
      lines
    end

    def TableGuesser.find_lines_on_page(pdf, page_number_zero_indexed)
      Tabula::Extraction::LineExtractor.lines_in_pdf_page(pdf, page_number_zero_indexed, {:render_pdf => false})
    end

    def TableGuesser.find_rects_on_page(pdf, page_index)
      find_rects_from_lines(find_lines_on_page(pdf, page_index, 10))
    end

    def TableGuesser.find_rects_from_lines(lines)
      horizontal_lines = lines.select(&:horizontal?)
      vertical_lines = lines.select(&:vertical?)
      find_tables(vertical_lines, horizontal_lines).inject([]) do |memo, next_rect|
        java.awt.geom.Rectangle2D::Float.unionize( memo, next_rect )
      end.compact.reject{|r| r.area == 0 }.sort_by(&:area).reverse
    end


    def TableGuesser.euclidean_distance(x1, y1, x2, y2)
      return Math.sqrt( ((x1 - x2) ** 2) + ((y1 - y2) ** 2) )
    end

    def TableGuesser.is_upward_oriented(line, y_value)
      #return true if this line is oriented upwards, i.e. if the majority of it's length is above y_value.
      return (y_value - line.top > line.bottom - y_value);
    end

    def TableGuesser.find_tables(verticals, horizontals)
      #
      # Find all the rectangles in the vertical and horizontal lines given.
      #
      # Rectangles are deduped with hashRectangle, which considers two rectangles identical if each point rounds to the same tens place as the other.
      #
      # TODO: generalize this.
      #
      corner_proximity_threshold = 0.005;

      rectangles = []
      #find rectangles with one horizontal line and two vertical lines that end within $threshold to the ends of the horizontal line.

      [true, false].each do |up_or_down_lines|
        horizontals.each do |horizontal_line|
          horizontal_line_length = horizontal_line.length

          has_vertical_line_from_the_left = false
          left_vertical_line = nil
          #for the left vertical line.
          verticals.each do |vertical_line|
            #1. if it is correctly oriented (up or down) given the outer loop here. (We don't want a false-positive rectangle with one "arm" going down, and one going up.)
            next unless is_upward_oriented(vertical_line, horizontal_line.top) == up_or_down_lines

            vertical_line_length = vertical_line.length
            longer_line_length = [horizontal_line_length, vertical_line_length].max
            corner_proximity = corner_proximity_threshold * longer_line_length
            #make this the left vertical line:
            #2. if it begins near the left vertex of the horizontal line.
            if euclidean_distance(horizontal_line.left, horizontal_line.top, vertical_line.left, vertical_line.top) < corner_proximity ||
               euclidean_distance(horizontal_line.left, horizontal_line.top, vertical_line.left, vertical_line.bottom) < corner_proximity
              #3. if it is farther to the left of the line we already have.
              if left_vertical_line.nil? || left_vertical_line.left> vertical_line.left #is this line is more to the left than left_vertical_line. #"What's your opinion on Das Kapital?"
                has_vertical_line_from_the_left = true
                left_vertical_line = vertical_line
              end
            end
          end

          has_vertical_line_from_the_right = false;
          right_vertical_line = nil
          #for the right vertical line.
          verticals.each do |vertical_line|
            next unless is_upward_oriented(vertical_line, horizontal_line.top) == up_or_down_lines
            vertical_line_length = vertical_line.length
            longer_line_length = [horizontal_line_length, vertical_line_length].max
            corner_proximity = corner_proximity_threshold * longer_line_length
            if euclidean_distance(horizontal_line.right, horizontal_line.top, vertical_line.left, vertical_line.top) < corner_proximity ||
              euclidean_distance(horizontal_line.right, horizontal_line.top, vertical_line.left, vertical_line.bottom) < corner_proximity

              if right_vertical_line.nil? || right_vertical_line.right > vertical_line.right  #is this line is more to the right than right_vertical_line. #"Can you recite all of John Galt's speech?"
                #do two passes to guarantee we don't get a horizontal line with a upwards and downwards line coming from each of its corners.
                #i.e. ensuring that both "arms" of the rectangle have the same orientation (up or down).
                has_vertical_line_from_the_right = true
                right_vertical_line = vertical_line
              end
            end
          end

          if has_vertical_line_from_the_right && has_vertical_line_from_the_left
            #in case we eventually tolerate not-quite-vertical lines, this computers the distance in Y directly, rather than depending on the vertical lines' lengths.
            height = [left_vertical_line.bottom - left_vertical_line.top, right_vertical_line.bottom - right_vertical_line.top].max

            top = [left_vertical_line.top, right_vertical_line.top].min
            width = horizontal_line.right - horizontal_line.left
            left = horizontal_line.left
            r = java.awt.geom.Rectangle2D::Float.new( left, top, width, height ) #x, y, w, h
            #rectangles.put(hashRectangle(r), r); #TODO: I dont' think I need this now that I'm in Rubyland
            rectangles << r
          end
        end

        #find rectangles with one vertical line and two horizontal lines that end within $threshold to the ends of the vertical line.
        verticals.each do |vertical_line|
          vertical_line_length = vertical_line.length

          has_horizontal_line_from_the_top = false
          top_horizontal_line = nil
          #for the top horizontal line.
          horizontals.each do |horizontal_line|
            horizontal_line_length = horizontal_line.length
            longer_line_length = [horizontal_line_length, vertical_line_length].max
            corner_proximity = corner_proximity_threshold * longer_line_length

            if euclidean_distance(vertical_line.left, vertical_line.top, horizontal_line.left, horizontal_line.top) < corner_proximity ||
                euclidean_distance(vertical_line.left, vertical_line.top, horizontal_line.right, horizontal_line.top) < corner_proximity
                if top_horizontal_line.nil? || top_horizontal_line.top > horizontal_line.top #is this line is more to the top than the one we've got already.
                  has_horizontal_line_from_the_top = true;
                  top_horizontal_line = horizontal_line;
                end
            end
          end
          has_horizontal_line_from_the_bottom = false;
          bottom_horizontal_line = nil
          #for the bottom horizontal line.
          horizontals.each do |horizontal_line|
            horizontal_line_length = horizontal_line.length
            longer_line_length = [horizontal_line_length, vertical_line_length].max
            corner_proximity = corner_proximity_threshold * longer_line_length

            if euclidean_distance(vertical_line.left, vertical_line.bottom, horizontal_line.left, horizontal_line.top) < corner_proximity ||
              euclidean_distance(vertical_line.left, vertical_line.bottom, horizontal_line.left, horizontal_line.top) < corner_proximity
              if bottom_horizontal_line.nil? || bottom_horizontal_line.bottom > horizontal_line.bottom  #is this line is more to the bottom than the one we've got already.
                has_horizontal_line_from_the_bottom = true;
                bottom_horizontal_line = horizontal_line;
              end
            end
          end

          if has_horizontal_line_from_the_bottom && has_horizontal_line_from_the_top
            x = [top_horizontal_line.left, bottom_horizontal_line.left].min
            y = vertical_line.top
            width = [top_horizontal_line.right - top_horizontal_line.left, bottom_horizontal_line.right - bottom_horizontal_line.right].max
            height = vertical_line.bottom - vertical_line.top
            r = java.awt.geom.Rectangle2D::Float.new( x, y, width, height ) #x, y, w, h
            #rectangles.put(hashRectangle(r), r);
            rectangles << r
          end
        end
      end
      return rectangles.uniq &:similarity_hash
    end
  end
end
