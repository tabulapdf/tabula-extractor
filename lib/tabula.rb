require File.join(File.dirname(__FILE__),
                  '..',
                  'target',
                  'tabula-0.8.0-jar-with-dependencies.jar')

java.util.logging.Logger.getLogger('org.apache.pdfbox').setLevel(java.util.logging.Level::OFF)

require_relative './tabula/version'
require_relative './tabula/core_ext'

require_relative './tabula/entities'
require_relative './tabula/extraction'
require_relative './tabula/table_extractor'

require_relative './tabula/table_extractor'
