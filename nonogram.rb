#!/bin/env ruby-2.1
require 'tk'
require './parse_puzzle.rb'

puzzle = parse_puzzle('webpbn000915.xml')

class Block
	attr_reader(:coords, :colour, :active)
	attr_accessor(:tkrec)

	def initialize(x, y)
		@coords = {x: x, y: y}
    @marked_x = []
		@colour = :white
		@tkrec = nil
	end

  def colour_swap
    if @colour == :white
      @tkrec.fill('black')
      @colour = :black
    else
      @tkrec.fill('white')
      @colour = :white
    end
  end

  def toggle_x(canvas)
    if @marked_x.empty?
      @tkrec.fill('white')
      @colour = :white
      @marked_x << TkcLine.new(canvas, @tkrec.coords[0], @tkrec.coords[1], @tkrec.coords[2], @tkrec.coords[3], { 'width' => 2 })
      @marked_x << TkcLine.new(canvas, @tkrec.coords[2], @tkrec.coords[1], @tkrec.coords[0], @tkrec.coords[3], { 'width' => 2 })
      @marked_x.map { |line| line.bind("ButtonPress-3", proc {toggle_x(canvas)}) }
      @marked_x.map { |line| line.bind("ButtonPress-1", proc do
        colour_swap
        toggle_x(canvas)
      end) }
    else
      @marked_x.map { |line| line.remove }
      @marked_x = []
    end
  end

end

def blocks_init(width, height)
	blocks = []
	(0..width).each do |x|
		(0..height).each do |y|
			blocks << Block.new(x, y)
		end
	end
	blocks
end

def draw_blocks(blocks, canvas, scale)
	blocks.each do |block|
		x1 = block.coords[:x]*scale
		y1 = block.coords[:y]*scale
    block.tkrec = TkcRectangle.new(canvas, x1, y1, x1+scale, y1+scale)
    block.tkrec.fill(block.colour.to_s).outline('black')
    block.tkrec.bind("ButtonPress-1", proc {block.colour_swap} )
    block.tkrec.bind("ButtonPress-3", proc {block.toggle_x(canvas)})
	end
end

def draw_guides(canvas, scale)
  (0..canvas.width).step(scale*5) do |x|
    TkcLine.new(canvas, x, 0, x, canvas.height, {'width' => '2', 'fill' => 'black'})
  end
  (0..canvas.height).step(scale*5) do |x|
    TkcLine.new(canvas, 0, x, canvas.width, x, {'width' => '2', 'fill' => 'black'})
  end
end


def draw_clues(puzzle, left_edge, top_edge, scale)
  puzzle["rows"].each_with_index do |row, r|
    row.reverse.each_with_index do |clue, i|
      TkcText.create(left_edge,
                     left_edge.width-(((i+1)*scale)-(scale/2)),
                     ((r+1)*scale)-(scale/2),
                     {'text' => clue})
    end
  end
  puzzle["columns"].each_with_index do |column, c|
    column.reverse.each_with_index do |clue, i|
      TkcText.create(top_edge,
                     (((c+1)*scale)-(scale/2)),
                     top_edge.height-(((i+1)*scale)-(scale/2)),
                     {'text' => clue})
    end
  end
end

def main(puzzle)
	width = puzzle["columns"].length
	height = puzzle["rows"].length
	scale = 20
	widthpx = width*scale
	heightpx = height*scale

	root = TkRoot.new(bg: "#222222") { title "Nonogram" }
	canvas = TkCanvas.new(root,
                        bg: "#ffffff",
                        height: heightpx,
                        width: widthpx) { grid(:row => 1, :column => 1)}

  left_edge = TkCanvas.new(root,
                           bg: "#aaaaaa",
                           height: heightpx,
                           width: (scale*5)) { grid(:row => 1, :column => 0)}
  top_edge = TkCanvas.new(root,
                          bg: "#aaaaaa",
                          height: (scale*5),
                          width: widthpx) { grid(:row => 0, :column => 1)}

	blocks = blocks_init(width, height)
	draw_blocks(blocks, canvas, scale)
  draw_guides(canvas, scale)
  draw_clues(puzzle, left_edge, top_edge, scale)

	Tk.mainloop

end

main(puzzle)
