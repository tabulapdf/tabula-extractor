# -*- coding: utf-8 -*-
require 'minitest'
require 'minitest/autorun'

require_relative '../lib/tabula'

def lines_to_array(lines)
  lines.map { |l|
    l.map { |te| te.text.strip }
  }
end

def lines_to_table(lines)
  Tabula::Table.new_from_array(lines_to_array(lines))
end


# I don't want to pollute the "real" class with a funny inspect method. Just for testing comparisons.
module Tabula
  class Table
    def inspect
      "[" + lines.map(&:inspect).join(",") + "]"
    end
  end
end

module Tabula
  class Line
    def inspect
      @text_elements.map(&:text).inspect
    end
  end
end


class TestEntityComparability < Minitest::Test
  def test_text_element_comparability
    base = Tabula::TextElement.new(nil, nil, nil, nil, nil, nil, "Jeremy", nil)

    two = Tabula::TextElement.new(nil, nil, nil, nil, nil, nil, " Jeremy  \n", nil)
    three = Tabula::TextElement.new(7, 6, 8, 6, nil, 12, "Jeremy", 88)
    four = Tabula::TextElement.new(5, 7, 1212, 121, 66, 15, "Jeremy", 55)

    five = Tabula::TextElement.new(5, 7, 1212, 121, 66, 15, "jeremy b", 55)
    six = Tabula::TextElement.new(5, 7, 1212, 121, 66, 15, "jeremy    kj", 55)
    seven = Tabula::TextElement.new(nil, nil, nil, nil, nil, nil, "jeremy    kj", nil)
    assert_equal base, two
    assert_equal base, three
    assert_equal base, four

    refute_equal base, five
    refute_equal base, six
    refute_equal base, seven
  end

  def test_line_comparability
    text_base = Tabula::TextElement.new(nil, nil, nil, nil, nil, nil, "Jeremy", nil)

    text_two = Tabula::TextElement.new(nil, nil, nil, nil, nil, nil, " Jeremy  \n", nil)
    text_three = Tabula::TextElement.new(7, 6, 8, 6, nil, 12, "Jeremy", 88)
    text_four = Tabula::TextElement.new(5, 7, 1212, 121, 66, 15, "Jeremy", 55)

    text_five = Tabula::TextElement.new(5, 7, 1212, 121, 66, 15, "jeremy b", 55)
    text_six = Tabula::TextElement.new(5, 7, 1212, 121, 66, 15, "jeremy    kj", 55)
    text_seven = Tabula::TextElement.new(nil, nil, nil, nil, nil, nil, "jeremy    kj", nil)
    line_base = Tabula::Line.new
    line_base.text_elements = [text_base, text_two, text_three]
    line_equal = Tabula::Line.new
    line_equal.text_elements = [text_base, text_two, text_three]
    line_equal_but_longer = Tabula::Line.new
    line_equal_but_longer.text_elements = [text_base, text_two, text_three, Tabula::TextElement::EMPTY, Tabula::TextElement::EMPTY]
    line_unequal = Tabula::Line.new
    line_unequal.text_elements = [text_base, text_two, text_three, text_five]
    line_unequal_and_longer = Tabula::Line.new
    line_unequal_and_longer.text_elements = [text_base, text_two, text_three, text_five, Tabula::TextElement::EMPTY, Tabula::TextElement::EMPTY]
    line_unequal_and_longer_and_different = Tabula::Line.new
    line_unequal_and_longer_and_different.text_elements = [text_base, text_two, text_three, text_five, Tabula::TextElement::EMPTY, 'whatever']

    assert_equal line_base, line_equal
    assert_equal line_base, line_equal_but_longer
    refute_equal line_base, line_unequal
    refute_equal line_base, line_unequal_and_longer
    refute_equal line_base, line_unequal_and_longer_and_different
  end

  def test_table_comparability
    rows_base = [["a", "b", "c"], ['', 'd', '']]
    rows_equal = [["a", "b", "c"], ['', 'd']]
    rows_equal_padded = [['', "a", "b", "c"], ['', '', 'd']]
    rows_unequal_one = [["a", "b", "c"], ['d']]
    rows_unequal_two = [["a", "b", "c"], ['d', '']]
    rows_unequal_three = [["a", "b", "c"], ['d'], ['a','b', 'd']]
    rows_unequal_four = [["a", "b", "c"]]

    table_base = Tabula::Table.new_from_array(rows_base)
    table_equal = Tabula::Table.new_from_array(rows_equal)
    table_equal_column_padded = Tabula::Table.new_from_array(rows_equal_padded)
    table_unequal_one = Tabula::Table.new_from_array(rows_unequal_one)
    table_unequal_two = Tabula::Table.new_from_array(rows_unequal_two)
    table_unequal_three = Tabula::Table.new_from_array(rows_unequal_three)
    table_unequal_four = Tabula::Table.new_from_array(rows_unequal_four)

    assert_equal table_base, table_equal
    assert_equal table_base, table_equal_column_padded
    refute_equal table_base, table_unequal_one
    refute_equal table_base, table_unequal_two
    refute_equal table_base, table_unequal_three
    refute_equal table_base, table_unequal_four
  end
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

