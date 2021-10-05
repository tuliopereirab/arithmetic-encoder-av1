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
    input [(TOP_SYMBOL_WIDTH-1):0] top_symbol,
    input [TOP_SYMBOL_WIDTH:0] top_nsyms,
    input top_bool,
    output wire [(TOP_BITSTREAM_WIDTH-1):0] OUT_BIT_1, OUT_BIT_2, OUT_BIT_3,
    output wire [(TOP_BITSTREAM_WIDTH-1):0] OUT_BIT_4, OUT_BIT_5,
    output wire [2:0] OUT_FLAG_BITSTREAM,
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

  // ARITHMETIC ENCODER OUTPUT CONNECTIONS
    // ALl arithmetic encoder outputs come from registers
    // Therefore, it isn't necessary to create more registers here
  wire [(TOP_RANGE_WIDTH-1):0] out_arith_bitstream_1, out_arith_bitstream_2;
  wire [(TOP_RANGE_WIDTH-1):0] out_arith_range;
  wire [(TOP_D_SIZE-1):0] out_arith_cnt;
  wire [(TOP_LOW_WIDTH-1):0] out_arith_low;
  wire [1:0] out_arith_flag;


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
      .general_symbol (top_symbol),
      .general_nsyms (top_nsyms),
      .general_bool (top_bool),
      // outputs
      .RANGE_OUTPUT (out_arith_range),
      .LOW_OUTPUT (out_arith_low),
      .CNT_OUTPUT (out_arith_cnt),
      .OUT_BIT_1 (out_arith_bitstream_1),
      .OUT_BIT_2 (out_arith_bitstream_2),
      .OUT_FLAG_BITSTREAM (out_arith_flag)
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
      .in_arith_bitstream_1 (out_arith_bitstream_1),
      .in_arith_bitstream_2 (out_arith_bitstream_2),
      .in_arith_range (out_arith_range),
      .in_arith_cnt(out_arith_cnt),
      .in_arith_low (out_arith_low),
      .in_arith_flag (out_arith_flag),
      // outputs
      .out_carry_bit_1 (OUT_BIT_1),
      .out_carry_bit_2 (OUT_BIT_2),
      .out_carry_bit_3 (OUT_BIT_3),
      .out_carry_bit_4 (OUT_BIT_4),
      .out_carry_bit_5 (OUT_BIT_5),
      .out_carry_flag_bitstream (OUT_FLAG_BITSTREAM),
      .output_flag_last (OUT_FLAG_LAST)
    );
endmodule
