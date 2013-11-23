require 'csv'

module Tabula

  def Tabula.merge_words(text_elements, options={})
    default_options = {:vertical_rulings => []}
    options = default_options.merge(options)

    text_chunks = [TextChunk.create_from_text_element(text_elements.first)]

    vertical_ruling_locations = options[:vertical_rulings].map(&:left) if options[:vertical_rulings]
    text_elements[1..-1].inject(text_chunks) do |chunks, char|
      current_chunk = chunks.last
      prev_char = current_chunk.text_elements.last

      # should we add a space?
      if (prev_char.text != " ") and (char.text != " ") and prev_char.should_add_space?(char)
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
      if prev_char.should_merge?(char) \
        && !(options[:vertical_rulings] \
             && vertical_ruling_locations.any? { |loc|
               current_chunk.left < loc && char.left > loc
             })

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
    default_options = {:separators => [], :vertical_rulings => []}
    options = default_options.merge(options)

    if text_elements.empty?
      return []
    end

    text_chunks = merge_words(text_elements).sort

    lines = group_by_lines(text_chunks)

    top = lines[0].text_elements.map(&:top).min
    right = 0
    columns = []

    text_chunks.each do |te|
      next if te.text =~ ONLY_SPACES_RE
      if te.top >= top
        left = te.left
        if (left > right)
          columns << right if options[:vertical_rulings].empty?
          right = te.right
        elsif te.right > right
          right = te.right
        end
      end
    end

    unless options[:vertical_rulings].empty?
      columns = options[:vertical_rulings].map(&:left) #pixel locations, not entities
    end

    separators = columns[1..-1].sort.reverse

    table = Table.new(lines.count, separators)
    lines.each_with_index do |line, i|
      line.text_elements.each do |te|
        j = separators.find_index { |s| te.left > s } || separators.count
        table.add_text_element(te, i, separators.count - j)
      end
    end

    table.lines.map do |l|
      l.text_elements.map! do |te|
        te.nil? ? TextElement.new(nil, nil, nil, nil, nil, nil, '', nil) : te
      end
    end.sort_by { |l| l.map { |te| te.top or 0 }.max }

  end
end
