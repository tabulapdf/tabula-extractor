module Tabula
  class Table
    attr_reader :lines
    def initialize(line_count, separators)
      @separators = separators
      @lines = (0...line_count).inject([]) { |m| m << Line.new }
    end

    def add_text_element(text_element, i, j)
      if @lines.size <= i
        @lines[i] = Line.new
      end
      if @lines[i].text_elements[j]
        @lines[i].text_elements[j].merge!(text_element)
      else
        @lines[i].text_elements[j] = text_element
      end
    end

    # create a new Table object from an array of arrays, representing a list of rows in a spreadsheet
    # probably only used for testing
    def self.new_from_array(array_of_rows)
      t = Table.new(array_of_rows.size, [])
      array_of_rows.each_with_index do |row, index|
        t.lines[index].text_elements = row.map{|cell| TextElement.new(nil, nil, nil, nil, nil, nil, cell, nil)}
      end
      t
    end

    #for equality testing, return @lines stripped of leading columns of empty strings
    #TODO: write a method to strip all totally-empty columns (or not?)
    def lstrip_lines
      return @lines if @lines.include?(nil)
      min_leading_empty_strings = Float::INFINITY
      @lines.each do |line|
        empties = line.text_elements.map{|t| t.nil? || t.text.empty? }
        min_leading_empty_strings = [min_leading_empty_strings, empties.index(false)].min
      end
      if min_leading_empty_strings == 0
        @lines
      else
        @lines.each{|line| line.text_elements = line.text_elements[min_leading_empty_strings..-1]}
        @lines
      end
    end
    def lstrip_lines!
      @lines = self.lstrip_lines
    end

    #used for testing, ignores separator locations (they'll sometimes be nil/empty)
    def ==(other)
      self.instance_variable_set(:@lines, self.lstrip_lines)
      other.instance_variable_set(:@lines, other.lstrip_lines)
      self.instance_variable_set(:@lines, self.lines.rpad(nil, other.lines.size))
      other.instance_variable_set(:@lines, other.lines.rpad(nil, self.lines.size))

      self.lines.zip(other.lines).all? { |my, yours| my == yours }

    end
  end
end
