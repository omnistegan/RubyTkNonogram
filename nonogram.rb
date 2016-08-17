#!/bin/env ruby-2.1
require 'tk'
require './parse_puzzle.rb'

puzzle = parse_puzzle('15776.xml')

class Block
	attr_reader(:coords, :colour, :active)
	attr_accessor(:tkrec)

	def initialize(canvas, x, y)
		@coords = {x: x, y: y}
		@colour = :white
    @active = false

    @canvas = canvas
		@tkrec = nil
    @marked_x = []
	end

  def colour_swap
    if @colour == :white
      @colour = :black
    elsif @colour == :black
      @colour = :white
    elsif @colour == :mark
      @colour = :white
    end
    update_view()
  end

  def toggle_x
    if colour == :mark
      colour_swap
    else
      @colour = :mark
      update_view()
    end
  end

  def draw_self(scale)
    x1 = @coords[:x]*scale
    y1 = @coords[:y]*scale
    @tkrec = TkcRectangle.new(@canvas, x1, y1, x1+scale, y1+scale)
    @tkrec.fill(@colour.to_s).outline('#aaaaaa')
    @tkrec.bind("ButtonPress-1", proc {colour_swap()} )
    @tkrec.bind("ButtonPress-3", proc {toggle_x()})
  end

  def update_view
    if @colour == :mark
      @tkrec.fill('white')
      @marked_x << TkcLine.new(@canvas, @tkrec.coords[0], @tkrec.coords[1], @tkrec.coords[2], @tkrec.coords[3], { 'width' => 2 })
      @marked_x << TkcLine.new(@canvas, @tkrec.coords[2], @tkrec.coords[1], @tkrec.coords[0], @tkrec.coords[3], { 'width' => 2 })
      @marked_x.map { |line| line.bind("ButtonPress-3", proc {colour_swap()}) }
      @marked_x.map { |line| line.bind("ButtonPress-1", proc {colour_swap()}) }
    else
      if !@marked_x.empty?
        @marked_x.each { |line| line.remove }
        @marked_x = []
      end
      @tkrec.fill(@colour.to_s)
    end
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

class Board

  def initialize(root, puzzle, scale)
    @width = puzzle["columns"].length
    @height = puzzle["rows"].length

    @scale = 20
    @widthpx = @width*scale
    @heightpx = @height*scale

    @canvas = TkCanvas.new(root,
                          bg: "#ffffff",
                          height: @heightpx,
                          width: @widthpx) { grid(:row => 1, :column => 1)}

    @blocks = blocks_init()
    @active_block = @blocks.find {|b| b.coords == {x: 0, y: 0}}
    @active_lines = []

    @canvas.bind('Motion', proc {|x, y| draw_active(block_from_pos(x, y))}, "%x %y")
    @canvas.bind('Leave', proc {remove_active()})

    root.bind('l', proc do
      draw_active(@blocks.find do |b|
        b.coords == {x: @active_block.coords[:x]+1, y: @active_block.coords[:y]}
      end)
    end)
    root.bind('h', proc do
      draw_active(@blocks.find do |b|
        b.coords == {x: @active_block.coords[:x]-1, y: @active_block.coords[:y]}
      end)
    end)
    root.bind('k', proc do
      draw_active(@blocks.find do |b|
        b.coords == {x: @active_block.coords[:x], y: @active_block.coords[:y]-1}
      end)
    end)
    root.bind('j', proc do
      draw_active(@blocks.find do |b|
        b.coords == {x: @active_block.coords[:x], y: @active_block.coords[:y]+1}
      end)
    end)
    root.bind('c', proc { @active_block.colour_swap })
    root.bind('x', proc { @active_block.toggle_x })

    draw_blocks()
    draw_guides()
    draw_active(@active_block)
  end

  def blocks_init
    blocks = []
    (0...@width).each do |x|
      (0...@height).each do |y|
        blocks << Block.new(@canvas, x, y)
      end
    end
    blocks
  end

  def floor_to(number, step)
    whole, _ = number.divmod(step)
    whole * step
  end

  def block_from_pos(x, y)
    x = floor_to(x, @scale)/@scale
    y = floor_to(y, @scale)/@scale
    @blocks.find {|b| b.coords == {x: x, y: y}}
  end

  def draw_blocks
    @blocks.each { |block| block.draw_self(@scale) }
  end

  def draw_guides
    (0..@canvas.width).step(@scale*5) do |x|
      TkcLine.new(@canvas, x, 0, x, @canvas.height, {'width' => '2', 'fill' => '#aaaaaa'})
    end
    (0..@canvas.height).step(@scale*5) do |x|
      TkcLine.new(@canvas, 0, x, @canvas.width, x, {'width' => '2', 'fill' => '#aaaaaa'})
    end
  end

  def draw_active(block)
    if block != @active_block
      if block
        @active_block = block
        block_coords = block.tkrec.coords
        @active_lines.each {|line| line.remove}
        @active_lines = []
        @active_lines << TkcLine.new(@canvas, block_coords[0], 0, block_coords[0], @canvas.height, {'width' => 1, 'fill' => 'red'})
        @active_lines << TkcLine.new(@canvas, block_coords[2], 0, block_coords[2], @canvas.height, {'width' => 1, 'fill' => 'red'})
        @active_lines << TkcLine.new(@canvas, 0, block_coords[1], @canvas.width, block_coords[1], {'width' => 1, 'fill' => 'red'})
        @active_lines << TkcLine.new(@canvas, 0, block_coords[3], @canvas.width, block_coords[3], {'width' => 1, 'fill' => 'red'})
      end
    end
  end

  def remove_active
    @active_lines.each {|line| line.remove}
    @active_lines = []
  end

end

def main(puzzle)

  width = puzzle["columns"].length
  height = puzzle["rows"].length
  scale = 20
  widthpx = width*scale
  heightpx = height*scale

	root = TkRoot.new(bg: "#222222") { title "Nonogram" }

  left_edge = TkCanvas.new(root,
                           bg: "#aaaaaa",
                           height: heightpx,
                           width: (scale*5)) { grid(:row => 1, :column => 0)}
  top_edge = TkCanvas.new(root,
                          bg: "#aaaaaa",
                          height: (scale*5),
                          width: widthpx) { grid(:row => 0, :column => 1)}

  board = Board.new(root, puzzle, scale)

  draw_clues(puzzle, left_edge, top_edge, scale)

	Tk.mainloop

end

main(puzzle)
