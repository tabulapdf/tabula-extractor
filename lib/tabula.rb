module Tabula
  PDFBOX = 'pdfbox-app-2.0.0-SNAPSHOT.jar'
  ONLY_SPACES_RE = Regexp.new('^\s+$')
  SAME_CHAR_RE = Regexp.new('^(.)\1+$')
end

require File.join(File.dirname(__FILE__), '../target/', Tabula::PDFBOX)
require File.join(File.dirname(__FILE__), '../target/', 'slf4j-api-1.6.3.jar')
require File.join(File.dirname(__FILE__), '../target/', 'trove4j-3.0.3.jar')
require File.join(File.dirname(__FILE__), '../target/', 'jsi-1.1.0-SNAPSHOT.jar')

import 'java.util.logging.LogManager'
import 'java.util.logging.Level'

lm = LogManager.log_manager
lm.logger_names.each do |name|
  if name == "" #rootlogger is apparently the logger PDFBox is talking to.
    l = lm.get_logger(name)
    l.level = Level::OFF
    l.handlers.each do |h|
      h.level = Level::OFF
    end
  end
end
require_relative './tabula/version'
require_relative './tabula/core_ext'

module Tabula
  # entities
  autoload :ZoneEntity        , File.expand_path('tabula/entities/zone_entity.rb', File.dirname(__FILE__))
  autoload :TextElement       , File.expand_path('tabula/entities/text_element.rb', File.dirname(__FILE__))
  autoload :TextChunk         , File.expand_path('tabula/entities/text_chunk.rb', File.dirname(__FILE__))
  autoload :Cell              , File.expand_path('tabula/entities/cell.rb', File.dirname(__FILE__))
  autoload :Line              , File.expand_path('tabula/entities/line.rb', File.dirname(__FILE__))
  autoload :Ruling            , File.expand_path('tabula/entities/ruling.rb', File.dirname(__FILE__))
  autoload :Page              , File.expand_path('tabula/entities/page.rb', File.dirname(__FILE__))
  autoload :PageArea          , File.expand_path('tabula/entities/page_area.rb', File.dirname(__FILE__))
  autoload :HasCells          , File.expand_path('tabula/entities/has_cells.rb', File.dirname(__FILE__))
  autoload :Spreadsheet       , File.expand_path('tabula/entities/spreadsheet.rb', File.dirname(__FILE__))
  autoload :Table             , File.expand_path('tabula/entities/table.rb', File.dirname(__FILE__))
  autoload :TextElementIndex  , File.expand_path('tabula/entities/text_element_index.rb', File.dirname(__FILE__))
  autoload :AbstractInterface , File.expand_path('tabula/entities/tabular.rb', File.dirname(__FILE__))
  autoload :Tabular           , File.expand_path('tabula/entities/tabular.rb', File.dirname(__FILE__))


  autoload :Extraction        , File.expand_path('tabula/extraction.rb', File.dirname(__FILE__))

  autoload :LSD               , File.expand_path('tabula/line_segment_detector.rb', File.dirname(__FILE__))

  autoload :Writers           , File.expand_path('tabula/writers.rb', File.dirname(__FILE__))

  autoload :Render            , File.expand_path('tabula/pdf_render.rb', File.dirname(__FILE__))
end

require_relative './tabula/table_extractor'
