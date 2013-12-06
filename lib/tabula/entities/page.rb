module Tabula
  class Page < ZoneEntity
    include Tabula::HasCells

    attr_reader :rotation, :number_one_indexed, :file_path, :ruling_lines
    attr_accessor :cells, :horizontal_ruling_lines, :vertical_ruling_lines

    def initialize(file_path, width, height, rotation, number, texts=[])
      super(0, 0, width, height)
      @rotation = rotation
      if number < 1
        raise ArgumentError, "Tabula::Page numbers are one-indexed; numbers < 1 are invalid."
      end
      @ruling_lines = nil
      @file_path = file_path
      @number_one_indexed = number
      self.texts = texts
      @cells = []
    end

    # returns the Spreadsheets
    # TODO: doesn't memoize, probably it should.
    def spreadsheets
      get_ruling_lines!
      self.find_cells!
      # add_merged_cells!(@cells, @vertical_ruling_lines,  @horizontal_ruling_lines)

      spreadsheet_areas = find_spreadsheets_from_cells #literally, java.awt.geom.Area objects. lol sorry. polygons.

      #e.g.
      # [
      #  [Point2D.Float[54.0, 24.0],
      #   Point2D.Float[54.0, 98.0],
      #   Point2D.Float[344.0, 98.0],
      #   Point2D.Float[344.0, 24.0]
      #  ],

      #  [Point2D.Float[154.0, 104.0],
      #   Point2D.Float[154.0, 110.0],
      #   Point2D.Float[54.0, 110.0],
      #   Point2D.Float[54.0, 572.0],
      #   Point2D.Float[930.0, 572.0],
      #   Point2D.Float[930.0, 104.0]
      #  ]
      # ]

      #transform each spreadsheet area into a rectangle
      # and get the cells contained within it.
      spreadsheet_rectangle_areas = spreadsheet_areas.map{|a| a.getBounds } #getBounds2D is theoretically better, but returns a Rectangle2D.Double, which doesn't have our Ruby sugar on it.

      actual_spreadsheets = spreadsheet_rectangle_areas.map do |rect|
        spr = Spreadsheet.new(rect.y, rect.x,
                        rect.width, rect.height,
                        #TODO: keep track of the cells, instead of getting them again inefficiently.
                        [],
                        vertical_ruling_lines.select{|vl| rect.intersectsLine(vl.to_line) },
                        horizontal_ruling_lines.select{|hl| rect.intersectsLine(hl.to_line) }
                        )
        spr.cells = @cells.select{|c| spr.overlaps?(c) }
        spr.add_merged_cells!
        spr
      end

      actual_spreadsheets
    end

    def number(indexing_base=:one_indexed)
      if indexing_base == :zero_indexed
        return @number_one_indexed - 1
      else
        return @number_one_indexed
      end
    end

    #returns ruling lines, memoizes them in
    def get_ruling_lines!(options={})
      if @ruling_lines.nil?
        options[:render_pdf] ||= false
        @ruling_lines = Tabula::Extraction::LineExtractor.lines_in_pdf_page(file_path, number(:zero_indexed), options)
        @vertical_ruling_lines = @ruling_lines.select(&:vertical?)
        @horizontal_ruling_lines = @ruling_lines.select(&:horizontal?)
      end
    end

    ##
    #get text insidea area
    # area can be an Array ([top, left, width, height])
    # or a Rectangle2D
    def get_text(area=nil)
      if area.instance_of?(Array)
        top, left, bottom, right = area
        area = Tabula::ZoneEntity.new(top, left,
                                      right - left, bottom - top)
      end
      area ||= self # if area not provided, use entire page
      texts.find_all { |t|
        area.contains(t)
      }
    end

    def get_cell_text(area=nil)
      area = Rectangle2D::Float.new(0, 0, width, height) if area.nil?
      # puts ""

      texts = self.texts.select do |t|
        # if t.top >= 76.0 && t.bottom <= 84
        #   puts [t.text, t.top, t.bottom].inspect
        # end
        t.vertical_midpoint.between?(area.top, area.bottom) &&
        #t.top >= area.top && t.vertical_midpoint <= area.bottom) && \
        t.horizontal_midpoint.between?(area.left, area.right)
        #t.horizontal_midpoint >= area.left && t.horizontal_midpoint <= area.right
      end
      texts = Tabula.merge_words(texts)
      # puts ""

      texts
    end


    def to_json(options={})
      { :width => self.width,
        :height => self.height,
        :number => self.number,
        :rotation => self.rotation,
        :texts => self.texts
      }.to_json(options)
    end



  end
end
