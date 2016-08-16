#!/usr/bin/env ruby
require 'xmlsimple'

def parse_puzzle(xml)
  puzzle_xml = XmlSimple.xml_in(xml, { 'KeyAttr' => 'name' })

  first = []
  second = []

  puzzle_xml["puzzle"][0]["clues"][0]["line"].each do |line|
    counts = []
    line["count"].each { |x| counts << x.to_i }
    first << counts
  end

  puzzle_xml["puzzle"][0]["clues"][1]["line"].each do |line|
    counts = []
    line["count"].each { |x| counts << x.to_i }
    second << counts
  end

  { puzzle_xml["puzzle"][0]["clues"][0]["type"].to_s => first,
    puzzle_xml["puzzle"][0]["clues"][1]["type"].to_s => second}
end

puzzle = parse_puzzle('webpbn004495.xml')
