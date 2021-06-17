class BFMState
  attr_reader :ary, :data_pos, :prog_pos
  INSTS = "><+-[],.\0".bytes
  def initialize(code, input=$stdin.each_byte, output=$stdout)
    @ary = Hash.new(0)
    code.each_byte.with_index {|ch,i| @ary[i] = ch}
    @data_pos = 0
    @prog_pos = 0
    @input_enum = input
    @output = output
  end
  def move_to_open
    cnt = -1
    while cnt != 0
      @prog_pos -= 1
      raise "Unmatch brackets" if !@ary.has_key?(@prog_pos)
      case @ary[@prog_pos]
      when INSTS[4] then
        cnt += 1
      when INSTS[5] then
        cnt -= 1
      end
    end
  end
  def move_to_close
    cnt = 1
    while cnt != 0
      @prog_pos += 1
      raise "Unmatch brackets" if !@ary.has_key?(@prog_pos)
      case @ary[@prog_pos]
      when INSTS[4] then
        cnt += 1
      when INSTS[5] then
        cnt -= 1
      end
    end
  end
  def step
    case @ary[@prog_pos]
    when INSTS[0] then
      @data_pos += 1
      @ary[@data_pos] = 0 if !@ary.has_key?(@data_pos)
    when INSTS[1] then
      @data_pos -= 1
      @ary[@data_pos] = 0 if !@ary.has_key?(@data_pos)
    when INSTS[2] then
      if @ary[@data_pos] < 255 then
        @ary[@data_pos] += 1
      else
        @ary[@data_pos] = 0
      end
    when INSTS[3] then
      if @ary[@data_pos] > 0 then
        @ary[@data_pos] -= 1
      else
        @ary[@data_pos] = 255
      end
    when INSTS[4] then
      move_to_close if @ary[@data_pos] == 0
    when INSTS[5] then
      move_to_open if @ary[@data_pos] != 0
    when INSTS[6] then
      begin
        @ary[@data_pos] = @input_enum.next
      rescue StopIteration
        @ary[@data_pos] = 0
      end
    when INSTS[7] then
      @output.putc @ary[@data_pos].chr
    when INSTS[8] then
      return false
    end
    @prog_pos += 1
    return true
  end
end

