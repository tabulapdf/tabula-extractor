module Tabula
  class Table
    include Tabula::Tabular
    attr_reader :extraction_method

    def initialize(line_count, separators)
      @separators = separators
      @lines = (0...line_count).inject([]) { |m| m << Line.new }
      @extraction_method = "original"
    end

    def add_text_element(text_element, i, j)
      if @lines.size <= i
        @lines[i] = Line.new
      end
      @lines[i].add_text_chunk(j, text_element)
    end


    def cols
      rows.transpose
    end

    # TODO: this is awful, refactor
    def rows
      rpad!
      lstrip_lines!
      li = lines.map do |l|
        l.text_elements = l.text_elements.map do |te|
          te || TextElement::EMPTY
        end
      end.select do
        |l| !l.all? { |te| te.text.empty? }
      end.sort_by do |l|
        l.map { |te| te.top || 0 }.max
      end
    end

    # create a new Table object from an array of arrays, representing a list of rows in a spreadsheet
    # probably only used for testing
    def self.new_from_array(array_of_rows)
      t = Table.new(array_of_rows.size, [])
      @extraction_method = "testing"
      tlines = []
      array_of_rows.each_with_index do |row, index|
        l = Line.new
        l.text_elements = row.each_with_index.map { |cell, inner_index|
          TextElement.new(index.to_java(:float), inner_index.to_java(:float), 1, 1, nil, 0, cell, 0)
        }
        tlines << l
      end
      t.instance_variable_set(:@lines, tlines)
      t.send(:rpad!)
      t
    end


    #used for testing, ignores separator locations (they'll sometimes be nil/empty)
    def ==(other)
      self.instance_variable_set(:@lines, self.lstrip_lines)
      other.instance_variable_set(:@lines, other.lstrip_lines)
      self.instance_variable_set(:@lines, self.lines.rpad(Line.new, other.lines.size))
      other.instance_variable_set(:@lines, other.lines.rpad(Line.new, self.lines.size))

      self.rows.zip(other.rows).all? { |my, yours| my == yours }

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

    protected
    def rpad!
      max = lines.map{|l| l.text_elements.size}.max
      lines.each do |line|
        needed = max - line.text_elements.size
        needed.times do
          line.text_elements << TextElement::EMPTY # TextElement.new(nil, nil, nil, nil, nil, nil, '', nil)
        end
      end
    end

    #for equality testing, return @lines stripped of leading columns of empty strings
    #TODO: write a method to strip all totally-empty columns (or not?)
    def lstrip_lines
      min_leading_empty_strings = Float::INFINITY
      @lines.each do |line|
        empties = line.text_elements.map{|t| t.nil? || t.text.empty? }
        min_leading_empty_strings = [min_leading_empty_strings,
                                     empties.index(false) || 0].min
      end
      if min_leading_empty_strings == 0
        @lines
      else
        @lines.each{ |line|
          #line.text_elements = line.text_elements[min_leading_empty_strings..-1]
          line.text_elements.removeRange(0, min_leading_empty_strings)
        }
        @lines
      end
    end
    def lstrip_lines!
      @lines = self.lstrip_lines
    end

    attr_accessor :lines

  end
end
