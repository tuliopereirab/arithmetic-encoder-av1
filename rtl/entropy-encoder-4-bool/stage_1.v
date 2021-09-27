module stage_1 #(
  parameter RANGE_WIDTH = 16,
  parameter SYMBOL_WIDTH = 4,
  parameter LUT_ADDR_WIDTH = 8,
  parameter LUT_DATA_WIDTH = 16
  )(
    input clk_stage_1, bool_flag_1, bool_flag_2, bool_flag_3, bool_flag_4,
    /* is the flag showing if it is a bool_flag or not.
      0- bool_flag, 1- not bool_flag (this is inverted in this stage) */
    input [(RANGE_WIDTH-1):0] FL, FH,
    input [(SYMBOL_WIDTH-1):0] SYMBOL_1, SYMBOL_2, SYMBOL_3, SYMBOL_4,
    input [SYMBOL_WIDTH:0] NSYMS,   // defined as 1 bit longer than SYMBOL;
                                    // nsyms receives the number of symbols used
    output wire COMP_mux_1, bool_out_1, bool_out_2, bool_out_3, bool_out_4,
    output wire [(LUT_DATA_WIDTH-1):0] lut_u_out, lut_v_out,
    output wire [(SYMBOL_WIDTH-1):0] out_symbol_1, out_symbol_2,
    output wire [(SYMBOL_WIDTH-1):0] out_symbol_3, out_symbol_4,
    output wire [(RANGE_WIDTH-1):0] UU, VV
  );

  wire [SYMBOL_WIDTH:0] N_5bits;
  wire [(SYMBOL_WIDTH-1):0] N;
  wire [(LUT_ADDR_WIDTH-1):0] lut_addr;
  // ---------------------

  assign N_5bits = NSYMS - 5'd1;
  assign N = N_5bits[(SYMBOL_WIDTH-1):0];
  assign lut_addr = {N, SYMBOL_1};

  assign UU = FL >> 16'd6;
  assign VV = FH >> 16'd6;

  assign COMP_mux_1 = (FL < 16'd32768) ? 1'b1 :
                      1'b0;

  assign bool_out_1 = ~bool_flag_1;
  assign bool_out_2 = ~bool_flag_2;
  assign bool_out_3 = ~bool_flag_3;
  assign bool_out_4 = ~bool_flag_4;
  assign out_symbol_1 = SYMBOL_1;
  assign out_symbol_2 = SYMBOL_2;
  assign out_symbol_3 = SYMBOL_3;
  assign out_symbol_4 = SYMBOL_4;

  lut_u_module #(
    .DATA_WIDTH (LUT_DATA_WIDTH),
    .ADDR_WIDTH (LUT_ADDR_WIDTH)
    ) lut_u (
      .addr (lut_addr),
      .q (lut_u_out)
    );
  lut_v_module #(
    .DATA_WIDTH (LUT_DATA_WIDTH),
    .ADDR_WIDTH (LUT_ADDR_WIDTH)
    ) lut_v (
      .addr (lut_addr),
      .q (lut_v_out)
    );
endmodule
