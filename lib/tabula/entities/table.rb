java_import org.nerdpower.tabula.Table


class Table
  # include Tabula::Tabular
  # attr_reader :extraction_method

  # def cols
  #   rows.transpose
  # end

  # create a new Table object from an array of arrays, representing a list of rows in a spreadsheet
  # probably only used for testing
  def self.new_from_array(array_of_rows)
    t = Table.new
    @extraction_method = "testing"
    tlines = []
    array_of_rows.each_with_index do |row, i|
      l = Line.new
      l.text_elements = row.each_with_index.map { |cell, j|
        TextElement.new(i.to_java(:float), j.to_java(:float), 1, 1, nil, 0, cell, 0)
      }
      tlines << l
    end
    t.instance_variable_set(:@lines, tlines)
#    t.send(:rpad!)
    t
  end


  #used for testing, ignores separator locations (they'll sometimes be nil/empty)
  # def ==(other)
  #   self.instance_variable_set(:@lines, self.lstrip_lines)
  #   other.instance_variable_set(:@lines, other.lstrip_lines)
  #   self.instance_variable_set(:@lines, self.lines.rpad(Line.new, other.lines.size))
  #   other.instance_variable_set(:@lines, other.lines.rpad(Line.new, self.lines.size))

  #   self.rows.zip(other.rows).all? { |my, yours| my == yours }
  # end

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
  # def rpad!
  #   max = lines.map{|l| l.text_elements.size}.max
  #   lines.each do |line|
  #     needed = max - line.text_elements.size
  #     needed.times do
  #       line.text_elements << TextElement::EMPTY # TextElement.new(nil, nil, nil, nil, nil, nil, '', nil)
  #     end
  #   end
  # end

  #for equality testing, return @lines stripped of leading columns of empty strings
  #TODO: write a method to strip all totally-empty columns (or not?)
  def lstrip_lines
    min_leading_empty_strings = ::Float::INFINITY
    lines.each do |line|
      empties = line.text_elements.map{|t| t.nil? || t.text.empty? }
      min_leading_empty_strings = [min_leading_empty_strings,
                                   empties.index(false) || 0].min
    end
    if min_leading_empty_strings == 0
      lines
    else
      (0...lines.size).each do |i|
        lines[i].text_elements.removeRange(0, min_leading_empty_strings)
      end
      lines
    end
  end
  def lstrip_lines!
    #@lines = self.lstrip_lines
    lstrip_lines
  end

  attr_accessor :lines

end


module Tabula
  Table = ::Table
end
