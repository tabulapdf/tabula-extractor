tabula-extractor
================

[![Build Status](https://travis-ci.org/tabulapdf/tabula-extractor.png)](https://travis-ci.org/tabulapdf/tabula-extractor)

Extract tables from PDF files. `tabula-extractor` is the table extraction engine that powers [Tabula](http://tabula.technology), now available as a library and command line program.

Versions 0.9.6 and greater of [Tabula](http://tabula.technology) can export shell scripts using `tabula-extractor` for bulk extraction.

## Installation

`tabula-extractor` only works with JRuby 1.7 or newer. [Install JRuby](http://jruby.org/getting-started) and run

``
jruby -S gem install tabula-extractor
``


## Usage

```
Tabula helps you extract tables from PDFs

Usage:
       tabula [options] <pdf_file>
where [options] are:
Tabula helps you extract tables from PDFs
       --pages, -p <s>:   Comma separated list of ranges. Examples: --pages
                          1-3,5-7 or --pages 3. Default is --pages 1 (default:
                          1)
        --area, -a <s>:   Portion of the page to analyze
                          (top,left,bottom,right). Example: --area
                          269.875,12.75,790.5,561. Default is entire page
     --columns, -c <s>:   X coordinates of column boundaries. Example --columns
                          10.1,20.2,30.3
    --password, -s <s>:   Password to decrypt document. Default is empty
                          (default: )
           --guess, -g:   Guess the portion of the page to analyze per page.
           --debug, -d:   Print detected table areas instead of processing.
      --format, -f <s>:   Output format (CSV,TSV,HTML,JSON) (default: CSV)
     --outfile, -o <s>:   Write output to <file> instead of STDOUT (default: -)
     --spreadsheet, -r:   Force PDF to be extracted using spreadsheet-style
                          extraction (if there are ruling lines separating each
                          cell, as in a PDF of an Excel spreadsheet)
  --no-spreadsheet, -n:   Force PDF not to be extracted using spreadsheet-style
                          extraction (if there are ruling lines separating each
                          cell, as in a PDF of an Excel spreadsheet)
          --silent, -i:   Suppress all stderr output.
--use-line-returns, -u:   Use embedded line returns in cells.
         --version, -v:   Print version and exit
            --help, -h:   Show this message
```

## Command Line Examples

These examples use documents contained with `tabula-extractor`'s [`test`](https://github.com/tabulapdf/tabula-extractor/tree/master/test) folder. If you want to follow along, download the document and give it a shot. There's more extensive explanation [here](https://github.com/tabulapdf/tabula-extractor/wiki/Using-the-command-line-tabula-extractor-tool).

Extract all the tables from a document into a spreadsheet called `output.csv`:
````bash
tabula test/heuristic-test-set/spreadsheet/tabla_subsidios.pdf -o output.csv
````

Extract only the tables on page 1 into a spreadsheet called `output.csv`:
````bash
tabula --pages 1 test/heuristic-test-set/spreadsheet/strongschools.pdf -o output.csv
````

Extract only the tables on page 1 into a CSV spreadsheet onto STDOUT (that is, print it out in your terminal window):
````bash
tabula --pages 1 test/heuristic-test-set/spreadsheet/strongschools.pdf
````

Extract the data from the table contained within a certain area on page 1 into a spreadsheet called `output.csv`:
````bash
tabula test/data/vertical_rulings_bug.pdf --area 250,0,325,1700  --pages 1 -o output.csv
````

Extract all the tables from a document into a tab-separated spreadsheet called `output.tsv`:
````bash
tabula test/heuristic-test-set/spreadsheet/strongschools.pdf output.tsv --format TSV #should exclude guff
````

Extract the table from page 1, using specified locations for column boundaries, into a spreadsheet called `output.csv`:
````bash
tabula test/data/campaign_donors.pdf -o output.csv --columns 47,147,256,310,375,431,504
````

## Scripting examples

`tabula-extractor` is also a RubyGem that you can use to programmatically extract tabular data, using the Tabula engine, in your scripts or applications. We don't have docs yet, but [the tests](test/tests.rb) are a good source of information.

Here's a very basic example, using the "spreadsheet" extraction method:

````ruby
require 'tabula'

pdf_file_path = "whatever.pdf"
outfilename = "whatever.csv"

out = open(outfilename, 'w')

extractor = Tabula::Extraction::ObjectExtractor.new(pdf_file_path, :all )
extractor.extract.each do |pdf_page|
  pdf_page.spreadsheets.each do |spreadsheet|
    out << spreadsheet.to_csv
    out << "\n\n"
  end
end
out.close

````

Here's another example using the "original" extraction method, which is useful for tables that don't have ruling lines separating the rows and cells. This example extracts data from only pages 1 and 2.

````ruby
require 'tabula'

pdf_file_path = "whatever.pdf"
outfilename = "whatever.csv"

out = open(outfilename, 'w')

extractor = Tabula::Extraction::ObjectExtractor.new(pdf_file_path, 1..2)
extractor.extract.each_with_index do |pdf_page, page_index|
  page_areas = [[250, 0, 325, 1700]]

  page_areas.each do |page_area|
    out << pdf_page.get_area(page_area).make_table.to_csv
    out << "\n\n"
  end

end
extractor.close!
out.close
````

This similar example using the "original" extraction method, but specifies the location of columns. This is a useful tactic when crappy PDF creation software let one column's text flow into the next column. Unless you specify column locations manually, Tabula would combine the two columns. You can find the column locations using a screen ruler; I find it works well to measure the width of the entire PDF and scale the locations based on the width of the page as PDFBox renders it, as shown in the example below.

````ruby
require 'tabula'

pdf_file_path = "whatever.pdf"
outfilename = "whatever.csv"

out = open(outfilename, 'w')

extractor = Tabula::Extraction::ObjectExtractor.new(pdf_file_path, 1..2)
extractor.extract.each_with_index do |pdf_page, page_index|
  page_areas = [[250, 0, 325, 1700]]

  scale_factor = pdf_page.width / 1700 
  # where 1700 is the width of the page as you measured it.

  vertical_ruling_locations = [0, 360, 506, 617, 906, 1034, 1160, 1290, 1418, 1548] #column locations
  vertical_rulings = vertical_ruling_locations.map{|n| Tabula::Ruling.new(0, n * scale_factor, 0, 1000)}

  page_areas.each do |page_area|
    out << pdf_page.get_area(page_area).make_table(:vertical_rulings => vertical_rulings).to_csv
    out << "\n\n"
  end
end
extractor.close!
out.close
````

## How Does This Work? Like, Theoretically?

PDFs are a terrible format for transmitting tabular data. Tabula uses two algorithms to try to reconstruct the underlying structure of the data table. This section describes how PDFs represent your data and how Tabula extracts it so you can use `tabula-extractor` productively.

PDFs were designed to represent a paper document's layout across various computers and on paper, so they focus on precise positioning. They include primitives for text strings, geometric shapes, images and videos (and more), but no data tables. Tabula includes a Java library called PDFBox to access those embedded text strings and geometric shapes and uses them to reconstruct your table. 

<em style="margin-left: 5px;"> Why Can't Tabula Process Scanned Pages? Scanned PDF pages usually contain only one primitive: the image of the scanned page. Since those PDFs don't contain text strings or geometric shapes, Tabula won't be able to reconstruct your data -- unless you run the PDF through an OCR (Optical Character Recognition) program, which re-inserts those text strings into their original position, though the results can be error prone.</em>

Tabula has two distinct algorithms to use for different kinds of tables. It uses a heuristic to try to guess which algorithm to use for each table, but this heuristic is wrong fairly often, so you may need to specify which algorithm to use, using the Extraction Method selector buttons in the GUI or the `spreadsheet` or `no-spreadsheet` flags on the command line.

- The `spreadsheet` algorithm uses geometric lines to reconstruct the table structure. After discarding oblique lines, the algorithm finds all of the lines' crossing points. Using those crossing points, it creates a large list of minimal rectangular areas (that is, rectangles that contain no other rectangles) that are spreadsheet cells. The minimum bounding box of groups of adjacent cells is a table (called a Spreadsheet object). After spreadsheet objects are created, empty "placeholder" cells are created when a cell in one row (or, likewise, column) spans over a space in which multiple cells are contained in another row. Once we have the dimensions of all the cells on the page, the PDFBox library can get the text contained within each cell. 
- The `original` or `no-spreadsheet` algorithm uses only the position of text element on the page. (Because OCR software doesn't reconstruct lines, this algorithm is the only algorithm available for OCRed PDFs.) The algorithm collects all the text on the page (or within the area of the page that contains a table, specified with the Tabula GUI or the `--area` flag) and finds "rivers" -- vertical spaces that don't contain any text for the entire height of the table. These are considered column boundaries. (If text from one column flows into another column because the PDF was created with crappy software, you can specify it manually with the `--columns` flag ) Each line of text on the page (by unique y locations) is considered a separate line in the table. (If cells contain multiple rows, you may have to write a script to "roll them up" -- Tabula can't provide this functionality.) 

These two algorithms are inspired by some academic work, including Anssi Nurminen's "[Algorithmic Extraction of Data in Tables in Pdf Documents](http://dspace.cc.tut.fi/dpub/bitstream/handle/123456789/21520/Nurminen.pdf?sequence=3)" (2013) for the spreadsheet algorithm.

## Documentation

You're welcome to try to integrate the `tabula-extractor` gem into your project. We don't really have documentation yet, though the tests may be a good source. If you're going to, please feel free to drop us a note and we may be able to give you some pointers.
