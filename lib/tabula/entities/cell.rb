module Tabula

  #cells are components of spreadsheets

  class Cell < org.nerdpower.tabula.Rectangle

    NORMAL = 0
    DEBUG = 1
    SUPERDEBUG = 2

    attr_accessor :text_elements, :placeholder, :spanning, :options

    def initialize(top, left, width, height, options={})
      super()
      self.java_send :setRect, [Java::float, Java::float, Java::float, Java::float], left, top, width, height
      @placeholder = false
      @spanning = false
      @text_elements = []
      @options = ({:use_line_returns => true, :cell_debug => NORMAL}).merge options
    end

    def text
      return "placeholder" if @placeholder && @options[:cell_debug] >= DEBUG
      output = ""
      text_elements.sort #use the default sort for ZoneEntity
      text_elements.group_by(&:top).values.each do |row|
        output << row.map{|el| el.text}.join('') + (@options[:use_line_returns] ? "\r" : '')
        # per @bchartoff, https://github.com/jazzido/tabula-extractor/pull/65#issuecomment-32899336
        # line returns as \r behave better in Excel.
      end
      if (output.empty? && @options[:cell_debug] >= DEBUG) || @options[:cell_debug] >= SUPERDEBUG
        text_output = output.dup
        output = "top: #{top} left: #{left} \n w: #{width} h: #{height}"
        output += " \n #{text_output}"
      end
      output.strip
    end

    def to_json(*a)
      {
        'json_class'   => self.class.name,
        'text' => text,
        'top' => top,
        'left' => left,
        'width' => width,
        'height' => height
      }.to_json(*a)
    end
  end
end
