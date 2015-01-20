require 'csv'
require 'json'

module Tabula
  module Writers

    def Writers.CSV(lines, output=$stdout)
      lines.each do |l|
        output.write CSV.generate_line(l.map(&:text), row_sep: "\r\n")
      end
    end

    def Writers.JSON(lines, output=$stdout)
      output.write lines.to_json
    end

    def Writers.TSV(lines, output=$stdout)
      lines.each do |l|
        output.write CSV.generate_line(l.map(&:text), col_sep: "\t", row_sep: "\r\n")
      end
    end
  end
end
