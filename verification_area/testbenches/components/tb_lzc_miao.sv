module tb_lzc #(
  parameter TB_RANGE_WIDTH = 16,
  parameter TB_D_SIZE = 4,
  parameter MAX_TEST = 65535
  ) ();

  reg [(TB_RANGE_WIDTH-1):0] tb_range_input;
  wire [(TB_D_SIZE-1):0] tb_lzc_out;
  wire tb_v;
  int current_value, check_value, counter, match, miss;

  lzc_miao_16 lzc (.in (tb_range_input), .out_z (tb_lzc_out),
                  .v (tb_v));

  function int leading_zero_function;
    input bit [(TB_RANGE_WIDTH-1):0] rng;
    int i;
    for(i=0;i<TB_RANGE_WIDTH; i = i + 1) begin
      if(rng[(TB_RANGE_WIDTH-1)-i] == 1) begin
        return i;
      end
    end
    return TB_RANGE_WIDTH;
  endfunction

  initial begin
    counter = 0;
    match = 0;
    miss = 0;
    while(counter < MAX_TEST) begin
      current_value = counter;
      // current_value = $urandom_range(0,65535);
      check_value = leading_zero_function(current_value);
      tb_range_input = current_value;
      #10ns;
      if((tb_lzc_out != (check_value)) && (current_value != 0)) begin
        $display("Value %d:\tExpected: %d\tGot: %d\nCounter: %d\n", current_value, check_value, tb_lzc_out, counter);
        miss = miss + 1;
        //#1ns;
        $stop;
      end else begin
        //$display("Right!\n");
        match = match + 1;
      end
      counter = counter + 1;
      #5ns;
    end
    $display("Total Executed: %d\nTotal Matches: %d\nTotal Misses: %d\n", counter, match, miss);
    $stop;
  end
endmodule
