#!/bin/env ruby
require 'tk'
require './parse_puzzle.rb'

class Block
  attr_reader(:coords, :color)
  attr_accessor(:selected)

  # Init a Block
  def initialize(x, y, color)
    @coords = {x: x, y: y}
    @color = color
    @selected = false
  end

  # Change the colour
  def color_cycle(colors)
    if @color != :mark
      @color = colors[colors.find_index(@color)-1]
    else
      @color = colors[0]
    end
  end

  # If not marked, mark it
  def set_marked
    if @color != :mark
      @color = :mark
    end
  end
end

class Board
  attr_reader(:width, :height, :clues, :colors, :blocks)
  # Init the Board
  def initialize(puzzle)
    @width = puzzle[:columns].length
    @height = puzzle[:rows].length
    @clues = puzzle.reject { |key,_| ![:rows, :columns].include? key }
    @passing = passing_init
    @colors = [:white, :black]
    # Init the blocks
    @blocks = blocks_init()
  end

  def blocks_init
    blocks = []
    (0...@width).each do |x|
      (0...@height).each do |y|
        blocks << Block.new(x, y, @colors[0])
      end
    end
    blocks[0].selected = true
    blocks
  end

  def passing_init
    passing = {}
    @clues.each do |direction, lines|
      passing[direction] = []
      lines.each do |line|
        new_line = []
        line.each do |clue|
          new_line << false
        end
        passing[direction] << new_line
      end
    end
  end

  def read_line(number, direction)
    score = []
    if direction == :rows
      line = @blocks.select { |b| b.coords[:y] == number }.map { |b| b = b.color }
    else
      line = @blocks.select { |b| b.coords[:x] == number }.map { |b| b = b.color }
    end
    counter = 0
    line.each_with_index do |cell, i|
      # Start a counter
      if cell == :black && (i == 0 || line[i-1] == :white)
        counter = 0
      end
      # Add to the counter if :black
      if cell == :black
        counter += 1
      end
      if cell == :black && (i == line.length-1 || line[i+1] == :white)
        score << counter
      end
    end
    score
  end

  def test_puzzle(puzzle)
    puzzle[:rows].each_with_index do |row,i|
      if read_line(i, :rows) != row
        return false
      end
    end
    puzzle[:columns].each_with_index do |column,i|
      if read_line(i, :columns) != column
        return false
      end
    end
    return true
  end
end

