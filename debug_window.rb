require 'curses'

module DebugWindowModule
  def self.init_screen
    Curses::init_screen
    Curses::start_color
    Curses::init_pair(1, Curses::COLOR_WHITE, Curses::COLOR_BLACK)
    Curses::init_pair(2, Curses::COLOR_BLACK, Curses::COLOR_WHITE)
    Curses::init_pair(3, Curses::COLOR_BLACK, Curses::COLOR_GREEN)
    Curses::init_pair(4, Curses::COLOR_WHITE, Curses::COLOR_CYAN)
    Curses::init_pair(5, Curses::COLOR_RED, Curses::COLOR_BLACK)
    Curses::cbreak
    Curses::noecho
  end
  def self.fill_space(str, width)
    str += " " while str.length < width
    return str
  end
  def self.write_header(window, y, id, str)
    window.attron(Curses::color_pair(id) | Curses::A_BOLD)
    window.setpos(y, 0)
    window.addstr(fill_space(str, window.maxx))
    window.attroff(Curses::color_pair(id) | Curses::A_BOLD)
  end
end

class DebugWindow
  def initialize(window = Curses.stdscr)
    @window = window
    # window to show program state
    prog_wind = @window.subwin(@window.maxy-20, @window.maxx, 1, 0)
    @prog_window = ProgramWindow.new(prog_wind, 1, 0)
    # window to show IO state
    io_wind = @window.subwin(18, @window.maxx, @window.maxy - 18, 0)
    @io_window = IOWindow.new(io_wind, @window.maxy - 18, 0)
    DebugWindowModule.write_header(@window, 0, 4, "Program:")
    DebugWindowModule.write_header(@window, @window.maxy - 19, 4, "I/O:")
    @window.refresh
    @window.setpos(@window.maxy - 16, 0)
  end
  def get_output_stream
    @io_window.get_output_stream
  end
  def get_input_stream(input)
    @io_window.get_input_stream(input)
  end
  def output(state)
    @prog_window.output(state)
  end
end

class ProgramWindow
  def initialize(window, offy, offx)
    @window = window
    char_win_h = (@window.maxy - 1) / 2
    @char_win = @window.subwin(char_win_h, @window.maxx, 1 + offy, 0 + offx)
    hex_win_h = @window.maxy - 2 - char_win_h
    @hex_win = @window.subwin(hex_win_h, @window.maxx, 2 + char_win_h + offy, 0 + offx)
    DebugWindowModule.write_header(@window, 0, 3, "Char:")
    DebugWindowModule.write_header(@window, char_win_h + 1, 3, "Hex:")
    @window.refresh
  end
  def output(state)
    output_char(state)
    output_hex(state)
  end
  def output_char(state)
    size_char = @char_win.maxx * @char_win.maxy
    @char_win.setpos(0, 0)
    size_char.times do |i|
      byte = state.ary[i].ord
      @char_win.attron(Curses::A_BOLD) if i == state.prog_pos
      @char_win.attron(Curses::A_REVERSE) if i == state.data_pos
      if byte != nil && 32 <= byte && byte <= 126 then
        @char_win.addch byte.chr
      else
        @char_win.attron(Curses::color_pair(5))
        @char_win.addch '.'
        @char_win.attroff(Curses::color_pair(5))
      end
      @char_win.attroff(Curses::A_REVERSE) if i == state.data_pos
      @char_win.attroff(Curses::A_BOLD) if i == state.prog_pos
    end
    @char_win.refresh
  end
  def output_hex(state)
    @hex_win.setpos(0, 0)
    size_hex = (@hex_win.maxx / 2) * @hex_win.maxy
    size_hex.times do |i|
      if i != 0 && (i % (@hex_win.maxx / 2)) == 0
        @hex_win.setpos(@hex_win.cury + 1, 0)
      end
      byte = if state.ary[i] != nil then state.ary[i].ord else 0 end
      @hex_win.attron(Curses::A_BOLD) if i == state.prog_pos
      @hex_win.attron(Curses::A_REVERSE) if i == state.data_pos
      @hex_win.addstr("%02X" % byte)
      @hex_win.attroff(Curses::A_REVERSE) if i == state.data_pos
      @hex_win.attroff(Curses::A_BOLD) if i == state.prog_pos
    end
    @hex_win.refresh
  end
