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
    input COMP_mux_1,
    input bool_flag_1, bool_flag_2, bool_flag_3,
    input [(RANGE_WIDTH-1):0] UU, VV, in_range, lut_u, lut_v, lut_uv,
    input [(SYMBOL_WIDTH-1):0] in_symbol_1, in_symbol_2, in_symbol_3,
    // Outputs
    output wire COMP_mux_1_out,
    output wire out_bool_1, out_bool_2, out_bool_3,
    output wire out_symbol_1, out_symbol_2, out_symbol_3, // LSB symbol
    output wire [RANGE_WIDTH:0] u,
    output wire [(D_SIZE-1):0] out_d_1, out_d_2, out_d_3,
    output wire [(RANGE_WIDTH-1):0] pre_calc_low_bool_1, pre_calc_low_bool_2,
    output wire [(RANGE_WIDTH-1):0] pre_calc_low_bool_3,
    output wire [(RANGE_WIDTH-1):0] initial_range_1, initial_range_2,
    output wire [(RANGE_WIDTH-1):0] initial_range_3, out_range
  );
  wire [(RANGE_WIDTH-1):0] normalized_range_in;
  wire [(RANGE_WIDTH-1):0] range_bool_1, range_bool_2, range_bool_3;
  wire [(RANGE_WIDTH-1):0] range_cdf, range_bool;
  wire [3:0] d_normalize;
  wire v_lzc_bool;


  /* As CDF doesn't normalize the Range value before releasing it,
  it is necessary to normalize it first in order to execute the COMP_mux_1 == 0
  option and the Boolean sequence. */
  lzc_miao_16 lzc_norm_in (.in (in_range), .out_z (d_normalize),
                            .v (v_lzc_bool));
  assign normalized_range_in = in_range << d_normalize;

  // CDF Operation
  s2_cdf #(
    .RANGE_WIDTH (RANGE_WIDTH),
    .D_SIZE (D_SIZE)
    ) s2_cdf (
      .UU (UU),
      .VV (VV),
      .lut_u (lut_u),
      .lut_v (lut_v),
      .lut_uv (lut_uv),
      .in_range (in_range),
      .normalized_range_in (normalized_range_in),
      .COMP_mux_1 (COMP_mux_1),
      // Outputs
      .u (u),
      .out_range (range_cdf)
  );

  /* Boolean Operation
      - The Parallelized Boolean estimates the use of 3 Booleans that generate
    outputs at the same clock cycle (therefore parallel).
      - In reality, they are sequential. However, if observed from the top
    entity blocks, their results arrive all together and, therefore, in
    parallel.
  */
  s2_bool #(
    .RANGE_WIDTH (RANGE_WIDTH),
    .SYMBOL_WIDTH (SYMBOL_WIDTH),
    .D_SIZE (D_SIZE)
    ) s2_bool_1 (
      .in_range (normalized_range_in),
      .symbol (in_symbol_1),
      // Outputs
      .out_d (out_d_1),
      .range_1 (pre_calc_low_bool_1),
      .out_range (range_bool_1)
  );
  s2_bool #(
    .RANGE_WIDTH (RANGE_WIDTH),
    .SYMBOL_WIDTH (SYMBOL_WIDTH),
    .D_SIZE (D_SIZE)
    ) s2_bool_2 (
      .symbol (in_symbol_2),
      .in_range (range_bool_1),
      // Outputs
      .out_d (out_d_2),
      .range_1 (pre_calc_low_bool_2),
      .out_range (range_bool_2)
  );
  s2_bool #(
    .RANGE_WIDTH (RANGE_WIDTH),
    .SYMBOL_WIDTH (SYMBOL_WIDTH),
    .D_SIZE (D_SIZE)
    ) s2_bool_3 (
      .symbol (in_symbol_3),
      .in_range (range_bool_2),
      // Outputs
      .out_d (out_d_3),
      .range_1 (pre_calc_low_bool_3),
      .out_range (range_bool_3)
  );
  // -------------------
  // Find the last valid Bool block
  assign range_bool = (bool_flag_3 == 1'b1) ? range_bool_3 :
                      (bool_flag_2 == 1'b1) ? range_bool_2 :
                      (bool_flag_1 == 1'b1) ? range_bool_1 :
                      16'd0;

  // Output assignments
  assign initial_range_1 = normalized_range_in;
  assign initial_range_2 =  (bool_flag_2 == 1'b1) ? range_bool_1 :
                            16'd0;
  assign initial_range_3 =  (bool_flag_3 == 1'b1) ? range_bool_2 :
                            16'd0;
  assign out_range =  (bool_flag_1 == 1'b1) ? range_bool :
                      range_cdf;

  assign COMP_mux_1_out = COMP_mux_1;
  assign out_bool_1 = bool_flag_1;
  assign out_bool_2 = bool_flag_2;
  assign out_bool_3 = bool_flag_3;
  assign out_symbol_1 = in_symbol_1;
  assign out_symbol_2 = in_symbol_2;
  assign out_symbol_3 = in_symbol_3;
endmodule

module s2_cdf #(
  parameter RANGE_WIDTH = 16,
  parameter D_SIZE = 5
  )(
    input COMP_mux_1,
    input [(RANGE_WIDTH-1):0] UU, VV, in_range, lut_u, lut_v, lut_uv,
    input [(RANGE_WIDTH-1):0] normalized_range_in,
    output wire [RANGE_WIDTH:0] u,
    output wire [(RANGE_WIDTH-1):0] out_range
  );
  // Non-boolean block
  // u = ((Range_in >> 8) * (FL >> 6) >> 1) + 4 * (N - (s - 1))
  // v = ((Range_in >> 8) * (FH >> 6) >> 1) + 4 * (N - (s - 0))
  wire [(RANGE_WIDTH-1):0] range_1, range_2;
  reg [((RANGE_WIDTH/2)-1):0] RR;
  wire [(RANGE_WIDTH):0] temp_u, v;
  wire [9:0] UU_mult, VV_mult;
  wire [2:0] rr_d;
  wire v_lzc;

  assign UU_mult = UU[9:0];
  assign VV_mult = VV[9:0];

  /*  Stage 2 isn't required to generate an already-normalized Range.
    As the normalization is a left-shift and RR is represented by a right-shift,
  then RR = (d >= 8) ? in_range[7:0] : RR = in_range >> (8 - d) */
  lzc_miao_8 lzc_cdf (.in (in_range[(RANGE_WIDTH-1):(RANGE_WIDTH/2)]),
                      .out_z (rr_d), .v (v_lzc));

  always @ (rr_d, in_range) begin
    case (rr_d)
      3'd0: RR = in_range >> 8;
      3'd1: RR = in_range >> 7;
      3'd2: RR = in_range >> 6;
      3'd3: RR = in_range >> 5;
      3'd4: RR = in_range >> 4;
      3'd5: RR = in_range >> 3;
      3'd6: RR = in_range >> 2;
      3'd7: RR = in_range >> 1;
      default: RR = in_range[((RANGE_WIDTH/2)-1):0];
    endcase
  end

  assign temp_u = (RR * UU_mult >> 1);
  // u adapted from: u = (RR * UU >> 1) + lut_u
  assign u = temp_u + lut_u;
  // v adapted from: v = (RR * VV >> 1) + lut_v
  assign v = (RR * VV_mult >> 1);

  // range_1 adapted from: range_1 = u - v
  assign range_1 = (temp_u[(RANGE_WIDTH-1):0] - v[(RANGE_WIDTH-1):0]) + lut_uv;
  // range_1 adapted from: range_2 = in_range - v
  assign range_2 = (normalized_range_in - lut_v) - v[(RANGE_WIDTH-1):0];

  assign out_range =  (COMP_mux_1) ? range_1 :    // Range_raw because I don't
                      range_2;                  // need to renormalize it here.
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
  wire [(RANGE_WIDTH-1):0] range_raw, RR;
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