class GameWindow

  def initialize(root, board, scale)
    @scale = scale
    @board = board
    @root = root
    set_root_keybinds()
    @board_window = draw_board_window()
    set_board_window_binds()
    @clues_windows = draw_clues_windows(@board.clues)
    @blocks = draw_blocks()
    @guide_lines = draw_guide_lines()
    # Record keeping
    @marks = {}
    @highlights = []
    # Clues : {coords: {row|column: #, clue: #} clue: #, text_object: TkcText}
    @clues_list = draw_clues(@board.clues)
  end

  def set_root_keybinds
    # Zoom in and out
    @root.bind('plus', proc do
      @scale += 1
      update_scale()
    end)
    @root.bind('minus', proc do
      @scale -= 1
      update_scale()
    end)
    # HJKL Vim Keybinds
    @root.bind('h', proc do
      active = @board.blocks.find { |b| b.selected }
      move_to = @board.blocks.find { |b| b.coords == {x: active.coords[:x]-1, y: active.coords[:y]} }
      if move_to
        active.selected = false
        move_to.selected = true
        update_highlight()
      end
    end)
    @root.bind('j', proc do
      active = @board.blocks.find { |b| b.selected }
      move_to = @board.blocks.find { |b| b.coords == {x: active.coords[:x], y: active.coords[:y]+1} }
      if move_to
        active.selected = false
        move_to.selected = true
        update_highlight()
      end
    end)
    @root.bind('k', proc do
      active = @board.blocks.find { |b| b.selected }
      move_to = @board.blocks.find { |b| b.coords == {x: active.coords[:x], y: active.coords[:y]-1} }
      if move_to
        active.selected = false
        move_to.selected = true
        update_highlight()
      end
    end)
    @root.bind('l', proc do
      active = @board.blocks.find { |b| b.selected }
      move_to = @board.blocks.find { |b| b.coords == {x: active.coords[:x]+1, y: active.coords[:y]} }
      if move_to
        active.selected = false
        move_to.selected = true
        update_highlight()
      end
    end)
    @root.bind('c', proc do
      active = @board.blocks.find { |b| b.selected }
      active.color_cycle(@board.colors)
      update_block_view(active)
    end)
    @root.bind('x', proc do
      active = @board.blocks.find { |b| b.selected }
      active.set_marked()
      update_block_view(active)
    end)
  end

  def set_board_window_binds
    @board_window.bind('Motion', proc do |x, y|
      x = floor_to(x, @scale)/@scale
      y = floor_to(y, @scale)/@scale
      block = @board.blocks.find {|b| b.coords == {x: x, y: y}}
      if block
        @board.blocks.select {|b| b.selected == true}.each do |b|
          b.selected = false
        end
        block.selected = true
        update_highlight()
      end
    end, "%x %y")
    @board_window.bind('Leave', proc { erase_highlight() })
  end

  # Init the main canvas
  def draw_board_window
    heightpx = @board.height*@scale
    widthpx = @board.width*@scale
    TkCanvas.new(@root, bg: "#ffffff", height: heightpx, width: widthpx) { grid(row: 1, column: 1) }
  end

  # Init the 2 clues canvas
  def draw_clues_windows(clues)
    heightpx = @board.height*@scale
    widthpx = @board.width*@scale
    windows = {}
    windows[:rows] = TkCanvas.new(@root, bg: "#aaaaaa") { grid(:row => 1, :column => 0) }
    windows[:rows].height = heightpx
    windows[:rows].width = (@scale*clues[:rows].map { |row| row.length }.max)
    windows[:columns] = TkCanvas.new(@root, bg: "#aaaaaa") { grid(:row => 0, :column => 1) }
    windows[:columns].height = (@scale*clues[:columns].map { |column| column.length }.max)
    windows[:columns].width = widthpx
    windows
  end

  # Draw the clues
  def draw_clues(clues)
    rows = @clues_windows[:rows]
    columns = @clues_windows[:columns]
    clue_list = []
    clues[:rows].each_with_index do |row, r|
      row.reverse.each_with_index do |clue, i|
        text_object = TkcText.new(rows, rows.width-(((i+1)*@scale)-(@scale/2)),
                                  ((r+1)*@scale)-(@scale/2),
                                  { text: clue, tag: "clue"})
        clue_list << {coords: {row: r, clue: i}, clue: clue.to_i, text_object: text_object}
      end
    end
    clues[:columns].each_with_index do |column, c|
      column.reverse.each_with_index do |clue, i|
        text_object = TkcText.new(columns, ((c+1)*@scale)-(@scale/2),
                                  columns.height-(((i+1)*@scale)-(@scale/2)),
                                  { text: clue, tag: "clue" })
        clue_list << {coords: {column: c, clue: i}, clue: clue.to_i, text_object:text_object}
      end
    end
    clue_list
  end

  # Draw the blocks on the board
  def draw_blocks
    blocks = {}
    @board.blocks.each do |block|
      x = block.coords[:x]*@scale
      y = block.coords[:y]*@scale
      cell = TkcRectangle.new(@board_window, x, y, x+@scale, y+@scale, { fill: block.color.to_s, outline: "#aaaaaa" })

      # Bind events
      cell.bind("ButtonPress-1", proc do
        block.color_cycle(@board.colors)
        update_block_view(block)
      end)
      cell.bind("ButtonPress-3", proc do
        if block.color != :mark
          block.set_marked()
        else
          block.color_cycle(@board.colors)
        end
        update_block_view(block)
      end)

      blocks[block] = cell
    end
    blocks
  end

  # Draw guide lines every 5 blocks
  def draw_guide_lines
    lines = []
    (0...@board_window.width).step(@scale*5) do |x|
      lines << TkcLine.new(@board_window, x, 0, x, @board_window.height, { width: 2, fill: "#aaaaaa" })
    end
    (0...@board_window.height).step(@scale*5) do |x|
      lines << TkcLine.new(@board_window, 0, x, @board_window.width, x, { width: 2, fill: "#aaaaaa" })
    end
    lines
  end

  def draw_highlight(cell)
    erase_highlight()
    @highlights = []
    @highlights << TkcLine.new(@board_window, cell.coords[0], 0, cell.coords[0], @board_window.height, { fill: 'red', width: 2 })
    @highlights << TkcLine.new(@board_window, cell.coords[2], 0, cell.coords[2], @board_window.height, { fill: 'red', width: 2 })
    @highlights << TkcLine.new(@board_window, 0, cell.coords[1], @board_window.height, cell.coords[1], { fill: 'red', width: 2 })
    @highlights << TkcLine.new(@board_window, 0, cell.coords[3], @board_window.width, cell.coords[3], { fill: 'red', width: 2 })
  end

  def erase_highlight
    unless @highlights.empty?
      @highlights.each {|highlight| highlight.remove}
    end
  end

  # Update the block visual
  def update_block_view(block)
    # test puzzle
    if @board.test_puzzle(@board.clues)
      Tk.messageBox( type: 'ok', title: 'Puzzle Complete!', message: 'Puzzle Complete!' )
    end
    cell = @blocks[block]
    delete_mark(block)
    if block.color != :mark
      cell.fill(block.color.to_s)
    else
      cell.fill("white")
      mark = []
      mark << TkcLine.new(@board_window, cell.coords[0], cell.coords[1], cell.coords[2], cell.coords[3], { 'width' => 2 })
      mark << TkcLine.new(@board_window, cell.coords[2], cell.coords[1], cell.coords[0], cell.coords[3], { 'width' => 2 })
      mark.map { |line| line.bind("ButtonPress-1", proc do
        block.color_cycle(@board.colors)
        update_block_view(block)
      end) }
      mark.map { |line| line.bind("ButtonPress-3", proc do
        block.color_cycle(@board.colors)
        update_block_view(block)
      end) }
      # Save the lines used for marking so they can be removed
      @marks[block] = mark
    end
  end

  def update_highlight
    draw_highlight(@blocks.find { |b, _| b.selected }[1])
  end

  # Given a block, if it is marked, remove the mark
  def delete_mark(block)
    if @marks[block]
      @marks[block].each { |line| line.remove }
      @marks.delete(block)
    end
  end

  # Update the window to reflect a change in scale
  def update_scale
    heightpx = @board.height*@scale
    widthpx = @board.width*@scale
    # Gameboard
    @board_window.height = heightpx
    @board_window.width = widthpx
    # Clue windows
    @clues_windows[:rows].height = heightpx
    @clues_windows[:rows].width = (@scale*@board.clues[:rows].map { |row| row.length }.max)
    @clues_windows[:columns].height = (@scale*@board.clues[:columns].map { |column| column.length }.max)
    @clues_windows[:columns].width = widthpx
    @clues_list.each { |clue| clue[:text_object].delete() }
    @clues_list = draw_clues(@board.clues)
    # Blocks
    @blocks.each do |block, cell|
      x = block.coords[:x]*@scale
      y = block.coords[:y]*@scale
      cell.coords = [x, y, x+@scale, y+@scale]
    end
    # Guide lines
    @guide_lines.each { |line| line.remove }
    @guide_lines = draw_guide_lines()
    update_highlight()
  end

  # Floor division helper
  def floor_to(number, step)
    whole, _ = number.divmod(step)
    whole * step
  end

end

# A main funtion for getting things going
def main(puzzle)

  puzzle = parse_puzzle(puzzle) unless !puzzle
  scale = 20

  # Check to see if we were passed a valid puzzle
  if puzzle && puzzle[:colors] == 2

    # Build everything
    root = TkRoot.new(bg: "#222222") { title "Nonogram" }
    board = Board.new(puzzle)
    gamewindow = GameWindow.new(root, board, scale)

    # Start the loop
    Tk.mainloop

  else
    puts "Please provide a valid 2 colour puzzle"
  end

end

# Start the game!
main(ARGV[0])
