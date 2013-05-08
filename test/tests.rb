require 'minitest/autorun'

require_relative '../lib/tabula'

class TestDumper < MiniTest::Unit::TestCase

  def test_extractor
    extractor = Tabula::Extraction::CharacterExtractor.new(File.expand_path('data/gre.pdf', File.dirname(__FILE__)))
    page = extractor.extract.first
    assert_instance_of Tabula::Page, page
  end

  def test_get_by_area

#    http://localhost:8080/debug/418b1d5698e5c7b724551d9610c071ab3063275c/characters?x1=57.921428571428564&x2=290.7&y1=107.1&y2=394.52142857142854&page=1&use_lines=false
    extractor = Tabula::Extraction::CharacterExtractor.new(File.expand_path('data/gre.pdf', File.dirname(__FILE__)))
    characters = extractor.extract.first.get_text_by_area(107.1, 57.9214, 394.5214, 290.7)
    assert_equal characters.size, 206
  end
end

class TestExtractor < MiniTest::Unit::TestCase

  def test_table_extraction_1
    character_extractor = Tabula::Extraction::CharacterExtractor.new(File.expand_path('data/gre.pdf', File.dirname(__FILE__)))
    characters = character_extractor.extract.first.get_text_by_area(107.1, 57.9214, 394.5214, 290.7)
    table = Tabula.lines_to_csv(Tabula.make_table(characters))
    puts table
  end
end
