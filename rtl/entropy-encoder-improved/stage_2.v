/*
This stage finishes the encoding Q15 process and also executes the one-round
normalization
The One-round normalization is an adaptation of the following article:
  @INPROCEEDINGS{6116523,
    author={Z. {Liu} and D. {Wang}},
    booktitle={2011 18th IEEE International Conference on Image Processing},
    title={One-round renormalization based 2-bin/cycle H.264/AVC CABAC encoder},
    year={2011},
    volume={},
    number={},
    pages={369-372},
    doi={10.1109/ICIP.2011.6116523}
  }
*/

module stage_2 #(
  parameter RANGE_WIDTH = 16,
  parameter D_SIZE = 5,
  parameter SYMBOL_WIDTH = 4
  )(
    input [(RANGE_WIDTH-1):0] UU, VV, in_range, lut_u, lut_v,
    input COMP_mux_1,
    // bool
    input [(SYMBOL_WIDTH-1):0] symbol,
    input bool_flag,
    // former stage 3 outputs
    output wire [RANGE_WIDTH:0] u, v_bool,
    output wire [(RANGE_WIDTH-1):0] initial_range, out_range,
    output wire [(D_SIZE-1):0] out_d,
    output wire [1:0] bool_symbol,
    output wire COMP_mux_1_out
  );
  wire [(RANGE_WIDTH-1):0] range_bool, range_cdf, range_raw;

  s2_cdf #(
    .RANGE_WIDTH (RANGE_WIDTH)
    ) s2_cdf (
      .UU (UU),
      .VV (VV),
      .in_range (in_range),
      .lut_u (lut_u),
      .lut_v (lut_v),
      .COMP_mux_1 (COMP_mux_1),
      // Outputs
      .u (u),
      .out_range (range_cdf)
  );

  // bool
  s2_bool #(
    .RANGE_WIDTH (RANGE_WIDTH),
    .SYMBOL_WIDTH (SYMBOL_WIDTH)
    ) s2_bool (
      .in_range (in_range),
      .symbol (symbol),
      // Outputs
      .out_range (range_bool),
      .out_v (v_bool)
  );
  // -------------------
  // Range_raw: range prior to renormalization
  assign range_raw =  (bool_flag == 1'b1) ? range_bool :
                      range_cdf;

  // Renormalization block
  s2_renormalization #(
    .RANGE_WIDTH (RANGE_WIDTH),
    .D_SIZE (D_SIZE)
    ) s2_norm (
      .range_raw (range_raw),
      // Outputs
      .d_out (out_d),
      .range_final (out_range)
  );

  // outputs
  // v_bool is above
  // u is above
  assign initial_range = in_range;
  assign bool_symbol = {bool_flag, symbol[0]}; // this input is a mix
     // between the least significant bit of symbol and the bool flag
   // [1]: bool flag; [0]: symbol[0]
  assign COMP_mux_1_out = COMP_mux_1;
endmodule

module s2_cdf #(
  parameter RANGE_WIDTH = 16
  )(
    input [(RANGE_WIDTH-1):0] UU, VV, in_range, lut_u, lut_v,
    input COMP_mux_1,
    // Outputs
    output wire [RANGE_WIDTH:0] u,
    output wire [(RANGE_WIDTH-1):0] out_range
  );
  // Non-boolean block
  // u = ((Range_in >> 8) * (FL >> 6) >> 1) + 4 * (N - (s - 1))
  // v = ((Range_in >> 8) * (FH >> 6) >> 1) + 4 * (N - (s - 0))
  wire [(RANGE_WIDTH-1):0] RR, range_1, range_2;
  wire [(RANGE_WIDTH):0] v;

  assign RR = in_range >> 8;

  assign u = (RR * UU >> 1) + lut_u;
  assign v = (RR * VV >> 1) + lut_v;

  assign range_1 = u[(RANGE_WIDTH-1):0] - v[(RANGE_WIDTH-1):0];
  assign range_2 = in_range - v[(RANGE_WIDTH-1):0];

  assign out_range =  (COMP_mux_1 == 1'b1) ? range_1 :
                      range_2;
endmodule

module s2_bool #(
  parameter RANGE_WIDTH = 16,
  parameter SYMBOL_WIDTH = 4
  )(
    input [(RANGE_WIDTH-1):0] in_range,
    input [(SYMBOL_WIDTH-1):0] symbol,
    output wire [(RANGE_WIDTH-1):0] out_range,
    output wire [RANGE_WIDTH:0] out_v
  );
  // Boolean block
  // As the probability is fixed to 50%, it is possible to change the
  // original formula:
  // v = ((Range_in >> 8) * (Prob >> 6) >> 1) + 4
  // Prob = 50% = 16384; 16384 >> 6 = 256
  assign out_v = ((in_range >> 8) << 7) + 16'd4;

  assign out_range =  (symbol[0] == 1'b1) ? out_v[(RANGE_WIDTH-1):0] :
                      in_range - out_v[(RANGE_WIDTH-1):0];
endmodule

module s2_renormalization #(
  parameter RANGE_WIDTH = 16,
  parameter D_SIZE = 5
  )(
    input [(RANGE_WIDTH-1):0] range_raw,
    output wire [(D_SIZE-1):0] d_out,  // LZC result
    output wire [(RANGE_WIDTH-1):0] range_final
  );
  wire v_lzc; // Validation bit for the LZC isn't being used

  leading_zero #(
    .RANGE_WIDTH_LCZ (RANGE_WIDTH),
    .D_SIZE_LZC (D_SIZE)
    ) lzc (
      .in_range (range_raw),
      .v (v_lzc),
      .lzc_out (d_out)
  );
  assign range_final = range_raw << d_out;
endmodule
