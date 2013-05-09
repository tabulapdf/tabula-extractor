tabula-extractor
================

Extract tables from PDF files

## Usage

```
$ tabula --help
Tabula helps you extract tables from PDFs

Usage:
       tabula [options] <pdf_file>
where [options] are:
     --page, -p <i>:   Page number (default: 1)
     --area, -a <s>:   Portion of the page to analyze (top, left, bottom,
                       right). Example: --area 269.875, 12.75, 790.5, 561.
                       Default is entire page
   --format, -f <s>:   Output format (CSV,TSV,HTML,JSON) (default: CSV)
  --outfile, -o <s>:   Write output to <file> instead of STDOUT (default: -)
      --version, -v:   Print version and exit
         --help, -h:   Show this message
```

