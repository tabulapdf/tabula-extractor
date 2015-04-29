require_relative '../target/tabula-extractor-0.7.4-SNAPSHOT-jar-with-dependencies.jar'
require_relative './tabula/core_ext'
java_import org.apache.pdfbox.pdmodel.PDDocument
java_import org.apache.pdfbox.pdmodel.encryption.StandardDecryptionMaterial
java.util.logging.Logger.getLogger('org.apache.pdfbox').setLevel(java.util.logging.Level::OFF)

module Tabula
  include_package Java::TechnologyTabula
end

class Java::TechnologyTabula::Table
  def to_csv
    sb = java.lang.StringBuilder.new
    Java::TechnologyTabulaWriters.CSVWriter.new.write(sb, self)
    sb.toString
  end

  def to_tsv
    sb = java.lang.StringBuilder.new
    Java::TechnologyTabulaWriters.TSVWriter.new.write(sb, self)
    sb.toString
  end

  def to_json(*a)
    sb = java.lang.StringBuilder.new
    Java::TechnologyTabulaWriters.JSONWriter.new.write(sb, self)
    sb.toString
  end
end
module Tabula
  include_package Java::TechnologyTabula
end

module Tabula

  def Tabula.extract_tables(pdf_path, specs, options={})
    options = {
      :password => '',
    }.merge(options)

    specs.each{|spec| spec.merge!( Hash[*options.map{|k,v| [k.to_s, v]}.flatten(1)] ) } #API backwards compatibility!

    specs = specs.group_by { |s| s['page'] }
    pages = specs.keys.sort

    extractor = Extraction::ObjectExtractor.new(pdf_path,
                                                options[:password])

    sea = Java::TechnologyTabulaExtractors.SpreadsheetExtractionAlgorithm.new
    bea = Java::TechnologyTabulaExtractors.BasicExtractionAlgorithm.new

    Enumerator.new do |y|
      extractor.extract(pages.map { |p| p.to_java(:int) }).each do |page|
        specs[page.getPageNumber].each do |spec|
          if ["spreadsheet", "original"].include?(spec['extraction_method'])
            use_spreadsheet_extraction_method = spec['extraction_method'] == "spreadsheet"
          else
            use_spreadsheet_extraction_method = sea.isTabular(page)
          end

          area = page.getArea(spec['y1'], spec['x1'], spec['y2'], spec['x2'])

          table_extractor = use_spreadsheet_extraction_method ? sea : bea
          table_extractor.extract(area).each { |table| y.yield table }
        end
      end
      extractor.close!
    end

  end

  # Deprecated. You shouldn't use this.
  def Tabula.extract_table(pdf_path, page, area, options={})
    options = {
      :password => '',
      :detect_ruling_lines => true,
      :vertical_rulings => [],
      :extraction_method => "guess",
    }.merge(options)
    # puts "Tabula.extract_table is deprecated. "
    raise ArgumentError, "page must be an integer for Tabula#extract_table; is a #{page.class}" unless page.is_a?(Fixnum)
    specs = [
      {"page"=> page, 
        'y1' => area.instance_of?(Array) ? area.shift : area.y1,
        'x1' => area.instance_of?(Array) ? area.shift : area.x1,
        'y2' => area.instance_of?(Array) ? area.shift : area.y2,
        'x2' => area.instance_of?(Array) ? area.shift : area.x2
      }]
    specs.each{|spec| spec.merge!( Hash[*options.map{|k,v| [k.to_s, v]}.flatten(1)] ) } #API backwards compatibility!
    Tabula.extract_tables(pdf_path, specs, options).first
  end


  module Extraction

    def Extraction.openPDF(pdf_filename, password='')
      raise Errno::ENOENT unless File.exists?(pdf_filename)
      document = PDDocument.load(pdf_filename)
      #document = PDDocument.loadNonSeq(java.io.File.new(pdf_filename), nil, password)
      document
    end

    class ObjectExtractor < Java::TechnologyTabula.ObjectExtractor

      alias_method :close!, :close

      # TODO: the +pages+ constructor argument does not make sense
      # now that we have +extract_page+ and +extract_pages+
      # positional arguments WERE pdf_filename, pages=nil, password='', options={}
      def initialize(pdf_filename, password='', options={}, deprecated=nil)
        raise Errno::ENOENT unless File.exists?(pdf_filename)
        if password.respond_to?(:each)
          puts "pages argument to ObjectExtractor#initialize IS DEPRECATED and HAS BEEN REMOVED."
          password = options.clone
          options = deprecated
        end
        @pdf_filename = pdf_filename
        document = Extraction.openPDF(pdf_filename, password)

        super(document)
      end
    end

    class PagesInfoExtractor < ObjectExtractor

      def pages
        Enumerator.new do |y|
          self.extract.each do |page|
            y.yield({
                      :width => page.getWidth,
                      :height => page.getHeight,
                      :number => page.getPageNumber,
                      :rotation => page.getRotation.to_i,
                      :hasText => page.hasText
                    })
            end
        end
      end
    end
  end
