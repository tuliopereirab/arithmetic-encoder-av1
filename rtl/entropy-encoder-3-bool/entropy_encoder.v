module entropy_encoder #(
  parameter TOP_RANGE_WIDTH = 16,
  parameter TOP_LOW_WIDTH = 24,
  parameter TOP_SYMBOL_WIDTH = 4,
  parameter TOP_LUT_ADDR_WIDTH = 8,
  parameter TOP_LUT_DATA_WIDTH = 16,
  parameter TOP_BITSTREAM_WIDTH = 8,
  parameter TOP_D_SIZE = 5,
  parameter TOP_ADDR_CARRY_WIDTH = 4
  )(
    input top_clk,
    input top_reset,
    input top_flag_first,
    /* top_final_flag will be sent in 1 exactly in the next clock cycle after
    the last input. */
    input top_final_flag,
    input [(TOP_RANGE_WIDTH-1):0] top_fl, top_fh,
    input [(TOP_SYMBOL_WIDTH-1):0] top_symbol_1, top_symbol_2, top_symbol_3,
    input [TOP_SYMBOL_WIDTH:0] top_nsyms,
    input top_bool_1, top_bool_2, top_bool_3,
    output wire [(TOP_BITSTREAM_WIDTH-1):0] OUT_BIT_1_1, OUT_BIT_1_2,
    output wire [(TOP_BITSTREAM_WIDTH-1):0] OUT_BIT_1_3, OUT_BIT_1_4,
    output wire [(TOP_BITSTREAM_WIDTH-1):0] OUT_BIT_1_5,
    output wire [2:0] OUT_FLAG_BITSTREAM_1,
    output wire OUT_FLAG_LAST
  );

  /*In order to ensure that all the necessary flags in the Carry propagation
  block will be correctly initiated, I will propagate a flag called flag_first
  able to set all flags to zero without requiring any other flag.
  This is a temporary way to ensure that all flags are correctly defined
  when the first bitstream comes through.
    The following lines will just propagate this signal between the blocks
  */
  reg reg_first_1_2, reg_first_2_3, reg_first_3_4;
  always @ (posedge top_clk) begin
    reg_first_1_2 <= top_flag_first;
    reg_first_2_3 <= reg_first_1_2;
    reg_first_3_4 <= reg_first_2_3;
    // reg_first_3_4 register is also the input for the Stage_4
  end

  // The 3 following registers will be used to keep the final 1 flag
  reg reg_final_exec_1_2, reg_final_exec_2_3, reg_final_exec_3_4;
  always @ (posedge top_clk) begin
    if(top_reset) begin
      reg_final_exec_1_2 <= 1'b0;
      reg_final_exec_2_3 <= 1'b0;
      reg_final_exec_3_4 <= 1'b0;
    end else begin
      reg_final_exec_1_2 <= top_final_flag;
      reg_final_exec_2_3 <= reg_final_exec_1_2;
      reg_final_exec_3_4 <= reg_final_exec_2_3;
    end
  end

  /* ARITHMETIC ENCODER OUTPUT CONNECTIONS
        -> All arithmetic encoder outputs come from registers
        -> Therefore, it isn't necessary to create more registers here */
  wire [(TOP_RANGE_WIDTH-1):0] out_arith_bitstream_1_1, out_arith_bitstream_1_2;
  wire [(TOP_RANGE_WIDTH-1):0] out_arith_bitstream_2_1, out_arith_bitstream_2_2;
  wire [(TOP_RANGE_WIDTH-1):0] out_arith_bitstream_3_1, out_arith_bitstream_3_2;
  wire [1:0] out_arith_flag_1, out_arith_flag_2, out_arith_flag_3;
  wire [(TOP_D_SIZE-1):0] out_arith_cnt;
  wire [(TOP_LOW_WIDTH-1):0] out_arith_low;
  wire [(TOP_RANGE_WIDTH-1):0] out_arith_range;
  // ------------------------------------------------


  arithmetic_encoder #(
    .GENERAL_RANGE_WIDTH (TOP_RANGE_WIDTH),
    .GENERAL_LOW_WIDTH (TOP_LOW_WIDTH),
    .GENERAL_SYMBOL_WIDTH (TOP_SYMBOL_WIDTH),
    .GENERAL_LUT_ADDR_WIDTH (TOP_LUT_ADDR_WIDTH),
    .GENERAL_LUT_DATA_WIDTH (TOP_LUT_DATA_WIDTH),
    .GENERAL_D_SIZE (TOP_D_SIZE)
    ) arith_encoder (
      .general_clk (top_clk),
      .reset (top_reset),     // send to the arith_encoder only the reset itself
      .general_fl (top_fl),
      .general_fh (top_fh),
      .general_nsyms (top_nsyms),
      // Parallel Bool
      .general_symbol_1 (top_symbol_1),
      .general_symbol_2 (top_symbol_2),
      .general_symbol_3 (top_symbol_3),
      .general_bool_1 (top_bool_1),
      .general_bool_2 (top_bool_2),
      .general_bool_3 (top_bool_3),
      // outputs
      .RANGE_OUTPUT (out_arith_range),
      .LOW_OUTPUT (out_arith_low),
      .CNT_OUTPUT (out_arith_cnt),
      // Parallel Bool
      .OUT_BIT_1_1 (out_arith_bitstream_1_1),
      .OUT_BIT_1_2 (out_arith_bitstream_1_2),
      .OUT_FLAG_BITSTREAM_1 (out_arith_flag_1),
      // Second
      .OUT_BIT_2_1 (out_arith_bitstream_2_1),
      .OUT_BIT_2_2 (out_arith_bitstream_2_2),
      .OUT_FLAG_BITSTREAM_2 (out_arith_flag_2),
      // Third
      .OUT_BIT_3_1 (out_arith_bitstream_3_1),
      .OUT_BIT_3_2 (out_arith_bitstream_3_2),
      .OUT_FLAG_BITSTREAM_3 (out_arith_flag_3)
    );

  stage_4 #(
    .S4_RANGE_WIDTH (TOP_RANGE_WIDTH),
    .S4_LOW_WIDTH (TOP_LOW_WIDTH),
    .S4_SYMBOL_WIDTH (TOP_SYMBOL_WIDTH),
    .S4_LUT_ADDR_WIDTH (TOP_LUT_ADDR_WIDTH),
    .S4_LUT_DATA_WIDTH (TOP_LUT_DATA_WIDTH),
    .S4_BITSTREAM_WIDTH (TOP_BITSTREAM_WIDTH),
    .S4_D_SIZE (TOP_D_SIZE),
    .S4_ADDR_CARRY_WIDTH (TOP_ADDR_CARRY_WIDTH)
    ) state_pipeline_4 (
      .s4_clk (top_clk),
      .s4_reset (top_reset),
      .s4_flag_first (reg_first_3_4),
      .s4_final_flag (reg_final_exec_3_4),
      .s4_final_flag_2_3 (reg_final_exec_2_3),
      .in_arith_range (out_arith_range),
      .in_arith_cnt(out_arith_cnt),
      .in_arith_low (out_arith_low),
      // Outputs
      // First
      .in_arith_flag_1 (out_arith_flag_1),
      .in_arith_bitstream_1_1 (out_arith_bitstream_1_1),
      .in_arith_bitstream_1_2 (out_arith_bitstream_1_2),
      // Second
      .in_arith_flag_2 (out_arith_flag_2),
      .in_arith_bitstream_2_1 (out_arith_bitstream_2_1),
      .in_arith_bitstream_2_2 (out_arith_bitstream_2_2),
      // Third
      .in_arith_flag_3 (out_arith_flag_3),
      .in_arith_bitstream_3_1 (out_arith_bitstream_3_1),
      .in_arith_bitstream_3_2 (out_arith_bitstream_3_2),
      // outputs
      .out_carry_bit_1_1 (OUT_BIT_1_1), .out_carry_bit_1_2 (OUT_BIT_1_2),
      .out_carry_bit_1_3 (OUT_BIT_1_3), .out_carry_bit_1_4 (OUT_BIT_1_4),
      .out_carry_bit_1_5 (OUT_BIT_1_5),
      .out_carry_flag_bitstream_1 (OUT_FLAG_BITSTREAM_1),
      .output_flag_last (OUT_FLAG_LAST)
    );
endmodule
