module Tabula
  PDFBOX = 'pdfbox-app-2.0.0-SNAPSHOT.jar'
  ONLY_SPACES_RE = Regexp.new('^\s+$')
  SAME_CHAR_RE = Regexp.new('^(.)\1+$')
end

require File.join(File.dirname(__FILE__), '../ext/tabula/target', 'tabula-extractor-0.7.4-SNAPSHOT-jar-with-dependencies.jar')

import 'java.util.logging.Level'
import 'java.util.logging.Logger'

Logger.getLogger('org.apache.pdfbox').setLevel(Level::OFF)

require_relative './tabula/version'
require_relative './tabula/core_ext'

require_relative './tabula/entities'
require_relative './tabula/extraction'
require_relative './tabula/table_extractor'
require_relative './tabula/writers'

require_relative './tabula/table_extractor'
