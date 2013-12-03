module Tabula

  #cells are components of spreadsheets

  class Cell < ZoneEntity
    attr_accessor :text_elements, :placeholder, :merged

    def initialize(top, left, width, height)
      super(top, left, width, height)
      @placeholder = false
      @merged = false
      @text_elements = []
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
      text_elements.each do |el|
        #output << " " if !output[-1].nil? && output[-1] != " " && el.text[0] != " "
        output << el.text
      end
      if output.empty? && debug
        output = "width: #{width} h: #{height}"
      end
      output
    end
  end
end
