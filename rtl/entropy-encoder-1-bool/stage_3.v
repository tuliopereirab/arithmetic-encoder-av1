// To check later
// 1- Make the bitstream generation (out_bit_1/2) to be 9-bit arrays

module stage_3 #(
  parameter RANGE_WIDTH = 16,
  parameter LOW_WIDTH = 24,
  parameter D_SIZE = 5
  ) (
    input [1:0] bool_symbol,  // Mix of the symb LSB and bool flag
                              // [1]: bool flag; [0]: symbol[0]
    input [(RANGE_WIDTH-1):0] in_range, range_ready,
    input [(D_SIZE-1):0] d,
    input COMP_mux_1,
    input [RANGE_WIDTH:0] u, v_bool,
    input [(D_SIZE-1):0] in_s,
    input [(LOW_WIDTH-1):0] in_low,
    output wire [(LOW_WIDTH-1):0] out_low,
    output wire [(RANGE_WIDTH-1):0] out_range,
    output wire [(RANGE_WIDTH-1):0] out_bit_1, out_bit_2,
    output wire [1:0] flag_bitstream,
    output wire [(D_SIZE-1):0] out_s
  );
  wire [(LOW_WIDTH-1):0] low_bool, low_cdf;
  wire [(LOW_WIDTH-1):0] low_raw;

  s3_cdf #(
    .LOW_WIDTH (LOW_WIDTH),
    .RANGE_WIDTH (RANGE_WIDTH)
    ) s3_cdf (
      .in_low (in_low),
      .in_range (in_range),
      .u (u),
      .COMP_mux_1 (COMP_mux_1),
      // Outputs
      .out_low (low_cdf)
    );

  s3_bool #(
    .LOW_WIDTH (LOW_WIDTH),
    .RANGE_WIDTH (RANGE_WIDTH)
    ) s3_bool (
      .in_low (in_low),
      .in_range (in_range),
      .v_bool (v_bool),
      .bool_symbol (bool_symbol),
      // Outputs
      .out_low (low_bool)
  );

  // ------------------------------------------------------
  assign low_raw =  (bool_symbol[1] == 1'b1) ? low_bool :
                    low_cdf;
  // ------------------------------------------------------
  // normalization
  s3_renormalization #(
    .LOW_WIDTH (LOW_WIDTH),
    .RANGE_WIDTH (RANGE_WIDTH),
    .D_SIZE (D_SIZE)
    ) s3_norm (
      .low_raw (low_raw),
      .d (d),
      .in_s (in_s),
      // Outputs
      .flag_bitstream (flag_bitstream),
      .out_s (out_s),
      .out_low (out_low),
      .out_bit_1 (out_bit_1),
      .out_bit_2 (out_bit_2)
    );
  // Assigned Outputs
  assign out_range = range_ready;
endmodule

module s3_cdf #(
  parameter LOW_WIDTH = 24,
  parameter RANGE_WIDTH = 16
  )(
    input [(LOW_WIDTH-1):0] in_low,
    input [(RANGE_WIDTH-1):0] in_range,
    input [RANGE_WIDTH:0] u,
    input COMP_mux_1,
    // Outputs
    output wire [(LOW_WIDTH-1):0] out_low
  );
  wire [(LOW_WIDTH-1):0] low_1;
  assign low_1 = in_low + (in_range - u[(RANGE_WIDTH-1):0]);

  assign out_low =  (COMP_mux_1 == 1'b1) ? low_1 :
                    in_low;
endmodule

module s3_bool #(
  parameter LOW_WIDTH = 24,
  parameter RANGE_WIDTH = 16
  )(
    input [(LOW_WIDTH-1):0] in_low,
    input [(RANGE_WIDTH-1):0] in_range,
    input [RANGE_WIDTH:0] v_bool,
    input [1:0] bool_symbol,
    // Outputs
    output wire [(LOW_WIDTH-1):0] out_low
  );
  wire [(LOW_WIDTH-1):0] low_1;
  assign low_1 = in_low + (in_range - v_bool[(RANGE_WIDTH-1):0]);

  assign out_low =  (bool_symbol[0] == 1'b1) ? low_1 :
                    in_low;
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
  wire [(D_SIZE-1):0] c_internal_s0, c_internal_s8, c_norm_s0, s_s0, s_s8;
  wire [(D_SIZE-1):0] s_comp;
  wire [(D_SIZE-1):0] c_bit_s0, c_bit_s8;

  assign s_comp = in_s + d;
  // ----------------------
  assign c_norm_s0 = in_s + 5'd7;
  assign c_internal_s0 = in_s + 5'd16;
  assign m_s0 = (24'd1 << c_norm_s0) - 24'd1;

  assign s_s0 = c_internal_s0 + d - 5'd24;
  assign low_s0 = low_raw & m_s0;
  // -----------------------
  assign c_internal_s8 = in_s + 5'd8;
  assign m_s8 = m_s0 >> 5'd8;

  assign s_s8 = c_internal_s8 + d - 5'd24;
  assign low_s8 = low_s0 & m_s8;

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
    out_bit_1 and out_bit_2 are the pre-bitstreams generated by Stage 3
    They are then send to Stage 4 (carry propagation)
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
