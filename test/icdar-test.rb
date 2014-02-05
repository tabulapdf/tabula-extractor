# -*- coding: utf-8 -*-
require 'nokogiri'
require_relative '../lib/tabula'

class Table < Struct.new(:id, :filename)
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

def parse_structure_groundtruth(path)
  xml = Nokogiri::XML(File.open(path))
  filename = File.expand_path(xml.xpath('/document/@filename').to_s, File.dirname(path))
  xml.xpath('/document/table').map do |table_el|
    table = Table.new(table_el.attr('id'), filename)
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
                 bbox_el.attr('x1').to_f, bbox_el.attr('x2').to_f, bbox_el.attr('y1').to_f, bbox_el.attr('y2').to_f,
                 content_el.text)
      end
      region
    end
    table
  end
end

def parse_region_groundtruth(path)
  xml = Nokogiri::XML(File.open(path))
  filename = File.expand_path(xml.xpath('/document/@filename').to_s, File.dirname(path))
  xml.xpath('/document/table').map do |table_el|
    table = Table.new(table_el.attr('id'), filename)
    table.regions = table_el.xpath('region').map do |region_el|
      bbox_el = region_el.xpath('bounding-box').first
      Region.new(region_el.attr('id'),
                 region_el.attr('page').to_i,
                 nil, nil,
                 bbox_el.attr('x1').to_f,
                 bbox_el.attr('x2').to_f,
                 bbox_el.attr('y1').to_f,
                 bbox_el.attr('y2').to_f)
    end
    table
  end
end

def run_test(id)
  dir = id.start_with?('eu') ? 'eu-dataset' : 'us-gov-dataset'
  structure = parse_structure_groundtruth(File.expand_path(File.join('data/icdar-groundtruth', dir, id + '-str.xml'), File.dirname(__FILE__)))
  region    = parse_region_groundtruth(File.expand_path(File.join('data/icdar-groundtruth', dir, id + '-reg.xml'), File.dirname(__FILE__)))

  structure.zip(region).each do |str, reg|
    str.regions.zip(reg.regions).each do |str_reg, reg_reg|
      # need to invert y-coords
      extractor = Tabula::Extraction::ObjectExtractor.new(reg.filename)
      page = extractor.extract_page(reg_reg.page)
      extractor.close!
      puts Tabula.extract_table(reg.filename,
                                reg_reg.page,
                                [page.height - reg_reg.y1,
                                 reg_reg.x1,
                                 page.height - reg_reg.y2,
                                 reg_reg.x2]).to_csv
      puts '----------------------------------------'
    end
  end
end

run_test(ARGV.first)
