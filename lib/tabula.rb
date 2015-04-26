require_relative '../target/tabula-extractor-0.7.4-SNAPSHOT-jar-with-dependencies.jar'
# java_import org.apache.pdfbox.pdmodel.PDDocument
# java_import org.apache.pdfbox.pdmodel.encryption.StandardDecryptionMaterial



# module Tabula
#   include_package Java::TechnologyTabula
#   include_package Java::TechnologyTabulaExtractors

#   def Tabula.extract_tables(pdf_path, specs, options={})
#     options = {
#       :password => '',
#       :detect_ruling_lines => true,
#       :vertical_rulings => [],
#       :extraction_method => "guess",
#     }.merge(options)


#     specs = specs.group_by { |s| s['page'] }
#     pages = specs.keys.sort

#     extractor = Extraction::ObjectExtractor.new(pdf_path,
#                                                 options[:password])

#     sea = Java::TechnologyTabulaExtractors.SpreadsheetExtractionAlgorithm.new
#     bea = Java::TechnologyTabulaExtractors.BasicExtractionAlgorithm.new

#     Enumerator.new do |y|
#       extractor.extract(pages.map { |p| p.to_java(:int) }).each do |page|
#         specs[page.getPageNumber].each do |spec|
#           if ["spreadsheet", "original"].include?(spec['extraction_method'])
#             use_spreadsheet_extraction_method = spec['extraction_method'] == "spreadsheet"
#           else
#             use_spreadsheet_extraction_method = sea.isTabular(page)
#           end

#           area = page.getArea(spec['y1'], spec['x1'], spec['y2'], spec['x2'])

#           table_extractor = use_spreadsheet_extraction_method ? sea : bea
#           table_extractor.extract(area).each { |table| y.yield table }
#         end
#       end
#       extractor.close!
#     end

#   end
# end


# java.util.logging.Logger.getLogger('org.apache.pdfbox').setLevel(java.util.logging.Level::OFF)

# require_relative './tabula/version'
# require_relative './tabula/core_ext'

# require_relative './tabula/entities'
# require_relative './tabula/extraction'
# require_relative './tabula/table_extractor'
# require_relative './tabula/writers'

# require_relative './tabula/table_extractor'


java_import org.apache.pdfbox.pdmodel.PDDocument
java_import org.apache.pdfbox.pdmodel.encryption.StandardDecryptionMaterial
java.util.logging.Logger.getLogger('org.apache.pdfbox').setLevel(java.util.logging.Level::OFF)

module Tabula
  include_package Java::TechnologyTabula
end

class Tabula::Table
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

  def Tabula.extract_tables(pdf_path, specs, options={})
    options = {
      :password => '',
      :detect_ruling_lines => true,
      :vertical_rulings => [],
      :extraction_method => "guess",
    }.merge(options)


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
      def initialize(pdf_filename, pages=[1], password='', options={})
        raise Errno::ENOENT unless File.exists?(pdf_filename)
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

module Java
  module TechnologyTabula
    class TextElement 
    end
    class Ruling
    end
    class Page
      def spreadsheets
        spreadsheetExtractor = ::Java::TechnologyTabulaExtractors.SpreadsheetExtractionAlgorithm.new
        spreadsheetExtractor.extract(self)
      end

      alias_method :get_cell_text, :get_text
    end
    class Table
    end
    class Cell
      alias_method :get_text_elements, :text
    end
  end
end