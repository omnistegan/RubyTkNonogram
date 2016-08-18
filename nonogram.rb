#!/usr/bin/env ruby
require 'tk'
require './parse_puzzle.rb'
require './gamewindow.rb'

class Block
  attr_reader(:coords, :color, :selected)

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

  # Toggle selected
  def toggle_selected
    if @selected
      @selected = false
    else
      @selected = true
    end
  end
end

class Board
  attr_reader(:width, :height, :clues, :colors, :blocks)
  # Init the Board
  def initialize(puzzle)
    @width = puzzle[:columns].length
    @height = puzzle[:rows].length
    # Keep just the clues from the puzzle
    @clues = clues_init(puzzle.reject { |key,_| ![:rows, :columns].include? key })
    # Only black and white for now
    @colors = [:white, :black]
    # Init the blocks
    @blocks = blocks_init()
  end

  # Init the clues to include a pass param
  def clues_init(clue_hash)
    clues = {}
    clue_hash.map do |direction, lines|
      clues[direction] = lines.map do |line|
        line.map do |clue|
          clue = {clue: clue, pass: false}
        end
      end
    end
    clues
  end

  # Create all the blocks
  def blocks_init
    blocks = []
    (0...@width).each do |x|
      (0...@height).each do |y|
        blocks << Block.new(x, y, @colors[0])
      end
    end
    # Initially select the first block to be selected
    blocks[0].toggle_selected
    blocks
  end

  # Return an array of grouped black blocks
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
      if cell == :black && (i == 0 || line[i-1] != :black)
        counter = 0
      end
      # Add to the counter if :black
      if cell == :black
        counter += 1
      end
      # Write the counter
      if cell == :black && (i == line.length-1 || line[i+1] != :black)
        score << counter
      end
    end
    score
  end

  # Update our clues to say which are passing
  def update_passing(x, y)
    # Reset all clues to false
    @clues[:rows][y].map { |clue| clue[:pass] = false }
    @clues[:columns][x].map { |clue| clue[:pass] = false }

    row_read = read_line(y, :rows)
    row_clues = @clues[:rows][y].map { |clue| clue = clue[:clue] }
    # If the whole row passes
    if row_read == row_clues
      @clues[:rows][y].map { |clue| clue[:pass] = true }
    else
      forward_pass = 0
      reverse_pass = 0
      forward_row = row_read.zip(row_clues)
      reverse_row = row_read.reverse.zip(row_clues.reverse)
      # How many clues pass in the forwards direction
      forward_row.each do |test, clue|
        if test == clue
          forward_pass += 1
        else
          break
        end
      end
      # How many clues pass in the reverse direction
      reverse_row.each do |test, clue|
        if test == clue
          reverse_pass += 1
        else
          break
        end
      end
      # Make sure we don't mark more clues than necessary
      clues_to_mark = row_read.length
      (0...forward_pass).each do |i|
        @clues[:rows][y][i][:pass] = true unless clues_to_mark <= 0
        clues_to_mark -= 1
      end
      (0...reverse_pass).each do |i|
        @clues[:rows][y][-i-1][:pass] = true unless clues_to_mark <= 0
        clues_to_mark -= 1
      end
    end

    # Do the whole thing again for the columns
    column_read = read_line(x, :columns)
    column_clues = @clues[:columns][x].map { |clue| clue = clue[:clue] }
    if column_read == column_clues
      @clues[:columns][x].map { |clue| clue[:pass] = true }
    else
      forward_pass = 0
      reverse_pass = 0
      forward_column = column_read.zip(column_clues)
      reverse_column = column_read.reverse.zip(column_clues.reverse)
      forward_column.each do |test, clue|
        if test == clue
          forward_pass += 1
        else
          break
        end
      end
      reverse_column.each do |test, clue|
        if test == clue
          reverse_pass += 1
        else
          break
        end
      end
      clues_to_mark = column_read.length
      (0...forward_pass).each do |i|
        @clues[:columns][x][i][:pass] = true unless clues_to_mark <= 0
        clues_to_mark -= 1
      end
      (0...reverse_pass).each do |i|
        @clues[:columns][x][-i-1][:pass] = true unless clues_to_mark <= 0
        clues_to_mark -= 1
      end
    end
  end

  # Test the whole puzzle and return a true|false
  def test_puzzle
    @clues[:rows].each_with_index do |row,i|
      if read_line(i, :rows) != row.map { |r| r = r[:clue] }
        return false
      end
    end
    @clues[:columns].each_with_index do |column,i|
      if read_line(i, :columns) != column.map { |c| c = c[:clue] }
        return false
      end
    end
    return true
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
