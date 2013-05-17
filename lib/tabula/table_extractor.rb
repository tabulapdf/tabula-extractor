require 'csv'

module Tabula
  class TableExtractor
    attr_accessor :text_elements, :options

    DEFAULT_OPTIONS = {
      :horizontal_rulings => [],
      :vertical_rulings => [],
      :merge_words => true,
      :split_multiline_cells => false
    }

    def initialize(text_elements, options = {})
      self.text_elements = text_elements
      self.options = DEFAULT_OPTIONS.merge(options)
      merge_words! if self.options[:merge_words]
    end

    def get_rows
      hg = self.get_line_boundaries
      hg.sort_by(&:top).map { |r| {'top' => r.top, 'bottom' => r.bottom, 'text' => r.texts} }
    end

    # TODO finish writing this method
    # it should be analogous to get_line_boundaries
    # (ie, take into account vertical ruling lines if available)
    def group_by_columns
      columns = []
      tes = self.text_elements.sort_by &:left

      # we don't have vertical rulings
      if self.options[:vertical_rulings].empty?
        tes.each do |te|
          if column = columns.detect { |c| te.horizontally_overlaps?(c) }
            column << te
          else
            columns << Column.new(te.left, te.width, [te])
          end
        end
      else
        self.options[:vertical_rulings].sort_by! &:left
        1.upto(self.options[:vertical_rulings].size - 1) do |i|
          left_ruling_line =  self.options[:vertical_rulings][i - 1]
          right_ruling_line = self.options[:vertical_rulings][i]
          columns << Column.new(left_ruling_line.left, right_ruling_line.left - left_ruling_line.left, []) if (right_ruling_line.left - left_ruling_line.left > 10)
        end
        tes.each do |te|
          if column = columns.detect { |c| te.horizontally_overlaps?(c) }
            column << te
          else
            puts "couldn't find a place for #{te.inspect}"
            #columns << Column.new(te.left, te.width, [te])
          end
        end
      end
      columns
    end

    def get_columns
      TableExtractor.new(text_elements).group_by_columns.map do |c|
        {'left' => c.left, 'right' => c.right, 'width' => c.width}
      end
    end

    def get_line_boundaries
      boundaries = []

      if self.options[:horizontal_rulings].empty?
        # we don't have rulings
        # iteratively grow boundaries to construct lines
        self.text_elements.each do |te|
          row = boundaries.detect { |l| l.vertically_overlaps?(te) }
          ze = ZoneEntity.new(te.top, te.left, te.width, te.height)
          if row.nil?
            boundaries << ze
            ze.texts << te.text
          else
            row.merge!(ze)
            row.texts << te.text
          end
        end
      else
        self.options[:horizontal_rulings].sort_by!(&:top)
        1.upto(self.options[:horizontal_rulings].size - 1) do |i|
          above = self.options[:horizontal_rulings][i - 1]
          below = self.options[:horizontal_rulings][i]

          # construct zone between a horizontal ruling and the next
          ze = ZoneEntity.new(above.top,
                              [above.left, below.left].min,
                              [above.width, below.width].max,
                              below.top - above.top)

          # skip areas shorter than some threshold
          # TODO: this should be the height of the shortest character, or something like that
          next if ze.height < 2

          boundaries << ze
        end
      end
      boundaries
    end

    private

    #this is where spaces come from!
    def merge_words!
      return self.text_elements if @merged # only merge once. awful hack.
      @merged = true
      current_word_index = i = 0
      char1 = self.text_elements[i]

      while i < self.text_elements.size-1 do

        char2 = self.text_elements[i+1]



        next if char2.nil? or char1.nil?

        if self.text_elements[current_word_index].should_merge?(char2)
          #puts "merging: #{self.text_elements[current_word_index].text}/#{self.text_elements[current_word_index].width}"
          self.text_elements[current_word_index].merge!(char2)
          char1 = char2
          self.text_elements[i+1] = nil
        else
          # is there a space? is this within `CHARACTER_DISTANCE_THRESHOLD` points of previous char?
          if (char1.text != " ") and (char2.text != " ") and self.text_elements[current_word_index].should_add_space?(char2)
            self.text_elements[current_word_index].text += " "
            #self.text_elements[current_word_index].width += self.text_elements[current_word_index].width_of_space
          end
          current_word_index = i+1
        end
        i += 1
      end
      self.text_elements.compact!
      return self.text_elements
    end
  end

  # TODO next four module methods are deprecated
  def Tabula.group_by_columns(text_elements, merge_words=false)
    TableExtractor.new(text_elements, :merge_words => merge_words).group_by_columns
  end

  def Tabula.get_line_boundaries(text_elements)
    TableExtractor.new(text_elements).get_line_boundaries
  end

  def Tabula.get_columns(text_elements, merge_words=true)
    TableExtractor.new(text_elements, :merge_words => merge_words).get_columns
  end

  def Tabula.get_rows(text_elements, merge_words=true)
    TableExtractor.new(text_elements, :merge_words => merge_words).get_rows
  end

  def Tabula.lines_to_csv(lines)
    CSV.generate do |csv|
      lines.each do |l|
        csv << l.map { |c| c.text.strip }
      end
    end
  end

  ONLY_SPACES_RE = Regexp.new('^\s+$')

  # Returns an array of Tabula::Line
  def Tabula.make_table(text_elements, options={})
    extractor = TableExtractor.new(text_elements, options)

    # group by lines
    lines = []
    line_boundaries = extractor.get_line_boundaries

    # find all the text elements
    # contained within each detected line (table row) boundary
    line_boundaries.each do |lb|
      line = Line.new

      line_members = text_elements.find_all do |te|
        te.vertically_overlaps?(lb)
      end

      text_elements -= line_members

      line_members.sort_by(&:left).each do |te|
        # skip text_elements that only contain spaces
        next if te.text =~ ONLY_SPACES_RE
        line << te
      end

      lines << line if line.text_elements.size > 0
    end

    lines.sort_by!(&:top)

    columns = TableExtractor.new(lines.map(&:text_elements).flatten.compact.uniq, {:merge_words => options[:merge_words]}).group_by_columns.sort_by(&:left)

    # # insert empty cells if needed
    lines.each_with_index do |l, line_index|
      next if l.text_elements.nil?
      l.text_elements.compact! # TODO WHY do I have to do this?
      l.text_elements.uniq!  # TODO WHY do I have to do this?
      l.text_elements.sort_by!(&:left)

      next unless l.text_elements.size < columns.size

      columns.each_with_index do |c, i|
        if (i > l.text_elements.size - 1) or !l.text_elements(&:left)[i].nil? and !c.text_elements.include?(l.text_elements[i])
          l.text_elements.insert(i, TextElement.new(l.top, c.left, c.width, l.height, nil, 0, '', 0))
        end
      end
    end

    # # merge elements that are in the same column
    lines.each_with_index do |l, line_index|
      next if l.text_elements.nil?

      (0..l.text_elements.size-1).to_a.combination(2).each do |t1, t2|
        next if l.text_elements[t1].nil? or l.text_elements[t2].nil?

        # if same column...
        if columns.detect { |c| c.text_elements.include? l.text_elements[t1] } \
          == columns.detect { |c| c.text_elements.include? l.text_elements[t2] }
          if l.text_elements[t1].bottom <= l.text_elements[t2].bottom
            l.text_elements[t1].merge!(l.text_elements[t2])
            l.text_elements[t2] = nil
          else
            l.text_elements[t2].merge!(l.text_elements[t1])
            l.text_elements[t1] = nil
          end
        end
      end

      l.text_elements.compact!
    end

    # remove duplicate lines
    # TODO this shouldn't have happened here, check why we have to do
    # this (maybe duplication is happening in the column merging phase?)
    (0..lines.size - 2).each do |i|
      next if lines[i].nil?
      # if any of the elements on the next line is duplicated, kill
      # the next line
      if (0..lines[i].text_elements.size-1).any? { |j| lines[i].text_elements[j] == lines[i+1].text_elements[j] }
        lines[i+1] = nil
      end
    end

    lines.compact.map do |line|
      line.text_elements.sort_by(&:left)
    end
  end


  def Tabula.make_table_with_vertical_rulings(text_elements, options={})
    extractor = TableExtractor.new(text_elements, options)

    # group by lines
    lines = []
    line_boundaries = extractor.get_line_boundaries

    # find all the text elements
    # contained within each detected line (table row) boundary
    line_boundaries.each do |lb|
      line = Line.new

      line_members = text_elements.find_all do |te|
        te.vertically_overlaps?(lb)
      end

      text_elements -= line_members

      line_members.sort_by(&:left).each do |te|
        # skip text_elements that only contain spaces
        next if te.text =~ ONLY_SPACES_RE
        line << te
      end

      lines << line if line.text_elements.size > 0
    end

    lines.sort_by!(&:top)

    vertical_rulings = options[:vertical_rulings]
    columns = TableExtractor.new(lines.map(&:text_elements).flatten.compact.uniq, {:merge_words => options[:merge_words], :vertical_rulings => vertical_rulings}).group_by_columns.sort_by(&:left)

    # insert empty cells if needed
    lines.each_with_index do |l, line_index|
      next if l.text_elements.nil?
      l.text_elements.compact! # TODO WHY do I have to do this?
      l.text_elements.uniq!  # TODO WHY do I have to do this?
      l.text_elements.sort_by!(&:left)

      columns.each_with_index do |c, i|
        if (l.text_elements.select{|te| te && te.left >= c.left && te.right <= (c.left + c.width)}.empty?)
          l.text_elements.insert(i, TextElement.new(l.top, c.left, c.width, l.height, nil, 0, '', 0))
        end
      end
    end

    # merge elements that are in the same column
    lines.each_with_index do |l, line_index|
      next if l.text_elements.nil?

      (0..l.text_elements.size-1).to_a.combination(2).each do |t1, t2|  #don't remove a string of empty cells
        next if l.text_elements[t1].nil? or l.text_elements[t2].nil?    or l.text_elements[t1].text.empty? or l.text_elements[t2].text.empty?

        # if same column...
        if columns.detect { |c| c.text_elements.include? l.text_elements[t1] } \
          == columns.detect { |c| c.text_elements.include? l.text_elements[t2] }
          if l.text_elements[t1].bottom <= l.text_elements[t2].bottom
            l.text_elements[t1].merge!(l.text_elements[t2])
            l.text_elements[t2] = nil
          else
            l.text_elements[t2].merge!(l.text_elements[t1])
            l.text_elements[t1] = nil
          end
        end
      end

      l.text_elements.compact!
    end

    # remove duplicate lines
    # TODO this shouldn't have happened here, check why we have to do
    # this (maybe duplication is happening in the column merging phase?)
    (0..lines.size - 2).each do |i|
      next if lines[i].nil?
      # if any of the elements on the next line is duplicated, kill
      # the next line
      if (0..lines[i].text_elements.size-1).any? { |j| lines[i].text_elements[j] == lines[i+1].text_elements[j] }
        lines[i+1] = nil
      end
    end

    lines.compact.map do |line|
      line.text_elements.sort_by(&:left)
    end
  end





end
