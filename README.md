tabula-extractor is DEPRECATED
==============================

[![Build Status](https://travis-ci.org/jazzido/tabula-extractor.png)](https://travis-ci.org/jazzido/tabula-extractor)

Extract tables from PDF files. `tabula-extractor` is the table extraction engine that used to power [Tabula](http://tabula.nerdpower.org), now available as a library and command line program.

If you're beginning a new project, consider using [tabula-java](http://www.github.com/tabula/tabula-java), a pure-Java version of the extraction engine behind Tabula. Since it's Java, not Ruby, it should be more compatible with more languages and stacks.

If you want Ruby bindings and are okay using JRuby (or have already begin a project), you may continue to use this project. This project's JRuby backend has been replaced with the Java backend; all that remains here is a fairly thin wrapper for Ruby compatibility. This wrapper maintains API backwards-compatibility with the old, pure-JRuby implementation we all know and love.


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

## Scripting examples

`tabula-extractor` is a RubyGem that you can use to programmatically extract tabular data, using the Tabula engine, in your scripts or applications. We don't have docs yet, but [the tests](test/tests.rb) are a good source of information.

Here's a very basic example:

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
