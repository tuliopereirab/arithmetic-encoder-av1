// To check later
// 1- Make the bitstream generation (out_bit_1/2) to be 9-bit arrays

module stage_3 #(
  parameter RANGE_WIDTH = 16,
  parameter LOW_WIDTH = 24,
  parameter D_SIZE = 5
  ) (
    input COMP_mux_1,
    input [(D_SIZE-1):0] in_s,
    input [(LOW_WIDTH-1):0] in_low,
    input [(D_SIZE-1):0] d_1, d_2, d_3,
    input in_bool_1, in_bool_2, in_bool_3,
    input in_symbol_1, in_symbol_2, in_symbol_3,
    input [RANGE_WIDTH:0] u,
    input [(RANGE_WIDTH-1):0] pre_low_bool_1, pre_low_bool_2, pre_low_bool_3,
    input [(RANGE_WIDTH-1):0] in_range_1, in_range_2, in_range_3, range_ready,
    output wire [(D_SIZE-1):0] out_s,
    output wire [(LOW_WIDTH-1):0] out_low,
    output wire [(RANGE_WIDTH-1):0] out_range,
    output wire [(RANGE_WIDTH-1):0] OUT_BIT_1_1, OUT_BIT_1_2,
    output wire [(RANGE_WIDTH-1):0] OUT_BIT_2_1, OUT_BIT_2_2,
    output wire [(RANGE_WIDTH-1):0] OUT_BIT_3_1, OUT_BIT_3_2,
    output wire [1:0] FLAG_BIT_1, FLAG_BIT_2, FLAG_BIT_3
  );
  wire [(LOW_WIDTH-1):0] low_bool_1, low_bool_2, low_bool_3, low_cdf;
  wire [(D_SIZE-1):0] s_cdf, s_bool_1, s_bool_2, s_bool_3;
  wire [(RANGE_WIDTH-1):0] out_bit_1_cdf, out_bit_2_cdf;    // For the 1st cdf
  // Architecture Outputs
  wire [1:0] flag_cdf_1;   // For the 1st both
  wire [1:0] flag_bool_1, flag_bool_2, flag_bool_3;
  wire [(RANGE_WIDTH-1):0] bool_out_bit_1_1, bool_out_bit_1_2;
  wire [(RANGE_WIDTH-1):0] bool_out_bit_2_1, bool_out_bit_2_2;
  wire [(RANGE_WIDTH-1):0] bool_out_bit_3_1, bool_out_bit_3_2;

  // Operand Isolation
  wire [(LOW_WIDTH-1):0] op_bool_1, op_bool_2, op_bool_3;
  assign op_bool_1 =  (in_bool_1) ? 24'd16777215 :
                      24'd0;
  assign op_bool_2 =  (in_bool_1 && in_bool_2) ? 24'd16777215 :
                      24'd0;
  assign op_bool_3 =  (in_bool_1 && in_bool_2 && in_bool_3) ?
                                                                24'd16777215 :
                      24'd0;
  // -----------------------------------------------------

  s3_cdf #(
    .D_SIZE (D_SIZE),
    .LOW_WIDTH (LOW_WIDTH),
    .RANGE_WIDTH (RANGE_WIDTH)
    ) s3_cdf (
      .u (u),
      .in_d (d_1),
      .in_s (in_s),
      .in_low (in_low),
      .in_range (in_range_1),
      .COMP_mux_1 (COMP_mux_1),
      // Outputs
      .out_s (s_cdf),
      .out_low (low_cdf),
      .out_bit_1 (out_bit_1_cdf),
      .out_bit_2 (out_bit_2_cdf),
      .flag_bitstream (flag_cdf_1)
    );

  /* Boolean Operation
      - The Parallelized Boolean estimates the use of 3 Booleans that generate
    outputs at the same clock cycle (therefore parallel).
      - In reality, they are sequential. However, if observed from the top
    entity blocks, their results arrive all together and, therefore, in
    parallel.
  */
  s3_bool #(
    .D_SIZE (D_SIZE),
    .LOW_WIDTH (LOW_WIDTH),
    .RANGE_WIDTH (RANGE_WIDTH)
    ) s3_bool_1 (
      .in_d (d_1 & op_bool_1[(D_SIZE-1):0]),
      .in_s (in_s & op_bool_1[(D_SIZE-1):0]),
      .in_low (in_low & op_bool_1),
      .symbol (in_symbol_1),
      .pre_low (pre_low_bool_1 & op_bool_1[(RANGE_WIDTH-1):0]),
      .in_range (in_range_1 & op_bool_1[(RANGE_WIDTH-1):0]),
      // Outputs
      .out_s (s_bool_1),
      .out_low (low_bool_1),
      .out_bit_1 (bool_out_bit_1_1),
      .out_bit_2 (bool_out_bit_1_2),
      .flag_bitstream (flag_bool_1)
  );
  s3_bool #(
    .D_SIZE (D_SIZE),
    .LOW_WIDTH (LOW_WIDTH),
    .RANGE_WIDTH (RANGE_WIDTH)
    ) s3_bool_2 (
      .in_d (d_2 & op_bool_2[(D_SIZE-1):0]),
      .in_s (s_bool_1 & op_bool_2[(D_SIZE-1):0]),
      .in_low (low_bool_1 & op_bool_2),
      .symbol (in_symbol_2),
      .pre_low (pre_low_bool_2 & op_bool_2[(RANGE_WIDTH-1):0]),
      .in_range (in_range_2 & op_bool_2[(RANGE_WIDTH-1):0]),
      // Outputs
      .out_s (s_bool_2),
      .out_low (low_bool_2),
      .out_bit_1 (bool_out_bit_2_1),
      .out_bit_2 (bool_out_bit_2_2),
      .flag_bitstream (flag_bool_2)
  );
  s3_bool #(
    .D_SIZE (D_SIZE),
    .LOW_WIDTH (LOW_WIDTH),
    .RANGE_WIDTH (RANGE_WIDTH)
    ) s3_bool_3 (
      .in_d (d_3 & op_bool_3[(D_SIZE-1):0]),
      .in_s (s_bool_2 & op_bool_3[(D_SIZE-1):0]),
      .in_low (low_bool_2 & op_bool_3),
      .symbol (in_symbol_3),
      .pre_low (pre_low_bool_3 & op_bool_3[(RANGE_WIDTH-1):0]),
      .in_range (in_range_3 & op_bool_3[(RANGE_WIDTH-1):0]),
      // Outputs
      .out_s (s_bool_3),
      .out_low (low_bool_3),
      .out_bit_1 (bool_out_bit_3_1),
      .out_bit_2 (bool_out_bit_3_2),
      .flag_bitstream (flag_bool_3)
  );
  // Outputs Assignments
  assign out_s =  (in_bool_1 == 1'b1) ? ((in_bool_3) ? s_bool_3 :
                                        (in_bool_2) ? s_bool_2 :
                                        s_bool_1) :
                  s_cdf;
  assign out_low =  (in_bool_1 == 1'b1) ? ((in_bool_3) ? low_bool_3 :
                                          (in_bool_2) ? low_bool_2 :
                                          low_bool_1) :
                    low_cdf;
  // ------------------------------------------------------
  assign OUT_BIT_1_1 =  (in_bool_1 == 1'b1) ? bool_out_bit_1_1 :
                        out_bit_1_cdf;
  assign OUT_BIT_1_2 =  (in_bool_1 == 1'b1) ? bool_out_bit_1_2 :
                        out_bit_2_cdf;

  /* In order to reduce the delay, sometimes there OUT_BIT 2_x and 3_x will
  receive a valid number instead of zero. This reduces the delay by 1 mux and
  might be benefitial here.
    The validation of these OUT_BITs will be done by the corresponding FLAG_BIT.
  */
  assign OUT_BIT_2_1 = bool_out_bit_2_1;
  assign OUT_BIT_2_2 = bool_out_bit_2_2;

  assign OUT_BIT_3_1 = bool_out_bit_3_1;
  assign OUT_BIT_3_2 = bool_out_bit_3_2;

  assign FLAG_BIT_1 = (in_bool_1 == 1'b1) ? flag_bool_1 :
                      flag_cdf_1;
  assign FLAG_BIT_2 = (in_bool_2 == 1'b1) ? flag_bool_2 :
                      2'd0;
  assign FLAG_BIT_3 = (in_bool_3 == 1'b1) ? flag_bool_3 :
                      2'd0;
  // ------------------------------------------------------
  /*  Variables already assigned upon the modules' output:
      - Flags bitstream 2 and 3;
      - Out Bitstreams 2_x and 3_x. */
  assign out_range = range_ready;
endmodule

module s3_cdf #(
  parameter D_SIZE = 5,
  parameter LOW_WIDTH = 24,
  parameter RANGE_WIDTH = 16
  )(
    input COMP_mux_1,
    input [RANGE_WIDTH:0] u,
    input [(LOW_WIDTH-1):0] in_low,
    input [(D_SIZE-1):0] in_d, in_s,
    input [(RANGE_WIDTH-1):0] in_range,
    // Outputs
    output wire [1:0] flag_bitstream,
    output wire [(D_SIZE-1):0] out_s,
    output wire [(LOW_WIDTH-1):0] out_low,
    output wire [(RANGE_WIDTH-1):0] out_bit_1, out_bit_2
  );
  wire [(LOW_WIDTH-1):0] low_1, low_raw;
  assign low_1 = in_low + (in_range - u[(RANGE_WIDTH-1):0]);

  assign low_raw =  (COMP_mux_1 == 1'b1) ? low_1 :
                    in_low;
  s3_renormalization # (
    .D_SIZE (D_SIZE),
    .LOW_WIDTH (LOW_WIDTH),
    .RANGE_WIDTH (RANGE_WIDTH)
    ) s3_cdf_norm (
      .d (in_d),
      .in_s (in_s),
      .low_raw (low_raw),
      // Outputs
      .out_s (out_s),
      .out_low (out_low),
      .out_bit_1 (out_bit_1),
      .out_bit_2 (out_bit_2),
      .flag_bitstream (flag_bitstream)
    );
endmodule

module s3_bool #(
  parameter D_SIZE = 5,
  parameter LOW_WIDTH = 24,
  parameter RANGE_WIDTH = 16
  )(
    input symbol,
    input [(LOW_WIDTH-1):0] in_low,
    input [(D_SIZE-1):0] in_d, in_s,
    input [(RANGE_WIDTH-1):0] in_range, pre_low,
    // Outputs
    output wire [1:0] flag_bitstream,
    output wire [(D_SIZE-1):0] out_s,
    output wire [(LOW_WIDTH-1):0] out_low,
    output wire [(RANGE_WIDTH-1):0] out_bit_1, out_bit_2
  );
  wire [(LOW_WIDTH-1):0] low_1, low_raw;
  /* Pre_low is a variable calculated within the Boolean block in Stage 2.
    Its creation was specifically done to reduce the stress generated by the
  parallelized Boolean blocks in Stage 3.
    Pre_low = in_range - v_bool
  */
  assign low_1 = in_low + pre_low;

  assign low_raw =  (symbol == 1'b1) ? low_1 :
                    in_low;
  s3_renormalization #(
    .D_SIZE (D_SIZE),
    .LOW_WIDTH (LOW_WIDTH),
    .RANGE_WIDTH (RANGE_WIDTH)
    ) s3_bool_norm (
      .d (in_d),
      .in_s (in_s),
      .low_raw (low_raw),
      // Outputs
      .out_s (out_s),
      .out_low (out_low),
      .out_bit_1 (out_bit_1),
      .out_bit_2 (out_bit_2),
      .flag_bitstream (flag_bitstream)
    );
endmodule

module s3_renormalization #(
  parameter LOW_WIDTH = 24,
  parameter RANGE_WIDTH = 16,
  parameter D_SIZE = 5
  )(
    input [(LOW_WIDTH-1):0] low_raw,
    input [(D_SIZE-1):0] d, in_s,
    // Outputs
    output wire [1:0] flag_bitstream,
    output wire [(D_SIZE-1):0] out_s,
    output wire [(LOW_WIDTH-1):0] out_low,
    output wire [(RANGE_WIDTH-1):0] out_bit_1, out_bit_2
  );
  wire [(LOW_WIDTH-1):0] low_s0, low_s8, m_s8, m_s0;
  wire [(D_SIZE-1):0] c_norm_s0, c_norm_s8, s_s0, s_s8;
  wire [(D_SIZE-1):0] s_comp;
  wire [(D_SIZE-1):0] c_bit_s0, c_bit_s8;

  assign s_comp = in_s + d;
  // ----------------------
  assign c_norm_s0 = in_s + 5'd7;
  assign m_s0 = (24'd1 << c_norm_s0) - 24'd1;

  // s_s0 adapted from: s0 = (in_s + 16) + d - 24
  assign s_s0 = in_s + d - 5'd8;
  assign low_s0 = low_raw & m_s0;
  // -----------------------
  assign c_norm_s8 = in_s - 5'd1;
  // m_s8 adapted from: m_s8 = m_s0 >> 8
  assign m_s8 = (24'd1 << c_norm_s8) - 24'd1;

  // s_s8 adapted from: s8 = (in_s + 8) + d - 24
  assign s_s8 = in_s + d - 5'd16;
  assign low_s8 = low_raw & m_s8;

  // pre-bitstream generation
  assign c_bit_s0 = in_s + 5'd7;
  assign c_bit_s8 = in_s - 5'd1;
  // =========================================================================
  // Outputs

  assign out_low =  ((s_comp >= 9) && (s_comp < 17)) ? low_s0 << d :
                    (s_comp >= 17) ? low_s8 << d :
                    low_raw << d;

  assign out_s =  ((s_comp >= 9) && (s_comp < 17)) ? s_s0 :
                  (s_comp >= 17) ? s_s8 :
                  s_comp;
  /*
    out_bit_1 and out_bit_2 are the pre-bitstreams generated by Stage 3.
    They are send to Stage 4 (carry propagation) for a reduction from a 9-bit to
  an 8-bit array.
  */
  assign out_bit_1 =  (s_comp >= 9) ? low_raw >> c_bit_s0 :
                      16'd0;
  assign out_bit_2 =  (s_comp >= 17) ? low_s0 >> c_bit_s8 :
                      16'd0;
  /*
  flag_bitstream represents how many pre-bitstreams are being in a given round
      01 (1): generating only out_bit_1
      10 (2): generating out_bit_1 and out_bit_2
  */

  assign flag_bitstream = ((s_comp >= 9) && (s_comp < 17)) ? 2'd1 :
                          (s_comp >= 17) ? 2'd2 :
                          2'd0;
endmodule
