require 'csv'

module Tabula
  module Writers

    def Writers.CSV(lines, output=$stdout)
      CSV(output) { |csv|
        lines.each { |l|
          csv << l.map { |c| c.text }
        }
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
