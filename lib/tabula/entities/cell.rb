module Tabula

  #cells are components of spreadsheets

  class Cell < ZoneEntity
    attr_accessor :text_elements, :placeholder, :merged, :options

    def initialize(top, left, width, height, options={})
      super(top, left, width, height)
      @placeholder = false
      @merged = false
      @text_elements = []
      @options = options #.merge({:use_line_returns => true})
    end

    def self.new_from_points(topleft, bottomright)
      width = bottomright.x - topleft.x
      height = bottomright.y - topleft.y
      Cell.new(topleft.y, topleft.x, width, height)
    end

    def text(debug=false)
      return "placeholder" if @placeholder && debug
      output = ""
      text_elements.sort #use the default sort for ZoneEntity
      text_elements.group_by(&:top).values.each do |row|
        output << row.map{|el| el.text}.join('') + (@options[:use_line_returns] ? "\n" : '')
      end
      if output.empty? && debug
        output = "top: #{top} left: #{left} \n w: #{width} h: #{height}"
      end
      output.strip
    end
  end
end
