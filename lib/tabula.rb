module Tabula
  #  PDFBOX = 'pdfbox-app-1.8.0.jar'
  PDFBOX = 'pdfbox-app-2.0.0-SNAPSHOT.jar'
end

require_relative './tabula/version'
require_relative './tabula/entities'
require_relative './tabula/pdf_dump'
require_relative './tabula/table_extractor'
require_relative './tabula/writers'
