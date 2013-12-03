module Tabula
  class Page < ZoneEntity
    attr_reader :rotation, :number_one_indexed, :file_path

    def initialize(file_path, width, height, rotation, number, texts=[])
      super(0, 0, width, height)
      @rotation = rotation
      if number < 1
        raise ArgumentError, "Tabula::Page numbers are one-indexed; numbers < 1 are invalid."
      end
      @file_path = file_path
      @number_one_indexed = number
      self.texts = texts
      @ruling_lines = []
    end

    def number(indexing_base=:one_indexed)
      if indexing_base == :zero_indexed
        return @number_one_indexed - 1
      else
        return @number_one_indexed
      end
    end

    def ruling_lines(options={})
      if @ruling_lines.empty?
        @ruling_lines = get_ruling_lines(options)
      end
      @ruling_lines
    end

    #memoize the ruling lines, since getting them can hypothetically be expensive
    def get_ruling_lines(options={})
      options[:render_pdf] ||= false
      Tabula::Extraction::LineExtractor.lines_in_pdf_page(file_path, number(:zero_indexed), options)
    end

    ##
    # get text insidea area
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

    def ruling_lines(options={})
      if @ruling_lines.empty?
        @ruling_lines = get_ruling_lines(options)
      end
      @ruling_lines
    end

    #memoize the ruling lines, since getting them can hypothetically be expensive
    def get_ruling_lines(options={})
      options[:render_pdf] ||= false
      Tabula::Extraction::LineExtractor.lines_in_pdf_page(file_path, number(:zero_indexed), options)
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
