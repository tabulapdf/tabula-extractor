require './lib/tabula'

input_filename = "vertical_rulings_bug.pdf"
out = File.new("output.xls", 'w')

extractor = Tabula::Extraction::CharacterExtractor.new(input_filename, :all) #:all ) # 1..2643
extractor.extract.each_with_index do |pdf_page, page_index|

  lines = Tabula::Ruling::clean_rulings(Tabula::LSD::detect_lines_in_pdf_page(input_filename, page_index))
  page_areas = [[0, 0, 1000, 1700]]

  scale_factor = pdf_page.width / 1700
  puts scale_factor

  vertical_rulings = [0, 360, 506, 617, 906, 700, 1034, 1160, 1290, 1418, 1548].map{|n| Geometry::Segment.new_by_arrays([n * scale_factor, 0], [n * scale_factor, 1000])}

  page_areas.each do |page_area|
    text = pdf_page.get_text( page_area ) #all the characters within the given area.

    Tabula::Writers.send(:TSV,
                         Tabula.make_table_with_vertical_rulings(text, {:vertical_rulings => vertical_rulings, :merge_words => true, :dontmerge => true}), 
                         out)
  end
end
out.close


#with dontmerge false (i.e. if we merge) we get crap. STCITY and no spaces in any cities.
#with dontmerge true (or commented out), MORGANTOWNWV, and some spaces (e.g. BRYN MAWR, but not FRESHMEADOWS)