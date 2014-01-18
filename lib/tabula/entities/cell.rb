module Tabula

  #cells are components of spreadsheets

  class Cell < ZoneEntity

    NORMAL = 0
    DEBUG = 1
    SUPERDEBUG = 2

    attr_accessor :text_elements, :placeholder, :spanning, :options

    def initialize(top, left, width, height, options={})
      super(top, left, width, height)
      @placeholder = false
      @spanning = false
      @text_elements = []
      @options = ({:use_line_returns => false, :cell_debug => NORMAL}).merge options
    end

    def self.new_from_points(topleft, bottomright, options={})
      width = bottomright.x - topleft.x
      height = bottomright.y - topleft.y
      Cell.new(topleft.y, topleft.x, width, height, options)
    end

    def text(options={})
      return "placeholder" if @placeholder && @options[:cell_debug] >= DEBUG
      output = ""
      text_elements.sort #use the default sort for ZoneEntity
      text_elements.group_by(&:top).values.each do |row|
        output << row.map{|el| el.text}.join('') + (@options[:use_line_returns] ? "\n" : '')
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
