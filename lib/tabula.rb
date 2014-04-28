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

require_relative './tabula/entities'
require_relative './tabula/extraction'
require_relative './tabula/table_extractor'
require_relative './tabula/writers'

module Tabula
  autoload :LSD               , File.expand_path('tabula/line_segment_detector.rb', File.dirname(__FILE__))
  autoload :Render            , File.expand_path('tabula/pdf_render.rb', File.dirname(__FILE__))
end

require_relative './tabula/table_extractor'
