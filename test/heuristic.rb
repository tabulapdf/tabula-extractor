#a list of filenames and the correct answer
# no more bs.
require_relative '../lib/tabula'


should_use_spreadsheet = Dir.glob( File.join(File.dirname(File.absolute_path(__FILE__)), "heuristic-test-set", "spreadsheet/*") ).map{|a| [a, true]}
should_use_original  = Dir.glob( File.join(File.dirname(File.absolute_path(__FILE__)), "heuristic-test-set", "original/*") ).map{|a| [a, false]}

correct = []
misclassified_as_original = []
misclassified_as_spreadsheet = []

(should_use_spreadsheet + should_use_original) .each do |filename, expected_to_be_tabular|
  extractor = Tabula::Extraction::CharacterExtractor.new(filename, [1])

  page = extractor.extract.first
  page.get_ruling_lines!
  page_is_tabular = page.is_tabular?

  if page_is_tabular && expected_to_be_tabular  || !page_is_tabular && !expected_to_be_tabular
    correct << filename
  elsif page_is_tabular && !expected_to_be_tabular
    misclassified_as_spreadsheet << filename
  elsif !page_is_tabular && expected_to_be_tabular
    misclassified_as_original << filename
  end
end



puts "#{correct.size} PDFs were correctly classified"
puts "#{misclassified_as_original.size + misclassified_as_spreadsheet.size} PDFs were incorrectly classified"
unless misclassified_as_spreadsheet.empty?
  puts "#{misclassified_as_spreadsheet.size} PDFs should use the original extraction algorithm\n\t but was classified as needing the spreadsheet algorithm"
  misclassified_as_spreadsheet.each do |filename|
    puts " - #{filename}"
  end
end
unless misclassified_as_original.empty?
  puts "#{misclassified_as_original.size} PDFs should use the spreadsheet extraction algorithm\n\t but was classified as needing the original algorithm"
  misclassified_as_original.each do |filename|
    puts " - #{filename}"
  end
end
