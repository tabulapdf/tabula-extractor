java_import org.nerdpower.tabula.Rectangle
module Tabula
  # extract a table from file +pdf_path+, +pages+ and +area+
  #
  # +pages+ can be a single integer (1-based) or an array of integers
  #
  # ==== Options
  # +:password+ - Password if encrypted PDF (default: empty)
  # +:detect_ruling_lines+ - Try to detect vertical (default: true)
  # +:vertical_rulings+ - List of positions for vertical rulings. Overrides +:detect_ruling_lines+. (default: [])
  def Tabula.extract_table(pdf_path, page, area, options={})
    options = {
      :password => '',
      :detect_ruling_lines => true,
      :vertical_rulings => [],
      :extraction_method => "guess",
    }.merge(options)

    if area.instance_of?(Array)
      top, left, bottom, right = area
      area = Rectangle.new(top.to_java(:double), left.to_java(:double),
                           (right - left).to_java(:double), (bottom - top).to_java(:double))
    end

    if page.is_a?(Integer)
      page = [page]
    end

    extractor = Extraction::ObjectExtractor.new(pdf_path,
                                                page,
                                                options[:password])

    pdf_page = extractor.extract.next
    extractor.close!

    if ["spreadsheet", "original"].include? options[:extraction_method]
      use_spreadsheet_extraction_method = options[:extraction_method] == "spreadsheet"
    else
      use_spreadsheet_extraction_method = pdf_page.is_tabular?
    end

    if use_spreadsheet_extraction_method
      return (spreadsheets = pdf_page.get_area(area).spreadsheets).empty? ? Spreadsheet.empty(pdf_page) : spreadsheets.inject(&:+)
    end

    use_detected_lines = false
    if options[:detect_ruling_lines] && options[:vertical_rulings].empty?

      detected_vertical_rulings = Ruling.crop_rulings_to_area(pdf_page.vertical_ruling_lines,
                                                              area)

      # only use lines if at least 80% of them cover at least 90%
      # of the height of area of interest

      # TODO this heuristic SUCKS
      # what if only a couple columns is delimited with vertical rulings?
      # ie: https://www.dropbox.com/s/lpydler5c3pn408/S2MNCEbirdisland.pdf (see 7th column)
      # idea: detect columns without considering rulings, detect vertical rulings
      # calculate ratio and try to come up with a threshold
      use_detected_lines = detected_vertical_rulings.size > 2 \
      && (detected_vertical_rulings.count { |vl|
            vl.height / area.height > 0.9
          } / detected_vertical_rulings.size.to_f) >= 0.8

    end

    pdf_page
      .get_area(area)
      .get_table(:vertical_rulings => use_detected_lines ? detected_vertical_rulings : options[:vertical_rulings])

  end
end
