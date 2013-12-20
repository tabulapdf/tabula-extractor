module Tabula

  $FOO = false

  def Tabula.merge_words(text_elements, options={})
    warn 'Tabula.merge_words is DEPRECATED. Use Tabula::TextElement.merge_words instead'
    TextElement.merge_words(text_elements, options)
  end

  def Tabula.group_by_lines(text_chunks)
    warn 'Tabula.group_by_lines is DEPRECATED. Use Tabula::TextChunk.group_by_lines instead.'
    TextChunk.group_by_lines(text_chunks)
  end

  # Returns an array of Tabula::Line
  def Tabula.make_table(page, area, options={})
    warn 'Tabula.make_table is DEPRECATED. Use Tabula::Page#make_table instead.'
    page.make_table(area, options)
  end

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
      :vertical_rulings => []
    }.merge(options)

    if area.instance_of?(Array)
      top, left, bottom, right = area
      area = Tabula::ZoneEntity.new(top, left,
                                    right - left, bottom - top)
    end

    if page.is_a?(Integer)
      page = [page]
    end

    page_obj = Extraction::ObjectExtractor.new(pdf_path,
                                               page,
                                               options[:password]) \
      .extract.next

    use_detected_lines = false
    if options[:detect_ruling_lines] && options[:vertical_rulings].empty?
      detected_vertical_rulings = Ruling.crop_rulings_to_area(page_obj.vertical_ruling_lines,
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

    page_obj.make_table(area,
                        :vertical_rulings => use_detected_lines ? detected_vertical_rulings : options[:vertical_rulings])


  end
end
