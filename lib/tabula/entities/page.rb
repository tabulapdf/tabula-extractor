module Tabula
  class Page < ZoneEntity
    include Tabula::HasCells

    attr_reader :rotation, :number_one_indexed, :file_path, :ruling_lines
    attr_accessor :cells, :horizontal_ruling_lines, :vertical_ruling_lines

    def initialize(file_path, width, height, rotation, number, texts=[], ruling_lines=[])
      super(0, 0, width, height)
      @rotation = rotation
      if number < 1
        raise ArgumentError, "Tabula::Page numbers are one-indexed; numbers < 1 are invalid."
      end
      @ruling_lines = ruling_lines
      @file_path = file_path
      @number_one_indexed = number
      self.texts = texts
      @cells = []
      @spreadsheets = nil
    end

    # returns the Spreadsheets; creating them if they're not memoized
    def spreadsheets(options={})
      unless @spreadsheets.nil?
        return @spreadsheets
      end
      get_ruling_lines!(options)
      self.find_cells!(options)

      spreadsheet_areas = find_spreadsheets_from_cells #literally, java.awt.geom.Area objects. lol sorry. polygons.

      #transform each spreadsheet area into a rectangle
      # and get the cells contained within it.
      spreadsheet_rectangle_areas = spreadsheet_areas.map{|a| a.getBounds } #getBounds2D is theoretically better, but returns a Rectangle2D.Double, which doesn't have our Ruby sugar on it.

      @spreadsheets = spreadsheet_rectangle_areas.map do |rect|
        spr = Spreadsheet.new(rect.y, rect.x,
                        rect.width, rect.height,
                        self,
                        #TODO: keep track of the cells, instead of getting them again inefficiently.
                        [],
                        vertical_ruling_lines.select{|vl| rect.intersectsLine(vl) },
                        horizontal_ruling_lines.select{|hl| rect.intersectsLine(hl) }
                        )
        spr.cells = @cells.select{|c| spr.overlaps?(c) }
        spr.add_merged_cells!
        spr
      end
      if options[:fill_in_cells]
        fill_in_cells!
      end

      spreadsheets
    end

    def fill_in_cells!(options={})
      spreadsheets(options).each do |spreadsheet|
        spreadsheet.cells.each do |cell|
          cell.text_elements = page.get_cell_text(cell)
          spreadsheet.cells_resolved = true
        end
      end
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
      if !@ruling_lines.nil?
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
      if area.nil?
        texts
      else
        texts.select do |t|
          area.contains(t)
        end
      end
    end

    def get_cell_text(area=nil)
      Tabula.merge_words(self.get_text(area))
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
