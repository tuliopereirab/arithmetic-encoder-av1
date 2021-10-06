module stage_1 #(
  parameter RANGE_WIDTH = 16,
  parameter LOW_WIDTH = 24,
  parameter SYMBOL_WIDTH = 4,
  parameter LUT_ADDR_WIDTH = 8,
  parameter LUT_DATA_WIDTH = 16
  )(
    /*
      For the Boolean Parallelization, it was added a few new inputs:
        - SYMBOL 1, 2 and 3, where 2 and 3 represent the next round's inputs;
        - out_symbol 1, 2 and 3, where 2 and 3 are used only to pass forward
      their input counterparts;
        - Bool_Flag 1, 2 and 3 (inputs and outputs).
    */
    input clk_stage_1, bool_flag_1, bool_flag_2, bool_flag_3,
    /* is the flag showing if it is a bool_flag or not.
      Input: 0- bool_flag, 1- not bool_flag (this is inverted in this stage) */
    input [(RANGE_WIDTH-1):0] FL, FH,
    input [(SYMBOL_WIDTH-1):0] SYMBOL_1, SYMBOL_2, SYMBOL_3,
                                      // receives the symbol (0 <= SYMB <= 15)
    input [SYMBOL_WIDTH:0] NSYMS,   // defined as 1 bit longer than SYMBOL;
                                    // nsyms receives the number of symbols used
    output wire [(RANGE_WIDTH-1):0] op_iso_bool_1, op_iso_bool_2, op_iso_bool_3,
    output wire COMP_mux_1, bool_out_1, bool_out_2, bool_out_3,
    output wire [(LUT_DATA_WIDTH-1):0] lut_u_out, lut_v_out, lut_uv_out,
    output wire [(SYMBOL_WIDTH-1):0] out_symbol_1, out_symbol_2, out_symbol_3,
    output wire [(RANGE_WIDTH-1):0] UU, VV
  );

  wire [SYMBOL_WIDTH:0] N_5bits;
  wire [(SYMBOL_WIDTH-1):0] N;
  wire [(LUT_ADDR_WIDTH-1):0] lut_addr;
  // ---------------------
  /* Due to the tight arrangement within Stages 2 and 3, the Operand Isolation
  variable must be defined in Stage 1 and be passed forward with registers. */
  assign op_iso_bool_1 =  (bool_out_1) ? 24'd16777215 :
                          24'd0;
  assign op_iso_bool_2 =  (bool_out_1 && bool_out_2) ? 24'd16777215 :
                          24'd0;
  assign op_iso_bool_3 =  (bool_out_1 &&
                            bool_out_2 && bool_out_3) ? 24'd16777215 :
                          24'd0;
  // ---------------------

  assign N_5bits = NSYMS - 5'd1;
  assign N = N_5bits[(SYMBOL_WIDTH-1):0];
  assign lut_addr = {N, SYMBOL_1};

  assign UU = FL >> 16'd6;
  assign VV = FH >> 16'd6;

  assign COMP_mux_1 = (FL < 16'd32768) ? 1'b1 :
                      1'b0;

  assign lut_uv_out = lut_u_out - lut_v_out;
  assign out_symbol_1 = SYMBOL_1;
  assign out_symbol_2 = SYMBOL_2;
  assign out_symbol_3 = SYMBOL_3;
  assign bool_out_1 = ~bool_flag_1;
  assign bool_out_2 = ~bool_flag_2;
  assign bool_out_3 = ~bool_flag_3;

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
