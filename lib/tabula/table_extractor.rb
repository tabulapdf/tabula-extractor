require 'csv'

module Tabula

  def Tabula.merge_words(text_elements, options={})
    default_options = {:vertical_rulings => []}
    options = default_options.merge(options)

    current_word_index = i = 0
    char1 = text_elements[i]
    vertical_ruling_locations = options[:vertical_rulings].map(&:left) if options[:vertical_rulings]
    while i < text_elements.size-1 do

      char2 = text_elements[i+1]

      next if char2.nil? or char1.nil?

      # should_merge? isn't aware of vertical rulings, so even if two text elements are close enough
      # that they ought to be merged by that account.
      # we still shouldn't merge them if the two elements are on opposite sides of a vertical ruling.
      # Why are both of those `.left`?, you might ask. The intuition is that a letter
      # that starts on the left of a vertical ruling ought to remain on the left of it.
      if text_elements[current_word_index].should_merge?(char2) \
        && !(options[:vertical_rulings] \
             && vertical_ruling_locations.map{ |loc|
               text_elements[current_word_index].left < loc && char2.left > loc
             }.include?(true))
        text_elements[current_word_index].merge!(char2)

        char1 = char2
        text_elements[i+1] = nil
      else
        # is there a space? is this within `CHARACTER_DISTANCE_THRESHOLD` points of previous char?
        if (char1.text != " ") and (char2.text != " ") and text_elements[current_word_index].should_add_space?(char2)
          text_elements[current_word_index].text  += " "
          text_elements[current_word_index].width += text_elements[current_word_index].width_of_space
        end
        current_word_index = i+1
      end
      i += 1
    end
    text_elements.compact!
    return text_elements
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

    text_elements = merge_words(text_elements).sort

    lines = group_by_lines(text_elements)

    top = lines[0].text_elements.map(&:top).min
    right = 0
    columns = []

    #text_elements.sort_by(&:left).each do |te|
    text_elements.each do |te|
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
