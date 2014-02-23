module Tabula
  module AbstractInterface

    class InterfaceNotImplementedError < NoMethodError
    end

    def self.included(klass)
      klass.send(:include, AbstractInterface::Methods)
      klass.send(:extend, AbstractInterface::Methods)
    end

    module Methods
      def api_not_implemented(klass)
        caller.first.match(/in \`(.+)\'/)
        method_name = $1
        raise AbstractInterface::InterfaceNotImplementedError.new("#{klass.class.name} needs to implement '#{method_name}' for interface #{self.name}!")
      end
    end
  end


  module Tabular
    include AbstractInterface
    # this is a pseudo-interface as described here:
    # http://metabates.com/2011/02/07/building-interfaces-and-abstract-classes-in-ruby/
    # Table and Spreadsheet implement this interface, so should any class 
    # intended to represent tabular data from a PDF, e.g. if another extraction
    # method were created, so that Tabula GUI and API can correctly handle
    # its data.

    def extraction_method; raise Tabular.api_not_implemented(self); end 

    def page; Tabular.api_not_implemented(self); end 
    def rows; Tabular.api_not_implemented(self); end 
    def cols; Tabular.api_not_implemented(self); end 

    def to_csv; Tabular.api_not_implemented(self); end 
    def to_tsv; Tabular.api_not_implemented(self); end 
    def to_a; Tabular.api_not_implemented(self); end 
    def to_json; Tabular.api_not_implemented(self); end 
  end
end
