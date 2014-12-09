class BFMState
  attr_reader :ary, :data_pos, :prog_pos
  @@code = "><+-[],.\0"
  def initialize(code, input=$stdin.each_byte, output=$stdout)
    @ary = Array.new
    code.each_byte {|ch| @ary.push(ch)}
    @data_pos = 0
    @prog_pos = 0
    @input_enum = input
    @output = output
  end
  def move_to_open
    cnt = -1
    while cnt != 0
      @prog_pos -= 1
      raise "Unmatch brackets" if @prog_pos < 0
      case @ary[@prog_pos].chr
      when @@code[4] then
        cnt += 1
      when @@code[5] then
        cnt -= 1
      end
    end
  end
  def move_to_close
    cnt = 1
    while cnt != 0
      @prog_pos += 1
      @ary[@prog_pos] = 0 if @ary[@prog_pos] == nil
      case @ary[@prog_pos].chr
      when @@code[4] then
        cnt += 1
      when @@code[5] then
        cnt -= 1
      end
    end
  end
  def step
    case @ary[@prog_pos].chr
    when @@code[0] then
      @data_pos += 1
      @ary[@data_pos] = 0 if @ary[@data_pos] == nil
    when @@code[1] then
      @data_pos -= 1
      raise "Out of Array" if @data_pos < 0
    when @@code[2] then
      if @ary[@data_pos] < 255 then
        @ary[@data_pos] += 1
      else
        @ary[@data_pos] = 0
      end
    when @@code[3] then
      if @ary[@data_pos] > 0 then
        @ary[@data_pos] -= 1
      else
        @ary[@data_pos] = 255
      end
    when @@code[4] then
      move_to_close if @ary[@data_pos] == 0
    when @@code[5] then
      move_to_open if @ary[@data_pos] != 0
    when @@code[6] then
      begin
        @ary[@data_pos] = @input_enum.next
      rescue StopIteration
        @ary[@data_pos] = 0
      end
    when @@code[7] then
      @output.putc @ary[@data_pos].chr
    when @@code[8] then
      return false
    end
    @prog_pos += 1
    @ary[@prog_pos] = 0 if @ary[@prog_pos] == nil
    return true
  end
end

