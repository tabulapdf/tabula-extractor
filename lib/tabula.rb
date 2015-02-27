require File.join(File.dirname(__FILE__), '../java/target', 'tabula-extractor-0.7.4-SNAPSHOT-jar-with-dependencies.jar')

java.util.logging.Logger.getLogger('org.apache.pdfbox').setLevel(java.util.logging.Level::OFF)

require_relative './tabula/version'
require_relative './tabula/core_ext'

require_relative './tabula/entities'
require_relative './tabula/extraction'
require_relative './tabula/table_extractor'
require_relative './tabula/writers'

require_relative './tabula/table_extractor'
