module Tabula
  PDFBOX = 'pdfbox-app-2.0.0-SNAPSHOT.jar'
end

require File.join(File.dirname(__FILE__), '../target/', Tabula::PDFBOX)

require_relative './tabula/version'
require_relative './tabula/core_ext'
require_relative './tabula/entities'
require_relative './tabula/pdf_dump'
require_relative './tabula/pdf_line_extractor'
require_relative './tabula/table_extractor'
require_relative './tabula/writers'
require_relative './tabula/table_guesser'
require_relative './tabula/line_segment_detector'
require_relative './tabula/pdf_render'
require_relative './tabula/spreadsheet_extractor'