class TestTableGuesser < Minitest::Test
  def test_find_rects_from_lines_with_lsd
    skip "Skipping until we actually use LSD"
    filename = File.expand_path('data/frx_2012_disclosure.pdf', File.dirname(__FILE__))
    page_index = 0
    lines = Tabula::Extraction::LineExtractor.lines_in_pdf_page(filename, page_index, :render_pdf => true)

    page_areas = Tabula::TableGuesser::find_rects_from_lines(lines)
    page_areas.map!{|rect| rect.dims(:top, :left, :bottom, :right)}
    expected_page_areas = [[54.087890625, 50.203125, 734.220703125, 550.44140625]]
    assert_equal expected_page_areas, page_areas
  end

end

class TestDumper < Minitest::Test

  def test_extractor
    extractor = Tabula::Extraction::ObjectExtractor.new(File.expand_path('data/gre.pdf', File.dirname(__FILE__)))
    page = extractor.extract.next
    assert_instance_of Tabula::Page, page
  end

  def test_get_by_area
    extractor = Tabula::Extraction::ObjectExtractor.new(File.expand_path('data/gre.pdf', File.dirname(__FILE__)))
    characters = extractor.extract.next.get_text([107.1, 57.9214, 394.5214, 290.7])
    assert_equal characters.size, 206
  end
end

class TestRulingIntersection < Minitest::Test
  def test_ruling_intersection
    horizontals = [Tabula::Ruling.new(10, 1, 10, 0)]
    verticals   = [Tabula::Ruling.new(1, 3, 0, 11),
                   Tabula::Ruling.new(1, 4, 0, 11)]
    ints = Tabula::Ruling.find_intersections(horizontals, verticals).to_a
    assert_equal 2, ints.size
    assert_equal ints[0][0].getX, 3.0
    assert_equal ints[0][0].getY, 10.0
    assert_equal ints[1][0].getX, 4.0
    assert_equal ints[1][0].getY, 10.0

    verticals =   [Tabula::Ruling.new(20, 3, 0, 11)]
    ints = Tabula::Ruling.find_intersections(horizontals, verticals).to_a
    assert_equal ints.size, 0
  end
end

