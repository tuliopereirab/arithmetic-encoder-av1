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
    input [(SYMBOL_WIDTH-1):0] symbol_1, symbol_2,
    input bool_flag_1, bool_flag_2,
    // former stage 3 outputs
    output wire [RANGE_WIDTH:0] u,
    output wire [(RANGE_WIDTH-1):0] pre_low_1, pre_low_2,
    output wire [(RANGE_WIDTH-1):0] initial_range_1, initial_range_2, out_range,
    output wire [(D_SIZE-1):0] out_d_1, out_d_2,
    output wire bool_1, bool_2, symbol_out_1, symbol_out_2,
    output wire COMP_mux_1_out
  );
  wire [(RANGE_WIDTH-1):0] range_bool_1, range_bool_2, range_cdf;
  wire [(D_SIZE-1):0] d_cdf, d_bool_1, d_bool_2;


  // CDF block returns the Range already normalized
  s2_cdf #(
    .RANGE_WIDTH (RANGE_WIDTH),
    .D_SIZE (D_SIZE)
    ) s2_cdf (
      .UU (UU),
      .VV (VV),
      .in_range (in_range),
      .lut_u (lut_u),
      .lut_v (lut_v),
      .COMP_mux_1 (COMP_mux_1),
      // Outputs
      .u (u),
      .out_range (range_cdf),
      .d_out (d_cdf)
  );

  // bool
  s2_bool #(
    .RANGE_WIDTH (RANGE_WIDTH),
    .SYMBOL_WIDTH (SYMBOL_WIDTH)
    ) s2_bool_1 (
      .in_range (in_range),
      .symbol (symbol_1),
      // Outputs
      .out_range (range_bool_1),
      .range_1 (pre_low_1),
      .out_d (d_bool_1)
  );

  s2_bool #(
    .RANGE_WIDTH (RANGE_WIDTH),
    .SYMBOL_WIDTH (SYMBOL_WIDTH)
    ) s2_bool_2 (
      .in_range (range_bool_1),
      .symbol (symbol_2),
      // Outputs
      .out_range (range_bool_2),
      .range_1 (pre_low_2),
      .out_d (d_bool_2)
  );
  // -------------------
  // Outputs
  assign out_range =  (bool_flag_1) ? ((bool_flag_2) ? range_bool_2 :
                                      range_bool_1) :
                      range_cdf;
  assign out_d_1 =  (bool_flag_1) ? d_bool_1 :
                    d_cdf;
  assign out_d_2 = d_bool_2;
  assign initial_range_1 = in_range;
  assign initial_range_2 = range_bool_1;// Output from Bool_1 = Input of Bool_2
  assign bool_1 = bool_flag_1;
  assign bool_2 = bool_flag_2;
  assign symbol_out_1 = symbol_1[0];
  assign symbol_out_2 = symbol_2[0];
  assign COMP_mux_1_out = COMP_mux_1;
endmodule

module s2_cdf #(
  parameter RANGE_WIDTH = 16,
  parameter D_SIZE = 5
  )(
    input [(RANGE_WIDTH-1):0] UU, VV, in_range, lut_u, lut_v,
    input COMP_mux_1,
    // Outputs
    output wire [RANGE_WIDTH:0] u,
    output wire [(D_SIZE-1):0] d_out,
    output wire [(RANGE_WIDTH-1):0] out_range
  );
  // Non-boolean block
  // u = ((Range_in >> 8) * (FL >> 6) >> 1) + 4 * (N - (s - 1))
  // v = ((Range_in >> 8) * (FH >> 6) >> 1) + 4 * (N - (s - 0))
  wire [(RANGE_WIDTH-1):0] RR, range_1, range_2, range_raw;
  wire [(RANGE_WIDTH):0] v;

  assign RR = in_range >> 8;

  assign u = (RR * UU >> 1) + lut_u;
  assign v = (RR * VV >> 1) + lut_v;

  assign range_1 = u[(RANGE_WIDTH-1):0] - v[(RANGE_WIDTH-1):0];
  assign range_2 = in_range - v[(RANGE_WIDTH-1):0];

  assign range_raw =  (COMP_mux_1 == 1'b1) ? range_1 :
                      range_2;
  s2_renormalization #(
    .RANGE_WIDTH (RANGE_WIDTH),
    .D_SIZE (D_SIZE)
    ) s2_cdf_norm (
      .range_raw (range_raw),
      // Outputs
      .d_out (d_out),
      .range_final (out_range)
    );
endmodule

module s2_bool #(
  parameter RANGE_WIDTH = 16,
  parameter SYMBOL_WIDTH = 4,
  parameter D_SIZE = 5
  )(
    input [(RANGE_WIDTH-1):0] in_range,
    input [(SYMBOL_WIDTH-1):0] symbol,
    output wire [(D_SIZE-1):0] out_d,
    output wire [(RANGE_WIDTH-1):0] range_1, out_range
  );
  wire [(RANGE_WIDTH-1):0] range_raw;
  wire [RANGE_WIDTH:0] out_v;
  /* Boolean block
      As the probability is fixed to 50%, it is possible to change the
      original formula:
      v = ((Range_in >> 8) * (Prob >> 6) >> 1) + 4
      Prob = 50% = 16384; 16384 >> 6 = 256
  */
  assign out_v = ((in_range >> 8) << 7) + 16'd4;
  /* pre_low_bool (here range_1) is a way to use an operation already being done
  here inside Stage 3 and therefore reduce the excessive delay created by the
  parallel Boolean Operations.
  */
  assign range_1 = in_range - out_v[(RANGE_WIDTH-1):0];

  assign range_raw =  (symbol[0] == 1'b1) ? out_v[(RANGE_WIDTH-1):0] :
                      range_1;

  /* The renormalizaton process for the boolean operation doesn't require
  the use of LZC because D will never be greater than 2.
    Hence, instead of wasting area and time running the LZC here, a simple mux
  can tackle the problem.
    Assuming the worst-case scenario, in_range = 32768 and symbol[0] = 0,
  range_raw will be 16380, which generates a D = 2. */
  assign out_d =  (range_raw[RANGE_WIDTH-1] == 1'b1) ? 5'd0 :
                  (range_raw[RANGE_WIDTH-2] == 1'b1) ? 5'd1 :
                  5'd2;
  assign out_range = range_raw << out_d;
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
  assign d_out[(D_SIZE-1)] = 1'b0;
  lzc_miao_16 lzc (
      .in (range_raw),
      .v (v_lzc),
      .out_z (d_out[3:0])
  );
  assign range_final = range_raw << d_out;
endmodule
