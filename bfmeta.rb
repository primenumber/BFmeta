require_relative 'bfm_state'

file = File.open(ARGV[0], "r")
if ARGV.include?("--debug") then
  require_relative 'debug_window'
  DebugWindowModule.init_screen
  $dw = DebugWindow.new
  input = $dw.get_input_stream(File.open(ARGV[1], "r"))
  output = $dw.get_output_stream
  state = BFMState.new(file.read, input, output)
  loop {
    break unless state.step
    $dw.output(state)
    sleep(0.1)
  }
  Curses::getch
  Curses::close_screen
  puts output.output
else
  input =  if ARGV[1] != nil then File.open(ARGV[1], "r").each_byte else $stdin end
  output = if ARGV[2] != nil then File.open(ARGV[2], "wb") else $stdout end
  state = BFMState.new(file.read, input, output)
  loop {
    break unless state.step
  }
end
