# -*- coding: utf-8 -*-
require 'minitest'
require 'minitest/autorun'

require_relative '../lib/tabula'

def lines_to_array(lines)
  lines.map { |l|
    l.map { |te| te.text }
  }
end

class TestPagesInfoExtractor < Minitest::Test
  def test_pages_info_extractor
    extractor = Tabula::Extraction::PagesInfoExtractor.new(File.expand_path('data/gre.pdf', File.dirname(__FILE__)))

    i = 0
    extractor.pages.each do |page|
      assert_instance_of Tabula::Page, page      
      i += 1
    end
    assert_equal 2, i
  end
end

class TestTableGuesser < MiniTest::Unit::TestCase
end

class TestDumper < Minitest::Test

  def test_extractor
    extractor = Tabula::Extraction::CharacterExtractor.new(File.expand_path('data/gre.pdf', File.dirname(__FILE__)))
    page = extractor.extract.first
    assert_instance_of Tabula::Page, page
  end

  def test_get_by_area

#    http://localhost:8080/debug/418b1d5698e5c7b724551d9610c071ab3063275c/characters?x1=57.921428571428564&x2=290.7&y1=107.1&y2=394.52142857142854&page=1&use_lines=false
    extractor = Tabula::Extraction::CharacterExtractor.new(File.expand_path('data/gre.pdf', File.dirname(__FILE__)))
    characters = extractor.extract.next.get_text([107.1, 57.9214, 394.5214, 290.7])
    assert_equal characters.size, 206
  end
end