end

module Tabula
  include_package Java::TechnologyTabula
  import 'technology.tabula.Page'
  import 'technology.tabula.TextElement'
  import 'technology.tabula.TextChunk'
  import 'technology.tabula.Ruling'
  import 'technology.tabula.Table'
  import 'technology.tabula.TableWithRulingLines'
  import 'technology.tabula.Cell'
  import 'technology.tabula.Line'
  import 'technology.tabula.Rectangle'

end

module Tabula
  class TextElement
    EMPTY = TextElement.new(0,0,0,0,nil,0,'',0)
    def ==(other)
      self.text.strip == other.text.strip
    end
    def inspect
      "<TextElement '#{self.text.strip}' >"#[#{top}, #{left}, #{top + height}, #{left + width}]>"
    end
  end
  class TextChunk
    def ==(other)
      self.text.strip == other.text.strip
    end
    def inspect
      "<TextChunk '#{self.text.strip}' >"#[#{top}, #{left}, #{top + height}, #{left + width}]>"
    end
  end
  class Page
    alias_method :get_cell_text, :get_text
    alias_method :get_ruling_lines!, :getRulings
    alias_method :ruling_lines, :getRulings
    def spreadsheets
      spreadsheetExtractor = ::Java::TechnologyTabulaExtractors.SpreadsheetExtractionAlgorithm.new
      spreadsheetExtractor.extract(self)
    end
    def get_area(array)
      java_send :getArea, [::Java::float,::Java::float,::Java::float,::Java::float], *array
    end
    def get_text(array)
      java_send :getText, [::Java::float,::Java::float,::Java::float,::Java::float], *array
    end
    def is_tabular?
      spreadsheetExtractor = ::Java::TechnologyTabulaExtractors.SpreadsheetExtractionAlgorithm.new
      spreadsheetExtractor.isTabular(self)
    end
    def get_table(options={})
      extractor = ::Java::TechnologyTabulaExtractors.BasicExtractionAlgorithm.new
      extractor.extract(self, options[:vertical_rulings].nil? ? [] : options[:vertical_rulings].map{|r| r.x1.to_java(Java::float) } ).first
    end
    def make_table(options={})
      get_table(options).rows
    end
  end
  class Table
    def to_a
      rows.map{|row| row.map(&:getText) }
    end
  end
  class Cell
    field_accessor :textElements
    # def text()
    #   textChunk.nil? ? '' : textChunk.text
    # end

    def textChunk
      return @first unless @first.nil?
      cellTextChunks = textElements.to_a
      @first = cellTextChunks.shift
      cellTextChunks.each{|tc|  @first.merge(tc) }
      @first.nil? ? TextChunk.new(TextElement::EMPTY) : @first
    end

  end
  Spreadsheet = TableWithRulingLines

  class Cell
    alias_method :get_text_elements, :text
  end
end