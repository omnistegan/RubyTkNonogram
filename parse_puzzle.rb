#!/usr/bin/env ruby
require 'xmlsimple'

def parse_puzzle(xml)
  puzzle_xml = XmlSimple.xml_in(xml, { 'KeyAttr' => 'name' })

  first = []
  second = []

  puzzle_xml["puzzle"][0]["clues"][0]["line"].each do |line|
    counts = []
    line["count"].each do |x|
      if x.class == Hash
        counts << x["content"].to_i
      else
        counts << x.to_i
      end
    end unless !line["count"]
    first << counts
  end

  puzzle_xml["puzzle"][0]["clues"][1]["line"].each do |line|
    counts = []
    line["count"].each do |x|
      if x.class == Hash
        counts << x["content"].to_i
      else
        counts << x.to_i
      end
    end unless !line["count"]
    second << counts
  end

  { puzzle_xml["puzzle"][0]["clues"][0]["type"].to_sym => first,
    puzzle_xml["puzzle"][0]["clues"][1]["type"].to_sym => second,
    :metadata => { :title => puzzle_xml["puzzle"][0]["title"][0],
                   :author => puzzle_xml["puzzle"][0]["author"][0],
                   :copyright => puzzle_xml["puzzle"][0]["copyright"][0],
                   :id => puzzle_xml["puzzle"][0]["id"][0],
                   :description => puzzle_xml["puzzle"][0]["description"][0] },
    :colors => puzzle_xml["puzzle"][0]["color"].length}
end
