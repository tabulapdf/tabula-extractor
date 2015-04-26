# -*- coding: utf-8 -*-
java_import org.apache.pdfbox.pdmodel.PDDocument
java_import org.apache.pdfbox.pdmodel.encryption.StandardDecryptionMaterial

module Tabula
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
