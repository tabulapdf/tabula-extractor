require 'csv'
require 'json'

module Tabula
  module Writers

    def Writers.CSV(lines, output=$stdout)
      lines.each { |l|
        output.write CSV.generate_line(l.map(&:text), row_sep: "\r\n")
      }
    end

    def Writers.JSON(lines, output=$stdout)
      output.write lines.to_json
    end

    def Writers.TSV(lines, output=$stdout)
      lines.each { |l|
        output.write(l.map(&:text).join("\t") + "\n")
      }
    end


    def Writers.HTML(lines, output=$stdout)
      raise "not implemented"
    end


  end
end
