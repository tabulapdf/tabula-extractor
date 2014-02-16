module Tabula
  module Tabular
    # this is a pseudo-interface as described here:
    # http://metabates.com/2011/02/07/building-interfaces-and-abstract-classes-in-ruby/
    # Table and Spreadsheet implement this interface, so should any class 
    # intended to represent tabular data from a PDF, e.g. if another extraction
    # method were created, so that Tabula GUI and API can correctly handle
    # its data.



    def extraction_method; raise InterfaceNotImplementedError; end 

    def page; raise InterfaceNotImplementedError; end 
    def rows; raise InterfaceNotImplementedError; end 
    def cols; raise InterfaceNotImplementedError; end 

    def to_csv; raise InterfaceNotImplementedError; end 
    def to_tsv; raise InterfaceNotImplementedError; end 
    def to_a; raise InterfaceNotImplementedError; end 
    def to_json; raise InterfaceNotImplementedError; end 

    class InterfaceNotImplementedError < NoMethodError
    end

  end
end