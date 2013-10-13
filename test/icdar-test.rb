# -*- coding: utf-8 -*-
require 'nokogiri'

class Table < Struct.new(:id)
  attr_accessor :regions
end
class Region < Struct.new(:id,
                          :page,
                          :col_increment, :row_increment,
                          :x1, :x2, :y1, :y2)
  attr_accessor :cells

end


class Cell < Struct.new(:id,
                        :start_col, :end_col,
                        :start_row, :end_row,
                        :x1, :x2, :y1, :y2,
                        :content)

  def end_col
    self[:end_col] || self[:start_col]
  end

  def end_row
    self[:end_row] || self[:start_row]
  end

end

require_relative '../lib/tabula'

def parse_structure_groundtruth(path)
  xml = Nokogiri::XML(File.open(path))
  xml.xpath('/document/table').map do |table_el|
    table = Table.new(table_el.attr('id'))
    table.regions = table_el.xpath('region').map do |region_el|

      region = Region.new(region_el.attr('id'),
                          region_el.attr('page').to_i,
                          region_el.attr('col-increment').to_i,
                          region_el.attr('row-increment').to_i)

      region.cells = region_el.xpath('cell').map do |cell_el|

        bbox_el = cell_el.xpath('bounding-box').first
        content_el = cell_el.xpath('content')

        Cell.new(cell_el.attr('id'),
                 cell_el.attr('start-col').to_i, cell_el.attr('end-col').to_i,
                 cell_el.attr('start-row').to_i, cell_el.attr('end-row').to_i,
                 bbox_el.attr('x1').to_i, bbox_el.attr('x2').to_i, bbox_el.attr('y1').to_i, bbox_el.attr('y2').to_i,
                 content_el.text)
      end
    end
    table
  end
end

def parse_region_groundtruth(path)
  xml = Nokogiri::XML(File.open(path))
  xml.xpath('/document/table').map do |table_el|
    table = Table.new(table_el.attr('id'))
    table.regions = table_el.xpath('region').map do |region_el|
      bbox_el = region_el.xpath('bounding-box').first
      Region.new(region_el.attr('id'),
                 region_el.attr('page').to_i,
                 nil, nil,
                 bbox_el.attr('x1').to_i, bbox_el.attr('x2').to_i, bbox_el.attr('y1').to_i, bbox_el.attr('y2').to_i)
    end
    table
  end

end


#puts parse_structure_groundtruth('/Users/manuel/Work/tabula/tabula-extractor/test/data/icdar-groundtruth/eu-dataset/eu-001-str.xml').inspect
puts parse_region_groundtruth('/Users/manuel/Work/tabula/tabula-extractor/test/data/icdar-groundtruth/eu-dataset/eu-001-reg.xml').first.regions.inspect
