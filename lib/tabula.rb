module Tabula
  PDFBOX = 'pdfbox-app-2.0.0-SNAPSHOT.jar'
  ONLY_SPACES_RE = Regexp.new('^\s+$')
  SAME_CHAR_RE = Regexp.new('^(.)\1+$')
end

require File.join(File.dirname(__FILE__), '../target/', Tabula::PDFBOX)
require File.join(File.dirname(__FILE__), '../target/', 'slf4j-api-1.6.3.jar')
require File.join(File.dirname(__FILE__), '../target/', 'trove4j-3.0.3.jar')
require File.join(File.dirname(__FILE__), '../target/', 'jsi-1.1.0-SNAPSHOT.jar')

# java.util.logging.Logger.getLogger('org.apache.pdfbox').setLevel(java.util.logging.Level::OFF)

require_relative './tabula/version'
require_relative './tabula/core_ext'

require_relative './tabula/entities'
require_relative './tabula/extraction'
require_relative './tabula/table_extractor'
require_relative './tabula/writers'

require_relative './tabula/table_extractor'
