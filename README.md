tabula-extractor
================

[![Build Status](https://travis-ci.org/jazzido/tabula-extractor.png)](https://travis-ci.org/jazzido/tabula-extractor)

Extract tables from PDF files. `tabula-extractor` is the table extraction engine that powers [Tabula](http://tabula.nerdpower.org), now available as a library and command line program.

## Installation

At the moment, `tabula-extractor` only works with JRuby. [Install JRuby](http://jruby.org/getting-started) and run

``
jruby -S gem install tabula-extractor
``


## Usage

```
Tabula helps you extract tables from PDFs

Usage:
       tabula [options] <pdf_file>
where [options] are:
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
                          Slow.
           --debug, -d:   Print detected table areas instead of processing.
      --format, -f <s>:   Output format (CSV,TSV,HTML,JSON) (default: CSV)
     --outfile, -o <s>:   Write output to <file> instead of STDOUT (default: -)
     --spreadsheet, -r:   Force PDF to be extracted using spreadsheet-style
                          extraction (if there are ruling lines separating each
                          cell, as in a PDF of an Excel spreadsheet)
  --no-spreadsheet, -n:   Force PDF not to be extracted using spreadsheet-style
                          extraction (if there are ruling lines separating each
                          cell, as in a PDF of an Excel spreadsheet)
         --version, -v:   Print version and exit
            --help, -h:   Show this message
```

## Scripting examples

`tabula-extractor` is a RubyGem that you can use to programmatically extract tabular data, using the Tabula engine, in your scripts or applications. We don't have docs yet, but [the tests](test/tests.rb) are a good source of information.

## Notes

`tabula-extractor` uses [LSD: a Line Segment Detector](http://www.ipol.im/pub/art/2012/gjmr-lsd/) by Rafael Grompone von Gioi, Jérémie Jakubowicz, Jean-Michel Morel and Gregory Randall.
