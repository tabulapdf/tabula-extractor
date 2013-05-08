require 'csv'

module Tabula
  module Writers

    def Writers.CSV(lines, output=$stdout)
      lines.each { |l|
        output.write CSV.generate_line(l.map(&:text), row_sep: "\r\n")
      }
    end

    def Writers.TSV(lines, output=$stdout)
      raise "not implemented"
    end

    def Writers.JSON(lines, output=$stdout)
      raise "not implemented"
    end

    def Writers.HTML(lines, output=$stdout)
      raise "not implemented"
    end

  end
end
