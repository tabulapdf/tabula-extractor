module Tabula
  class Cell < ZoneEntity
    attr_accessor :text_elements, :placeholder, :merged

    def initialize(top, left, width, height)
      super(top, left, width, height)
      @placeholder = false
      @merged = false
      @text_elements = []
    end

    def text(debug=false)
      return "placeholder" if @placeholder && debug
      output = ""
      text_elements.sort{|te1, te2| te1.top != te2.top ? te1.top <=> te2.top : te1.left <=> te2.left } #sort low to high, then tiebreak with left to right
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