class TestExtractor < Minitest::Test

  def test_table_extraction_1
    character_extractor = Tabula::Extraction::CharacterExtractor.new(File.expand_path('data/gre.pdf', File.dirname(__FILE__)))
    characters = character_extractor.extract.next.get_text([107.1, 57.9214, 394.5214, 290.7])
    table = lines_to_array Tabula.make_table(characters)
    expected = [["Prior Scale ", "New Scale ", "% Rank* "], ["800 ", "170 ", "99 "], ["790 ", "170 ", "99 "], ["780 ", "170 ", "99 "], ["770 ", "170 ", "99 "], ["760 ", "170 ", "99 "], ["750 ", "169 ", "99 "], ["740 ", "169 ", "99 "], ["730 ", "168 ", "98 "], ["720 ", "168 ", "98 "], ["710 ", "167 ", "97 "], ["700 ", "166 ", "96 "], ["690 ", "165 ", "95 "], ["680 ", "165 ", "95 "], ["670 ", "164 ", "93 "], ["660 ", "164 ", "93 "], ["650 ", "163 ", "91 "]]
    assert_equal expected, table
  end

  def test_diputados_voting_record
    character_extractor = Tabula::Extraction::CharacterExtractor.new(File.expand_path('data/argentina_diputados_voting_record.pdf', File.dirname(__FILE__)))
    characters = character_extractor.extract.next.get_text([269.875, 12.75, 790.5, 561])

    expected = [["ABDALA de MATARAZZO, Norma Amanda", "Frente Cívico por Santiago", "Santiago del Estero", "AFIRMATIVO"], ["ALBRIEU, Oscar Edmundo Nicolas", "Frente para la Victoria - PJ", "Rio Negro", "AFIRMATIVO"], ["ALONSO, María Luz", "Frente para la Victoria - PJ", "La Pampa", "AFIRMATIVO"], ["ARENA, Celia Isabel", "Frente para la Victoria - PJ", "Santa Fe", "AFIRMATIVO"], ["ARREGUI, Andrés Roberto", "Frente para la Victoria - PJ", "Buenos Aires", "AFIRMATIVO"], ["AVOSCAN, Herman Horacio", "Frente para la Victoria - PJ", "Rio Negro", "AFIRMATIVO"], ["BALCEDO, María Ester", "Frente para la Victoria - PJ", "Buenos Aires", "AFIRMATIVO"], ["BARRANDEGUY, Raúl Enrique", "Frente para la Victoria - PJ", "Entre Ríos", "AFIRMATIVO"], ["BASTERRA, Luis Eugenio", "Frente para la Victoria - PJ", "Formosa", "AFIRMATIVO"], ["BEDANO, Nora Esther", "Frente para la Victoria - PJ", "Córdoba", "AFIRMATIVO"], ["BERNAL, María Eugenia", "Frente para la Victoria - PJ", "Jujuy", "AFIRMATIVO"], ["BERTONE, Rosana Andrea", "Frente para la Victoria - PJ", "Tierra del Fuego", "AFIRMATIVO"], ["BIANCHI, María del Carmen", "Frente para la Victoria - PJ", "Cdad. Aut. Bs. As.", "AFIRMATIVO"], ["BIDEGAIN, Gloria Mercedes", "Frente para la Victoria - PJ", "Buenos Aires", "AFIRMATIVO"], ["BRAWER, Mara", "Frente para la Victoria - PJ", "Cdad. Aut. Bs. As.", "AFIRMATIVO"], ["BRILLO, José Ricardo", "Movimiento Popular Neuquino", "Neuquén", "AFIRMATIVO"], ["BROMBERG, Isaac Benjamín", "Frente para la Victoria - PJ", "Tucumán", "AFIRMATIVO"], ["BRUE, Daniel Agustín", "Frente Cívico por Santiago", "Santiago del Estero", "AFIRMATIVO"], ["CALCAGNO, Eric", "Frente para la Victoria - PJ", "Buenos Aires", "AFIRMATIVO"], ["CARLOTTO, Remo Gerardo", "Frente para la Victoria - PJ", "Buenos Aires", "AFIRMATIVO"], ["CARMONA, Guillermo Ramón", "Frente para la Victoria - PJ", "Mendoza", "AFIRMATIVO"], ["CATALAN MAGNI, Julio César", "Frente para la Victoria - PJ", "Tierra del Fuego", "AFIRMATIVO"], ["CEJAS, Jorge Alberto", "Frente para la Victoria - PJ", "Rio Negro", "AFIRMATIVO"], ["CHIENO, María Elena", "Frente para la Victoria - PJ", "Corrientes", "AFIRMATIVO"], ["CIAMPINI, José Alberto", "Frente para la Victoria - PJ", "Neuquén", "AFIRMATIVO"], ["CIGOGNA, Luis Francisco Jorge", "Frente para la Victoria - PJ", "Buenos Aires", "AFIRMATIVO"], ["CLERI, Marcos", "Frente para la Victoria - PJ", "Santa Fe", "AFIRMATIVO"], ["COMELLI, Alicia Marcela", "Movimiento Popular Neuquino", "Neuquén", "AFIRMATIVO"], ["CONTI, Diana Beatriz", "Frente para la Victoria - PJ", "Buenos Aires", "AFIRMATIVO"], ["CORDOBA, Stella Maris", "Frente para la Victoria - PJ", "Tucumán", "AFIRMATIVO"], ["CURRILEN, Oscar Rubén", "Frente para la Victoria - PJ", "Chubut", "AFIRMATIVO"]]

    assert_equal expected, lines_to_array(Tabula.make_table(characters))
  end

  def test_forest_disclosure_report_dont_regress
    # this is the current state of the expected output. Ideally the output should be like 
    # test_forest_disclosure_report, with spaces around the & in Regional Pulmonary & Sleep 
    # and a solution for half-x-height-offset lines.
    pdf_file_path = File.expand_path('data/frx_2012_disclosure.pdf', File.dirname(__FILE__))
    character_extractor = Tabula::Extraction::CharacterExtractor.new(pdf_file_path)
    lines = Tabula::TableGuesser.find_lines_on_page(pdf_file_path, 0)
    vertical_rulings = lines.select(&:vertical?).uniq{|line| (line.left / 10).round }


    characters = character_extractor.extract.next.get_text([110, 28, 218, 833])
                                                           #top left bottom right
    expected = [['AANONSEN, DEBORAH, A', '', 'STATEN ISLAND, NY', 'MEALS', '$85.00'],
                ['TOTAL', '', '', '','$85.00'],
                ['AARON, CAREN, T', '', 'RICHMOND, VA', 'EDUCATIONAL ITEMS', '$78.80'],
                ['AARON, CAREN, T', '', 'RICHMOND, VA', 'MEALS', '$392.45'],
                ['TOTAL', '', '', '', '$471.25'],
                ['AARON, JOHN', '', 'CLARKSVILLE, TN', 'MEALS', '$20.39'],
                ['TOTAL', '', '', '','$20.39'],
                ['AARON, JOSHUA, N', '', 'WEST GROVE, PA', 'MEALS', '$310.33'],
                ["", "REGIONAL PULMONARY & SLEEP", "", "", ""], ["AARON, JOSHUA, N", "", "WEST GROVE, PA", "SPEAKING FEES", "$4,700.00"], ["", "MEDICINE", "", "", ""], 
                ['TOTAL', '', '', '', '$5,010.33'],
                ['AARON, MAUREEN, M', '', 'MARTINSVILLE, VA', 'MEALS', '$193.67'],
                ['TOTAL', '', '', '', '$193.67'],
                ['AARON, MICHAEL, L', '', 'WEST ISLIP, NY', 'MEALS', '$19.50']]

    assert_equal expected, lines_to_array(Tabula.make_table_with_vertical_rulings(characters, :vertical_rulings => vertical_rulings))
  end

  def test_missing_spaces_around_an_ampersand
    pdf_file_path = File.expand_path('data/frx_2012_disclosure.pdf', File.dirname(__FILE__))
    character_extractor = Tabula::Extraction::CharacterExtractor.new(pdf_file_path)
    lines = Tabula::TableGuesser.find_lines_on_page(pdf_file_path, 0)
    vertical_rulings = lines.select(&:vertical?).uniq{|line| (line.left / 10).round }


    characters = character_extractor.extract.next.get_text([170, 28, 185, 833])
                                                           #top left bottom right
    expected = [
                 ["", "REGIONAL PULMONARY & SLEEP", "", "", ""], ["AARON, JOSHUA, N", "", "WEST GROVE, PA", "SPEAKING FEES", "$4,700.00"], ["", "MEDICINE", "", "", ""], 
                ]

    assert_equal expected, lines_to_array(Tabula.make_table_with_vertical_rulings(characters, :vertical_rulings => vertical_rulings))
  end

  def test_forest_disclosure_report
    pdf_file_path = File.expand_path('data/frx_2012_disclosure.pdf', File.dirname(__FILE__))
    character_extractor = Tabula::Extraction::CharacterExtractor.new(pdf_file_path)
    lines = Tabula::TableGuesser.find_lines_on_page(pdf_file_path, 0)
    vertical_rulings = lines.select(&:vertical?).uniq{|line| (line.left / 10).round }


    characters = character_extractor.extract.next.get_text([110, 28, 218, 833])
                                                           #top left bottom right
    expected = [['AANONSEN, DEBORAH, A', '', 'STATEN ISLAND, NY', 'MEALS', '$85.00'],
                ['TOTAL', '', '', '','$85.00'],
                ['AARON, CAREN, T', '', 'RICHMOND, VA', 'EDUCATIONAL ITEMS', '$78.80'],
                ['AARON, CAREN, T', '', 'RICHMOND, VA', 'MEALS', '$392.45'],
                ['TOTAL', '', '', '', '$471.25'],
                ['AARON, JOHN', '', 'CLARKSVILLE, TN', 'MEALS', '$20.39'],
                ['TOTAL', '', '', '','$20.39'],
                ['AARON, JOSHUA, N', '', 'WEST GROVE, PA', 'MEALS', '$310.33'],
                ['AARON, JOSHUA, N', 'REGIONAL PULMONARY & SLEEP MEDICINE', 'WEST GROVE, PA', 'SPEAKING FEES', '$4,700.00'],
                ['TOTAL', '', '', '', '$5,010.33'],
                ['AARON, MAUREEN, M', '', 'MARTINSVILLE, VA', 'MEALS', '$193.67'],
                ['TOTAL', '', '', '', '$193.67'],
                ['AARON, MICHAEL, L', '', 'WEST ISLIP, NY', 'MEALS', '$19.50']]

    assert_equal expected, lines_to_array(Tabula.make_table_with_vertical_rulings(characters, :vertical_rulings => vertical_rulings))
  end

  # TODO Spaces inserted in words - fails
  def test_bo_page24
    character_extractor = Tabula::Extraction::CharacterExtractor.new(File.expand_path('data/bo_page24.pdf', File.dirname(__FILE__)))
    characters = character_extractor.extract.next.get_text([435.625, 53.125, 585.7142857142857, 810.5357142857142])

    expected = [["1", "UNICA", "CECILIA KANDUS", "16/12/2008", "PEDRO ALBERTO GALINDEZ", "60279/09"], ["1", "UNICA", "CECILIA KANDUS", "10/06/2009", "PASTORA FILOMENA NAVARRO", "60280/09"], ["13", "UNICA", "MIRTA S. BOTTALLO DE VILLA", "02/07/2009", "MARIO LUIS ANGELERI, DNI 4.313.138", "60198/09"], ["16", "UNICA", "LUIS PEDRO FASANELLI", "22/05/2009", "PETTER o PEDRO KAHRS", "60244/09"], ["18", "UNICA", "ALEJANDRA SALLES", "26/06/2009", "RAUL FERNANDO FORTINI", "60236/09"], ["31", "UNICA", "MARÍA CRISTINA GARCÍA", "17/06/2009", "DOMINGO TRIPODI Y PAULA LUPPINO", "60302/09"], ["34", "UNICA", "SUSANA B. MARZIONI", "11/06/2009", "JESUSA CARMEN VAZQUEZ", "60177/09"], ["51", "UNICA", "MARIA LUCRECIA SERRAT", "19/05/2009", "DANIEL DECUADRO", "60227/09"], ["51", "UNICA", "MARIA LUCRECIA SERRAT", "12/02/2009", "ELIZABETH LILIANA MANSILLA ROMERO", "60150/09"], ["75", "UNICA", "IGNACIO M. REBAUDI BASAVILBASO", "01/07/2009", "ABALSAMO ALFREDO DANIEL", "60277/09"], ["94", "UNICA", "GABRIELA PALÓPOLI", "02/07/2009", "ALVAREZ ALICIA ESTHER", "60360/09"], ["96", "UNICA", "DANIEL PAZ EYNARD", "16/06/2009", "NELIDA ALBORADA ALCARAZ SERRANO", "60176/09"]]
    assert_equal expected, lines_to_array(Tabula.make_table(characters))
  end


end