end

class IOWindow
  def initialize(window, offy, offx)
    @window = window
    input_win = @window.subwin(8, @window.maxx, 1 + offy, 0 + offx)
    @input_window = InputWindow.new(input_win, 1 + offy, 0 + offx)
    output_win = @window.subwin(8, @window.maxx, 10 + offy, 0 + offx)
    @output_window = OutputWindow.new(output_win, 10 + offy, 0 + offx)
    DebugWindowModule.write_header(@window, 0, 3, "Input:")
    DebugWindowModule.write_header(@window, 9, 3, "Output:")
    @window.refresh
  end
  def get_output_stream
    @output_window.get_output_stream
  end
  def get_input_stream(input)
    @input_window.get_input_stream(input)
  end
end

class InputWindow
  def initialize(window, offy, offx)
    @window = window
    @char_win = @window.subwin(3, @window.maxx, 1 + offy, 0 + offx)
    @hex_win = @window.subwin(3, @window.maxx, 5 + offy, 0 + offx)
    DebugWindowModule.write_header(@window, 0, 2, "Char:")
    DebugWindowModule.write_header(@window, 4, 2, "Hex:")
    @window.refresh
  end
  def get_input_stream(input)
    @stream = InputStream.new(@char_win, @hex_win, input)
    return @stream
  end
end

class InputStream
  def initialize(window_char, window_hex, input)
    @char = window_char
    @hex = window_hex
    @input = input
    @input_buf_size = @char.maxy * @char.maxx
    @input_buf = ""
    @input_pos = 0
    load_nonblock
    show
  end
  def load_nonblock
    begin
      data = @input.read_nonblock(@input_buf_size)
      @input_buf += data
      @input_buf_size -= data.length
    rescue
    end
  end
  def show
    @char.setpos(0, 0)
    @hex.setpos(0, 0)
    @input_buf.each_byte.with_index do |byte, i|
      if i == @input_pos then
        @char.attron(Curses::A_BOLD)
        @hex.attron(Curses::A_BOLD)
      end
      if 32 <= byte && byte <= 126
        @char.addch byte.chr
      else
        @char.attron(Curses::color_pair(5))
        @char.addch '.'
        @char.attroff(Curses::color_pair(5))
      end
      @hex.addstr("%02X" % byte)
      if i == @input_pos then
        @char.attroff(Curses::A_BOLD)
        @hex.attroff(Curses::A_BOLD)
      end
    end
    @char.refresh
    @hex.refresh
  end
  def next
    load_nonblock
    result = ""
    if @input_pos < @input_buf.length then
      result = @input_buf.getbyte(@input_pos)
    else
      begin
        result = @input.readbyte
      rescue EOFError
        result = 0
      end
      if @input_pos < @input_buf.length + @input_buf_size then
        @input_buf += result.chr
        @input_buf_size -= 1
      end
    end
    show
    @input_pos += 1
    return result
  end
end

class OutputWindow
  def initialize(window, offy, offx)
    @window = window
    char_win = @window.subwin(3, @window.maxx, 1 + offy, 0 + offx)
    hex_win = @window.subwin(3, @window.maxx, 5 + offy, 0 + offx)
    @stream = OutputStream.new(char_win, hex_win)
    DebugWindowModule.write_header(@window, 0, 2, "Char:")
    DebugWindowModule.write_header(@window, 4, 2, "Hex:")
    @window.refresh
  end
  def get_output_stream
    @stream
  end
end

class OutputStream
  attr_reader :output
  def initialize(window_char, window_hex)
    @char = window_char
    @hex = window_hex
    @output = ""
  end
  def putc(char)
    @char.addch(char)
    @hex.addstr("%02X" % char.ord)
    @char.refresh
    @hex.refresh
    @output += char
  end
end
