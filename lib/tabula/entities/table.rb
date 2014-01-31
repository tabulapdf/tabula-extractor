module Tabula
  class Table
    attr_reader :extraction_method
    attr_accessor :lines
    def initialize(line_count, separators)
      @separators = separators
      @lines = (0...line_count).inject([]) { |m| m << Line.new }
      @extraction_method = "original"
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

    def rpad!
      max = lines.map{|l| l.text_elements.size}.max
      lines.each do |line|
        needed = max - line.text_elements.size
        needed.times do
          line.text_elements << TextElement.new(nil, nil, nil, nil, nil, nil, '', nil)
        end
      end
    end

    def cols
      rows.transpose
    end

    def rows
      self.rpad!
      lines.map do |l|
        l.text_elements.map! do |te|
          te || TextElement.new(nil, nil, nil, nil, nil, nil, '', nil)
        end
      end.sort_by { |l| l.map { |te| te.top || 0 }.max }
    end

    # create a new Table object from an array of arrays, representing a list of rows in a spreadsheet
    # probably only used for testing
    def self.new_from_array(array_of_rows)
      t = Table.new(array_of_rows.size, [])
      @extraction_method = "testing"
      array_of_rows.each_with_index do |row, index|
        t.lines[index].text_elements = row.each_with_index.map{|cell, inner_index| TextElement.new(index, inner_index, 1, 1, nil, nil, cell, nil)}
      end
      t.rpad!
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

    def to_json(*a)
      {
        'json_class'   => self.class.name,
        'extraction_method' => @extraction_method,
        'vertical_separators' => @separators,
        'data' => rows,
      }.to_json(*a)
    end

    def to_csv
      out = StringIO.new
      Tabula::Writers.CSV(rows, out)
      out.string
    end

    def to_tsv
      out = StringIO.new
      Tabula::Writers.TSV(rows, out)
      out.string
    end
  end
end
