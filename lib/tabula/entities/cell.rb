module Tabula
  Cell = Java::TechnologyTabula::Cell
  class Java::TechnologyTabula::Cell
    attr_accessor :options

    def text(use_line_returns=nil)
      java_send(:getText, [Java::boolean], use_line_returns.nil? ? (options.nil? || options[:use_line_returns].nil? ? true : options[:use_line_returns]) : use_line_returns)
    end
  end
end