class TestExtractor < Minitest::Test

  def test_table_extraction_1
    table = lines_to_array Tabula.extract_table(File.expand_path('data/gre.pdf', File.dirname(__FILE__)),
                                                1,
                                                [107.1, 57.9214, 394.5214, 290.7],
                                                :detect_ruling_lines => false)

    expected = [["Prior Scale","New Scale","% Rank*"], ["800","170","99"], ["790","170","99"], ["780","170","99"], ["770","170","99"], ["760","170","99"], ["750","169","99"], ["740","169","99"], ["730","168","98"], ["720","168","98"], ["710","167","97"], ["700","166","96"], ["690","165","95"], ["680","165","95"], ["670","164","93"], ["660","164","93"], ["650","163","91"]]

    assert_equal expected, table
  end

  def test_diputados_voting_record
    table = lines_to_array Tabula.extract_table(File.expand_path('data/argentina_diputados_voting_record.pdf', File.dirname(__FILE__)),
                                                1,
                                                [269.875, 12.75, 790.5, 561])

    expected = [["ABDALA de MATARAZZO, Norma Amanda", "Frente Cívico por Santiago", "Santiago del Estero", "AFIRMATIVO"], ["ALBRIEU, Oscar Edmundo Nicolas", "Frente para la Victoria - PJ", "Rio Negro", "AFIRMATIVO"], ["ALONSO, María Luz", "Frente para la Victoria - PJ", "La Pampa", "AFIRMATIVO"], ["ARENA, Celia Isabel", "Frente para la Victoria - PJ", "Santa Fe", "AFIRMATIVO"], ["ARREGUI, Andrés Roberto", "Frente para la Victoria - PJ", "Buenos Aires", "AFIRMATIVO"], ["AVOSCAN, Herman Horacio", "Frente para la Victoria - PJ", "Rio Negro", "AFIRMATIVO"], ["BALCEDO, María Ester", "Frente para la Victoria - PJ", "Buenos Aires", "AFIRMATIVO"], ["BARRANDEGUY, Raúl Enrique", "Frente para la Victoria - PJ", "Entre Ríos", "AFIRMATIVO"], ["BASTERRA, Luis Eugenio", "Frente para la Victoria - PJ", "Formosa", "AFIRMATIVO"], ["BEDANO, Nora Esther", "Frente para la Victoria - PJ", "Córdoba", "AFIRMATIVO"], ["BERNAL, María Eugenia", "Frente para la Victoria - PJ", "Jujuy", "AFIRMATIVO"], ["BERTONE, Rosana Andrea", "Frente para la Victoria - PJ", "Tierra del Fuego", "AFIRMATIVO"], ["BIANCHI, María del Carmen", "Frente para la Victoria - PJ", "Cdad. Aut. Bs. As.", "AFIRMATIVO"], ["BIDEGAIN, Gloria Mercedes", "Frente para la Victoria - PJ", "Buenos Aires", "AFIRMATIVO"], ["BRAWER, Mara", "Frente para la Victoria - PJ", "Cdad. Aut. Bs. As.", "AFIRMATIVO"], ["BRILLO, José Ricardo", "Movimiento Popular Neuquino", "Neuquén", "AFIRMATIVO"], ["BROMBERG, Isaac Benjamín", "Frente para la Victoria - PJ", "Tucumán", "AFIRMATIVO"], ["BRUE, Daniel Agustín", "Frente Cívico por Santiago", "Santiago del Estero", "AFIRMATIVO"], ["CALCAGNO, Eric", "Frente para la Victoria - PJ", "Buenos Aires", "AFIRMATIVO"], ["CARLOTTO, Remo Gerardo", "Frente para la Victoria - PJ", "Buenos Aires", "AFIRMATIVO"], ["CARMONA, Guillermo Ramón", "Frente para la Victoria - PJ", "Mendoza", "AFIRMATIVO"], ["CATALAN MAGNI, Julio César", "Frente para la Victoria - PJ", "Tierra del Fuego", "AFIRMATIVO"], ["CEJAS, Jorge Alberto", "Frente para la Victoria - PJ", "Rio Negro", "AFIRMATIVO"], ["CHIENO, María Elena", "Frente para la Victoria - PJ", "Corrientes", "AFIRMATIVO"], ["CIAMPINI, José Alberto", "Frente para la Victoria - PJ", "Neuquén", "AFIRMATIVO"], ["CIGOGNA, Luis Francisco Jorge", "Frente para la Victoria - PJ", "Buenos Aires", "AFIRMATIVO"], ["CLERI, Marcos", "Frente para la Victoria - PJ", "Santa Fe", "AFIRMATIVO"], ["COMELLI, Alicia Marcela", "Movimiento Popular Neuquino", "Neuquén", "AFIRMATIVO"], ["CONTI, Diana Beatriz", "Frente para la Victoria - PJ", "Buenos Aires", "AFIRMATIVO"], ["CORDOBA, Stella Maris", "Frente para la Victoria - PJ", "Tucumán", "AFIRMATIVO"], ["CURRILEN, Oscar Rubén", "Frente para la Victoria - PJ", "Chubut", "AFIRMATIVO"]]

    assert_equal expected, table
  end

  def test_forest_disclosure_report_dont_regress
    # this is the current state of the expected output. Ideally the output should be like
    # test_forest_disclosure_report, with spaces around the & in Regional Pulmonary & Sleep
    # and a solution for half-x-height-offset lines.
    pdf_file_path = File.expand_path('data/frx_2012_disclosure.pdf', File.dirname(__FILE__))

    table = lines_to_table Tabula.extract_table(pdf_file_path,
                                                1,
                                                [106.01, 48.09, 227.31, 551.89],
                                                :detect_ruling_lines => true)

    expected = Tabula::Table.new_from_array([["AANONSEN, DEBORAH, A", "", "STATEN ISLAND, NY", "MEALS", "$85.00"], ["TOTAL", "", "", "", "$85.00"], ["AARON, CAREN, T", "", "RICHMOND, VA", "EDUCATIONAL ITEMS", "$78.80"], ["AARON, CAREN, T", "", "RICHMOND, VA", "MEALS", "$392.45"], ["TOTAL", "", "", "", "$471.25"], ["AARON, JOHN", "", "CLARKSVILLE, TN", "MEALS", "$20.39"], ["TOTAL", "", "", "", "$20.39"], ["AARON, JOSHUA, N", "", "WEST GROVE, PA", "MEALS", "$310.33"], ["", "REGIONAL PULMONARY & SLEEP"], ["AARON, JOSHUA, N", "", "WEST GROVE, PA", "SPEAKING FEES", "$4,700.00"], ["", "MEDICINE"], ["TOTAL", "", "", "", "$5,010.33"], ["AARON, MAUREEN, M", "", "MARTINSVILLE, VA", "MEALS", "$193.67"], ["TOTAL", "", "", "", "$193.67"], ["AARON, MICHAEL, L", "", "WEST ISLIP, NY", "MEALS", "$19.50"], ["TOTAL", "", "", "", "$19.50"], ["AARON, MICHAEL, R", "", "BROOKLYN, NY", "MEALS", "$65.92"]])


    assert_equal expected, table
  end

  def test_missing_spaces_around_an_ampersand
    pdf_file_path = File.expand_path('data/frx_2012_disclosure.pdf', File.dirname(__FILE__))
    character_extractor = Tabula::Extraction::ObjectExtractor.new(pdf_file_path)
    page_obj = character_extractor.extract.next
    lines = page_obj.ruling_lines
    vertical_rulings = lines.select(&:vertical?)

    characters = page_obj.get_text([170, 28, 185, 833]) #top left bottom right

    expected = Tabula::Table.new_from_array([
       ["", "REGIONAL PULMONARY & SLEEP",],
       ["AARON, JOSHUA, N", "", "WEST GROVE, PA", "SPEAKING FEES", "$4,700.00"],
       ["", "MEDICINE", ],
      ])

    assert_equal expected, lines_to_table(Tabula.make_table(characters, :vertical_rulings => vertical_rulings))
  end

  def test_forest_disclosure_report
    skip "Skipping until we support multiline cells"
    pdf_file_path = File.expand_path('data/frx_2012_disclosure.pdf', File.dirname(__FILE__))
    character_extractor = Tabula::Extraction::ObjectExtractor.new(pdf_file_path)
    lines = Tabula::TableGuesser.find_lines_on_page(pdf_file_path, 0)
    vertical_rulings = lines.select(&:vertical?) #.uniq{|line| (line.left / 10).round }

    characters = character_extractor.extract.next.get_text([110, 28, 218, 833])
                                                           #top left bottom right
        expected = Tabula::Table.new_from_array([
          ['AANONSEN, DEBORAH, A', '', 'STATEN ISLAND, NY', 'MEALS', '', '$85.00'],
          ['TOTAL', '', '', '','$85.00'],
          ['AARON, CAREN, T', '', 'RICHMOND, VA', 'EDUCATIONAL ITEMS', '', '$78.80'],
          ['AARON, CAREN, T', '', 'RICHMOND, VA', 'MEALS', '', '$392.45'],
          ['TOTAL', '', '', '', '$471.25'],
          ['AARON, JOHN', '', 'CLARKSVILLE, TN', 'MEALS', '', '$20.39'],
          ['TOTAL', '', '', '','$20.39'],
          ['AARON, JOSHUA, N', '', 'WEST GROVE, PA', 'MEALS', '', '$310.33'],
          ['AARON, JOSHUA, N', 'REGIONAL PULMONARY & SLEEP MEDICINE', 'WEST GROVE, PA', 'SPEAKING FEES', '', '$4,700.00'],
          ['TOTAL', '', '', '', '$5,010.33'],
          ['AARON, MAUREEN, M', '', 'MARTINSVILLE, VA', 'MEALS', '', '$193.67'],
          ['TOTAL', '', '', '', '$193.67'],
          ['AARON, MICHAEL, L', '', 'WEST ISLIP, NY', 'MEALS', '', '$19.50']
        ])

    assert_equal expected, lines_to_table(Tabula.make_table(characters, :vertical_rulings => vertical_rulings))
  end

  # TODO Spaces inserted in words - fails
  def test_bo_page24
    table = lines_to_array Tabula.extract_table(File.expand_path('data/bo_page24.pdf', File.dirname(__FILE__)),
                                                1,
                                                [425.625, 53.125, 575.714, 810.535],
                                                :detect_ruling_lines => false)

    expected = [["1", "UNICA", "CECILIA KANDUS", "16/12/2008", "PEDRO ALBERTO GALINDEZ", "60279/09"], ["1", "UNICA", "CECILIA KANDUS", "10/06/2009", "PASTORA FILOMENA NAVARRO", "60280/09"], ["13", "UNICA", "MIRTA S. BOTTALLO DE VILLA", "02/07/2009", "MARIO LUIS ANGELERI, DNI 4.313.138", "60198/09"], ["16", "UNICA", "LUIS PEDRO FASANELLI", "22/05/2009", "PETTER o PEDRO KAHRS", "60244/09"], ["18", "UNICA", "ALEJANDRA SALLES", "26/06/2009", "RAUL FERNANDO FORTINI", "60236/09"], ["31", "UNICA", "MARÍA CRISTINA GARCÍA", "17/06/2009", "DOMINGO TRIPODI Y PAULA LUPPINO", "60302/09"], ["34", "UNICA", "SUSANA B. MARZIONI", "11/06/2009", "JESUSA CARMEN VAZQUEZ", "60177/09"], ["51", "UNICA", "MARIA LUCRECIA SERRAT", "19/05/2009", "DANIEL DECUADRO", "60227/09"], ["51", "UNICA", "MARIA LUCRECIA SERRAT", "12/02/2009", "ELIZABETH LILIANA MANSILLA ROMERO", "60150/09"], ["75", "UNICA", "IGNACIO M. REBAUDI BASAVILBASO", "01/07/2009", "ABALSAMO ALFREDO DANIEL", "60277/09"], ["94", "UNICA", "GABRIELA PALÓPOLI", "02/07/2009", "ALVAREZ ALICIA ESTHER", "60360/09"], ["96", "UNICA", "DANIEL PAZ EYNARD", "16/06/2009", "NELIDA ALBORADA ALCARAZ SERRANO", "60176/09"]]

    assert_equal expected, table
  end


  def test_vertical_rulings_splitting_words
    #if a vertical ruling crosses over a word, the word should be split at that vertical ruling
    # before, the entire word would end up on one side of the vertical ruling.
    pdf_file_path = File.expand_path('data/vertical_rulings_bug.pdf', File.dirname(__FILE__))

    #both of these are semantically "correct"; the difference is in how we handle multi-line cells
    expected = Tabula::Table.new_from_array([
      ["ABRAHAMS, HARRISON M", "ARLINGTON", "TX", "HARRISON M ABRAHAMS", "", "", "$3.08", "", "", "$3.08"],
      ["ABRAHAMS, ROGER A", "MORGANTOWN", "WV", "ROGER A ABRAHAMS", "", "$1500.00", "$76.28", "$49.95", "", "$1626.23"],
      ["ABRAHAMSON, TIMOTHY GARTH", "URBANDALE", "IA", "TIMOTHY GARTH ABRAHAMSON", "", "", "$22.93", "", "", "$22.93"]
     ])
    other_expected = Tabula::Table.new_from_array([
      ["ABRAHAMS, HARRISON M", "ARLINGTON", "TX", "HARRISON M ABRAHAMS", "", "", "$3.08", "", "", "$3.08"],
      ["ABRAHAMS, ROGER A", "MORGANTOWN", "WV", "ROGER A ABRAHAMS", "", "$1500.00", "$76.28", "$49.95", "", "$1626.23"],
      ["ABRAHAMSON, TIMOTHY GARTH", "URBANDALE", "IA", "TIMOTHY GARTH", "", "", "$22.93", "", "", "$22.93"],
      ["", "", "", "ABRAHAMSON"]
     ])

    #N.B. it's "MORGANTOWN", "WV" that we're most interested in here (it used to show up as ["MORGANTOWNWV", "", ""])


    extractor = Tabula::Extraction::ObjectExtractor.new(pdf_file_path, 1...2) #:all ) # 1..2643
    extractor.extract.each_with_index do |pdf_page, page_index|

      page_areas = [[250, 0, 325, 1700]]

      scale_factor = pdf_page.width / 1700

      vertical_rulings = [0, 360, 506, 617, 906, 1034, 1160, 1290, 1418, 1548].map{|n| Tabula::Ruling.new(0, n * scale_factor, 0, 1000)}

      tables = page_areas.map do |page_area|
        text = pdf_page.get_text( page_area ) #all the characters within the given area.
        Tabula.make_table(text, {:vertical_rulings => vertical_rulings, :merge_words => true})
      end
      assert_equal expected, lines_to_table(tables.first)
    end
  end

  def test_vertical_rulings_prevent_merging_of_columns
    expected = [["SZARANGOWICZ", "GUSTAVO ALEJANDRO", "25.096.244", "20-25096244-5", "09/10/2013", "EFECTIVO", "$ 10.000,00"], ["TAILHADE", "LUIS RODOLFO", "21.386.299", "20-21386299-6", "09/10/2013", "EFECTIVO", "$ 10.000,00"], ["TEDESCHI", "ADRIÁN ALBERTO", "24.171.507", "20-24171507-9", "09/10/2013", "EFECTIVO", "$ 10.000,00"], ["URRIZA", "MARÍA TERESA", "18.135.604", "27-18135604-4", "09/10/2013", "EFECTIVO", "$ 10.000,00"], ["USTARROZ", "GERÓNIMO JAVIER", "24.912.947", "20-24912947-0", "09/10/2013", "EFECTIVO", "$ 10.000,00"], ["VALSANGIACOMO BLANC", "OFERNANDO JORGE", "26.800.203", "20-26800203-1", "09/10/2013", "EFECTIVO", "$ 10.000,00"], ["VICENTE", "PABLO ARIEL", "21.897.586", "20-21897586-1", "09/10/2013", "EFECTIVO", "$ 10.000,00"], ["AMBURI", "HUGO ALBERTO", "14.096.560", "20-14096560-0", "09/10/2013", "EFECTIVO", "$ 20.000,00"], ["BERRA", "CLAUDIA SUSANA", "14.433.112", "27-14433112-0", "09/10/2013", "EFECTIVO", "$ 10.000,00"]]

    vertical_rulings = [47,147,256,310,375,431,504].map{|n| Tabula::Ruling.new(0, n, 0, 1000)}

    table = lines_to_array Tabula.extract_table(File.expand_path('data/campaign_donors.pdf', File.dirname(__FILE__)),
                                                1,
                                                [255.57,40.43,398.76,557.35],
                                                :vertical_rulings => vertical_rulings)

    assert_equal expected, table
  end

  def test_get_spacing_and_merging_right
    table = lines_to_array Tabula.extract_table(File.expand_path('data/strongschools.pdf', File.dirname(__FILE__)),
                                                1,
                                                [52.32857142857143,15.557142857142859,128.70000000000002,767.9571428571429],
                                                :detect_ruling_lines => true)

    expected = [["Last Name", "First Name", "Address", "City", "State", "Zip", "Occupation", "Employer", "Date", "Amount"], ["Lidstad", "Dick & Peg", "62 Mississippi River Blvd N", "Saint Paul", "MN", "55104", "retired", "", "10/12/2012", "60.00"], ["Strom", "Pam", "1229 Hague Ave", "St. Paul", "MN", "55104", "", "", "9/12/2012", "60.00"], ["Seeba", "Louise & Paul", "1399 Sheldon St", "Saint Paul", "MN", "55108", "BOE", "City of Saint Paul", "10/12/2012", "60.00"], ["Schumacher / Bales", "Douglas L. / Patricia ", "948 County Rd. D W", "Saint Paul", "MN", "55126", "", "", "10/13/2012", "60.00"], ["Abrams", "Marjorie", "238 8th St east", "St Paul", "MN", "55101", "Retired", "Retired", "8/8/2012", "75.00"], ["Crouse / Schroeder", "Abigail / Jonathan", "1545 Branston St.", "Saint Paul", "MN", "55108", "", "", "10/6/2012", "75.00"]]

    assert_equal expected, table

  end


  class SpreadsheetsHasCellsTester
    include Tabula::HasCells
    attr_accessor :cells
    def initialize(cells)
      @cells = cells
    end
  end

  #just tests the algorithm
  def test_cells_to_spreadsheets

    cells = [Tabula::Cell.new(40.0, 18.0, 208.0, 4.0), Tabula::Cell.new(44.0, 18.0, 52.0, 6.0),
      Tabula::Cell.new(50.0, 18.0, 52.0, 4.0), Tabula::Cell.new(54.0, 18.0, 52.0, 6.0),
      Tabula::Cell.new(60.0, 18.0, 52.0, 4.0), Tabula::Cell.new(64.0, 18.0, 52.0, 6.0),
      Tabula::Cell.new(70.0, 18.0, 52.0, 4.0), Tabula::Cell.new(74.0, 18.0, 52.0, 6.0),
      Tabula::Cell.new(90.0, 18.0, 52.0, 4.0), Tabula::Cell.new(94.0, 18.0, 52.0, 6.0),
      Tabula::Cell.new(100.0, 18.0, 52.0, 28.0), Tabula::Cell.new(128.0, 18.0, 52.0, 4.0),
      Tabula::Cell.new(132.0, 18.0, 52.0, 64.0), Tabula::Cell.new(196.0, 18.0, 52.0, 66.0),
      Tabula::Cell.new(262.0, 18.0, 52.0, 4.0), Tabula::Cell.new(266.0, 18.0, 52.0, 84.0),
      Tabula::Cell.new(350.0, 18.0, 52.0, 4.0), Tabula::Cell.new(354.0, 18.0, 52.0, 32.0),
      Tabula::Cell.new(386.0, 18.0, 52.0, 38.0), Tabula::Cell.new(424.0, 18.0, 52.0, 18.0),
      Tabula::Cell.new(442.0, 18.0, 52.0, 74.0), Tabula::Cell.new(516.0, 18.0, 52.0, 28.0),
      Tabula::Cell.new(544.0, 18.0, 52.0, 4.0), Tabula::Cell.new(44.0, 70.0, 156.0, 6.0),
      Tabula::Cell.new(50.0, 70.0, 156.0, 4.0), Tabula::Cell.new(54.0, 70.0, 156.0, 6.0),
      Tabula::Cell.new(60.0, 70.0, 156.0, 4.0), Tabula::Cell.new(64.0, 70.0, 156.0, 6.0),
      Tabula::Cell.new(70.0, 70.0, 156.0, 4.0), Tabula::Cell.new(74.0, 70.0, 156.0, 6.0),
      Tabula::Cell.new(84.0, 70.0, 2.0, 6.0), Tabula::Cell.new(90.0, 70.0, 156.0, 4.0),
      Tabula::Cell.new(94.0, 70.0, 156.0, 6.0), Tabula::Cell.new(100.0, 70.0, 156.0, 28.0),
      Tabula::Cell.new(128.0, 70.0, 156.0, 4.0), Tabula::Cell.new(132.0, 70.0, 156.0, 64.0),
      Tabula::Cell.new(196.0, 70.0, 156.0, 66.0), Tabula::Cell.new(262.0, 70.0, 156.0, 4.0),
      Tabula::Cell.new(266.0, 70.0, 156.0, 84.0), Tabula::Cell.new(350.0, 70.0, 156.0, 4.0),
      Tabula::Cell.new(354.0, 70.0, 156.0, 32.0), Tabula::Cell.new(386.0, 70.0, 156.0, 38.0),
      Tabula::Cell.new(424.0, 70.0, 156.0, 18.0), Tabula::Cell.new(442.0, 70.0, 156.0, 74.0),
      Tabula::Cell.new(516.0, 70.0, 156.0, 28.0), Tabula::Cell.new(544.0, 70.0, 156.0, 4.0),
      Tabula::Cell.new(84.0, 72.0, 446.0, 6.0), Tabula::Cell.new(90.0, 226.0, 176.0, 4.0),
      Tabula::Cell.new(94.0, 226.0, 176.0, 6.0), Tabula::Cell.new(100.0, 226.0, 176.0, 28.0),
      Tabula::Cell.new(128.0, 226.0, 176.0, 4.0), Tabula::Cell.new(132.0, 226.0, 176.0, 64.0),
      Tabula::Cell.new(196.0, 226.0, 176.0, 66.0), Tabula::Cell.new(262.0, 226.0, 176.0, 4.0),
      Tabula::Cell.new(266.0, 226.0, 176.0, 84.0), Tabula::Cell.new(350.0, 226.0, 176.0, 4.0),
      Tabula::Cell.new(354.0, 226.0, 176.0, 32.0), Tabula::Cell.new(386.0, 226.0, 176.0, 38.0),
      Tabula::Cell.new(424.0, 226.0, 176.0, 18.0), Tabula::Cell.new(442.0, 226.0, 176.0, 74.0),
      Tabula::Cell.new(516.0, 226.0, 176.0, 28.0), Tabula::Cell.new(544.0, 226.0, 176.0, 4.0),
      Tabula::Cell.new(90.0, 402.0, 116.0, 4.0), Tabula::Cell.new(94.0, 402.0, 116.0, 6.0),
      Tabula::Cell.new(100.0, 402.0, 116.0, 28.0), Tabula::Cell.new(128.0, 402.0, 116.0, 4.0),
      Tabula::Cell.new(132.0, 402.0, 116.0, 64.0), Tabula::Cell.new(196.0, 402.0, 116.0, 66.0),
      Tabula::Cell.new(262.0, 402.0, 116.0, 4.0), Tabula::Cell.new(266.0, 402.0, 116.0, 84.0),
      Tabula::Cell.new(350.0, 402.0, 116.0, 4.0), Tabula::Cell.new(354.0, 402.0, 116.0, 32.0),
      Tabula::Cell.new(386.0, 402.0, 116.0, 38.0), Tabula::Cell.new(424.0, 402.0, 116.0, 18.0),
      Tabula::Cell.new(442.0, 402.0, 116.0, 74.0), Tabula::Cell.new(516.0, 402.0, 116.0, 28.0),
      Tabula::Cell.new(544.0, 402.0, 116.0, 4.0), Tabula::Cell.new(84.0, 518.0, 246.0, 6.0),
      Tabula::Cell.new(90.0, 518.0, 186.0, 4.0), Tabula::Cell.new(94.0, 518.0, 186.0, 6.0),
      Tabula::Cell.new(100.0, 518.0, 186.0, 28.0), Tabula::Cell.new(128.0, 518.0, 186.0, 4.0),
      Tabula::Cell.new(132.0, 518.0, 186.0, 64.0), Tabula::Cell.new(196.0, 518.0, 186.0, 66.0),
      Tabula::Cell.new(262.0, 518.0, 186.0, 4.0), Tabula::Cell.new(266.0, 518.0, 186.0, 84.0),
      Tabula::Cell.new(350.0, 518.0, 186.0, 4.0), Tabula::Cell.new(354.0, 518.0, 186.0, 32.0),
      Tabula::Cell.new(386.0, 518.0, 186.0, 38.0), Tabula::Cell.new(424.0, 518.0, 186.0, 18.0),
      Tabula::Cell.new(442.0, 518.0, 186.0, 74.0), Tabula::Cell.new(516.0, 518.0, 186.0, 28.0),
      Tabula::Cell.new(544.0, 518.0, 186.0, 4.0), Tabula::Cell.new(90.0, 704.0, 60.0, 4.0),
      Tabula::Cell.new(94.0, 704.0, 60.0, 6.0), Tabula::Cell.new(100.0, 704.0, 60.0, 28.0),
      Tabula::Cell.new(128.0, 704.0, 60.0, 4.0), Tabula::Cell.new(132.0, 704.0, 60.0, 64.0),
      Tabula::Cell.new(196.0, 704.0, 60.0, 66.0), Tabula::Cell.new(262.0, 704.0, 60.0, 4.0),
      Tabula::Cell.new(266.0, 704.0, 60.0, 84.0), Tabula::Cell.new(350.0, 704.0, 60.0, 4.0),
      Tabula::Cell.new(354.0, 704.0, 60.0, 32.0), Tabula::Cell.new(386.0, 704.0, 60.0, 38.0),
      Tabula::Cell.new(424.0, 704.0, 60.0, 18.0), Tabula::Cell.new(442.0, 704.0, 60.0, 74.0),
      Tabula::Cell.new(516.0, 704.0, 60.0, 28.0), Tabula::Cell.new(544.0, 704.0, 60.0, 4.0),
      Tabula::Cell.new(84.0, 764.0, 216.0, 6.0), Tabula::Cell.new(90.0, 764.0, 216.0, 4.0),
      Tabula::Cell.new(94.0, 764.0, 216.0, 6.0), Tabula::Cell.new(100.0, 764.0, 216.0, 28.0),
      Tabula::Cell.new(128.0, 764.0, 216.0, 4.0), Tabula::Cell.new(132.0, 764.0, 216.0, 64.0),
      Tabula::Cell.new(196.0, 764.0, 216.0, 66.0), Tabula::Cell.new(262.0, 764.0, 216.0, 4.0),
      Tabula::Cell.new(266.0, 764.0, 216.0, 84.0), Tabula::Cell.new(350.0, 764.0, 216.0, 4.0),
      Tabula::Cell.new(354.0, 764.0, 216.0, 32.0), Tabula::Cell.new(386.0, 764.0, 216.0, 38.0),
      Tabula::Cell.new(424.0, 764.0, 216.0, 18.0), Tabula::Cell.new(442.0, 764.0, 216.0, 74.0),
      Tabula::Cell.new(516.0, 764.0, 216.0, 28.0), Tabula::Cell.new(544.0, 764.0, 216.0, 4.0)]


    expected_spreadsheets = [Tabula::Spreadsheet.new(40.0, 18.0, 208.0, 40.0, nil, nil, nil, nil),
                             Tabula::Spreadsheet.new(84.0, 18.0, 962.0, 464.0,nil, nil, nil, nil)]

    #compares spreadsheets on area only.
    assert_equal expected_spreadsheets.map{|s| [s.x, s.y, s.width, s.height] },
      SpreadsheetsHasCellsTester.new(cells).find_spreadsheets_from_cells.map{|a| s = a.getBounds; [s.x, s.y, s.width, s.height] }


  end

  def test_add_merged_cells
    skip "until I write it"
  end

  def test_add_placeholder_cells_to_funny_shaped_tables
    skip "until I write it, cf 01005787B_Pakistan.pdf"
  end

  class CellsHasCellsTester
    include Tabula::HasCells
    attr_accessor :vertical_ruling_lines, :horizontal_ruling_lines, :cells
    def initialize(vertical_ruling_lines, horizontal_ruling_lines)
      @cells = []
      @vertical_ruling_lines = vertical_ruling_lines
      @horizontal_ruling_lines = horizontal_ruling_lines
      find_cells!
    end
  end

  #just tests the algorithm
  def test_lines_to_cells
    vertical_ruling_lines = [ Tabula::Ruling.new(40.0, 18.0, 0.0, 40.0),
                              Tabula::Ruling.new(44.0, 70.0, 0.0, 36.0),
                              Tabula::Ruling.new(40.0, 226.0, 0.0, 40.0)]

    horizontal_ruling_lines = [ Tabula::Ruling.new(40.0, 18.0, 208.0, 0.0),
                                Tabula::Ruling.new(44.0, 18.0, 208.0, 0.0),
                                Tabula::Ruling.new(50.0, 18.0, 208.0, 0.0),
                                Tabula::Ruling.new(54.0, 18.0, 208.0, 0.0),
                                Tabula::Ruling.new(60.0, 18.0, 208.0, 0.0),
                                Tabula::Ruling.new(64.0, 18.0, 208.0, 0.0),
                                Tabula::Ruling.new(70.0, 18.0, 208.0, 0.0),
                                Tabula::Ruling.new(74.0, 18.0, 208.0, 0.0),
                                Tabula::Ruling.new(80.0, 18.0, 208.0, 0.0)]

    expected_cells = [Tabula::Cell.new(40.0, 18.0, 208.0, 4.0), Tabula::Cell.new(44.0, 18.0, 52.0, 6.0),
                      Tabula::Cell.new(50.0, 18.0, 52.0, 4.0), Tabula::Cell.new(54.0, 18.0, 52.0, 6.0),
                      Tabula::Cell.new(60.0, 18.0, 52.0, 4.0), Tabula::Cell.new(64.0, 18.0, 52.0, 6.0),
                      Tabula::Cell.new(70.0, 18.0, 52.0, 4.0), Tabula::Cell.new(74.0, 18.0, 52.0, 6.0),
                      Tabula::Cell.new(44.0, 70.0, 156.0, 6.0), Tabula::Cell.new(50.0, 70.0, 156.0, 4.0),
                      Tabula::Cell.new(54.0, 70.0, 156.0, 6.0), Tabula::Cell.new(60.0, 70.0, 156.0, 4.0),
                      Tabula::Cell.new(64.0, 70.0, 156.0, 6.0), Tabula::Cell.new(70.0, 70.0, 156.0, 4.0),
                      Tabula::Cell.new(74.0, 70.0, 156.0, 6.0), ]

    actual_cells = CellsHasCellsTester.new(vertical_ruling_lines, horizontal_ruling_lines).cells
    assert_equal Set.new(expected_cells), Set.new(actual_cells) #I don't care about order
  end

  #this is the real deal!!
  def test_extract_tabular_data_using_lines_and_spreadsheets
    pdf_file_path = "./test/data/frx_2012_disclosure.pdf"
    expected_data_path = "./test/data/frx_2012_disclosure.tsv"
    expected = open(expected_data_path, 'r').read #.split("\n").map{|line| line.split("\t")}

    Tabula::Extraction::ObjectExtractor.new(pdf_file_path, :all).extract.each do |pdf_page|
      spreadsheet = pdf_page.spreadsheets.first
      assert_equal expected, spreadsheet.to_tsv
    end
  end

  def test_cope_with_a_tableless_page
    pdf_file_path = "./test/data/no_tables.pdf"

    spreadsheets = Tabula::Extraction::ObjectExtractor.new(pdf_file_path, :all, '',
        :line_color_filter => lambda{|components| components.all?{|c| c < 0.1}}
      ).extract.to_a.first.spreadsheets

    assert_equal 0, spreadsheets.size
  end

end
