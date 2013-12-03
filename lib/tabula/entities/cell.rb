module Tabula

  #cells are components of spreadsheets

  class Cell < ZoneEntity
    attr_accessor :text_elements, :placeholder, :merged, :options

    def initialize(top, left, width, height)
      super(top, left, width, height)
      @placeholder = false
      @merged = false
      @text_elements = []
      @options = options
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
        #output << " " if !output[-1].nil? && output[-1] != " " && el.text[0] != " "
        output << row.map{|el| el.text}.join('') + (@options[:use_line_returns] ? "\n" : '')
      end
      if output.empty? && debug
        output = "width: #{width} h: #{height}"
      end
      output.strip
    end
  end
end
