module Tabula

  $FOO = false

  def Tabula.merge_words(text_elements, options={})
    default_options = {:vertical_rulings => []}
    options = default_options.merge(options)
    vertical_ruling_locations = options[:vertical_rulings].map(&:left) if options[:vertical_rulings]

    return [] if text_elements.empty?

    text_chunks = [TextChunk.create_from_text_element(text_elements.shift)]

    text_elements.inject(text_chunks) do |chunks, char|
      current_chunk = chunks.last
      prev_char = current_chunk.text_elements.last

      # any vertical ruling goes across prev_char and char?
      across_vertical_ruling = vertical_ruling_locations.any? { |loc|
        prev_char.left < loc && char.left > loc
      }

      # if current_chunk.text =~ /500$/
      #   $FOO = true
      # end
      # if $FOO
      #   puts '--------'
      #   puts "vertical_ruling_locations: #{vertical_ruling_locations.inspect}"
      #   puts "prev_char: #{prev_char.text} - left: #{prev_char.left}"
      #   puts "char: #{char.text} - left: #{char.left}"
      #   puts "current_chunk: #{current_chunk.text} - left: #{current_chunk.left}"
      # end

      # should we add a space?
      if (prev_char.text != " ") && (char.text != " ") \
        && !across_vertical_ruling \
        && prev_char.should_add_space?(char)

        sp = TextElement.new(prev_char.top,
                             prev_char.right,
                             prev_char.width_of_space,
                             prev_char.width_of_space, # width == height for spaces
                             prev_char.font,
                             prev_char.font_size,
                             ' ',
                             prev_char.width_of_space)
        chunks.last << sp
        prev_char = sp
      end

      # should_merge? isn't aware of vertical rulings, so even if two text elements are close enough
      # that they ought to be merged by that account.
      # we still shouldn't merge them if the two elements are on opposite sides of a vertical ruling.
      # Why are both of those `.left`?, you might ask. The intuition is that a letter
      # that starts on the left of a vertical ruling ought to remain on the left of it.
      if !across_vertical_ruling && prev_char.should_merge?(char)
        chunks.last << char
      else
        # create a new chunk
        chunks << TextChunk.create_from_text_element(char)
      end
      chunks
    end

  end

  ONLY_SPACES_RE = Regexp.new('^\s+$')

  def Tabula.group_by_lines(text_elements)
    lines = []
    text_elements.each do |te|
      next if te.text =~ ONLY_SPACES_RE
      l = lines.find { |line| line.horizontal_overlap_ratio(te) >= 0.01 }
      if l.nil?
        l = Line.new
        lines << l
      end
      l << te
    end
    lines
  end

  # Returns an array of Tabula::Line
  def Tabula.make_table(text_elements, options={})
    default_options = {:vertical_rulings => []}
    options = default_options.merge(options)

    if text_elements.empty?
      return []
    end

    text_chunks = merge_words(text_elements.uniq, options).sort

    lines = group_by_lines(text_chunks)

    top = lines[0].text_elements.map(&:top).min
    right = 0
    columns = []

    unless options[:vertical_rulings].empty?
      columns = options[:vertical_rulings].map(&:left) #pixel locations, not entities
      separators = columns.sort.reverse
    else
      text_chunks.each do |te|
        next if te.text =~ ONLY_SPACES_RE
        if te.top >= top
          left = te.left
          if (left > right)
            columns << right
            right = te.right
          elsif te.right > right
            right = te.right
          end
        end
      end
      separators = columns[1..-1].sort.reverse
    end

    table = Table.new(lines.count, separators)
    lines.each_with_index do |line, i|
      line.text_elements.each do |te|
        j = separators.find_index { |s| te.left > s } || separators.count
        table.add_text_element(te, i, separators.count - j)
      end
    end

    table.lstrip_lines!

    table.lines.map do |l|
      l.text_elements.map! do |te|
        te || TextElement.new(nil, nil, nil, nil, nil, nil, '', nil)
      end
    end.sort_by { |l| l.map { |te| te.top or 0 }.max }
  end

  # extract a table from file +pdf_path+, +page+ and +area+
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

    text_elements = Extraction::ObjectExtractor.new(pdf_path,
                                                       [page],
                                                       options[:password]) \
      .extract.next.get_text(area)

    use_detected_lines = false
    if options[:detect_ruling_lines] && options[:vertical_rulings].empty?
      detected_vertical_rulings = Extraction::LineExtractor.lines_in_pdf_page(pdf_path, page-1).
          find_all(&:vertical?)

      # crop lines to area of interest
      detected_vertical_rulings = Ruling.crop_rulings_to_area(detected_vertical_rulings, area)

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

    make_table(text_elements,
               :vertical_rulings => use_detected_lines ? detected_vertical_rulings : options[:vertical_rulings])


  end
end
