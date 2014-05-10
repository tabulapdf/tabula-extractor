java_import org.nerdpower.tabula.Rectangle
java_import org.nerdpower.tabula.TextChunk


##
# a "collection" of TextElements
class TextChunk
  attr_accessor :font, :font_size, :width_of_space

  def self.group_by_lines(text_chunks)
    bbwidth = text_chunks.max_by(&:right).right - text_chunks.min_by(&:left).left

    l = ::Tabula::Line.new
    l << text_chunks.first

    lines = text_chunks[1..-1].inject([l]) do |lines, te|
      if lines.last.horizontal_overlap_ratio(te) < 0.01
        # skip lines such that:
        # - are wider than the 90% of the width of the text_chunks bounding box
        # - it contains a single repeated character
        if lines.last.width / bbwidth > 0.9 \
                              && l.text_elements.all? { |te| te.text =~  ::Tabula::SAME_CHAR_RE }
          lines.pop
        end
        lines << ::Tabula::Line.new
      end
      lines.last << te
      lines
    end

    if lines.last.width / bbwidth > 0.9 \
                          && l.text_elements.all? { |te| te.text =~ ::Tabula::SAME_CHAR_RE }
      lines.pop
    end

    lines.map!(&:remove_sequential_spaces!)
  end

  ##
  # returns a list of column boundaries (x axis)
  # +lines+ must be an array of lines sorted by their +top+ attribute
  def self.column_positions(lines)
    init = lines.first.text_elements.inject([]) { |memo, text_chunk|
      next memo if text_chunk.text =~ ::Tabula::ONLY_SPACES_RE
      memo << Rectangle.new(*text_chunk.tlwh)
      memo
    }

    regions = lines[1..-1]
              .inject(init) do |column_regions, line|

      line_text_elements = line.text_elements.clone.select { |te| te.text !~ ::Tabula::ONLY_SPACES_RE }

      column_regions.each do |cr|

        overlaps = line_text_elements
                   .select { |te| te.text !~ ::Tabula::ONLY_SPACES_RE && cr.horizontally_overlaps?(te) }

        overlaps.inject(cr) do |memo, te|
          cr.merge(te)
        end

        line_text_elements = line_text_elements - overlaps
      end

      column_regions += line_text_elements.map { |te|
        Rectangle.new(*te.tlwh)
      }
    end

    regions.map { |r| r.right.round(2) }.uniq
  end

  def text
    self.text_elements.map(&:text).join
  end

  def inspect
    "#<TextChunk: #{self.top.round(2)},#{self.left.round(2)},#{self.bottom.round(2)},#{right.round(2)} '#{self.text}'>"
  end

  def to_h
    super.merge(:text => self.text)
  end
end


module Tabula
  TextChunk = org.nerdpower.tabula.TextChunk
end
