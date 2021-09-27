module arithmetic_encoder #(
  parameter GENERAL_RANGE_WIDTH = 16,
  parameter GENERAL_LOW_WIDTH = 24,
  parameter GENERAL_SYMBOL_WIDTH = 4,
  parameter GENERAL_LUT_ADDR_WIDTH = 8,
  parameter GENERAL_LUT_DATA_WIDTH = 16,
  parameter GENERAL_D_SIZE = 5
  )(
    input general_clk, reset,
    input [(GENERAL_RANGE_WIDTH-1):0] general_fl, general_fh,
    input [(GENERAL_SYMBOL_WIDTH-1):0] general_symbol_1, general_symbol_2,
    input [(GENERAL_SYMBOL_WIDTH-1):0] general_symbol_3, general_symbol_4,
    input [GENERAL_SYMBOL_WIDTH:0] general_nsyms,
    input general_bool_1, general_bool_2, general_bool_3, general_bool_4,
    output wire [(GENERAL_RANGE_WIDTH-1):0] RANGE_OUTPUT,
    output wire [(GENERAL_LOW_WIDTH-1):0] LOW_OUTPUT,
    output wire [(GENERAL_D_SIZE-1):0] CNT_OUTPUT,
    output wire [(GENERAL_RANGE_WIDTH-1):0] PB_1_1, PB_1_2, PB_2_1, PB_2_2,
    output wire [(GENERAL_RANGE_WIDTH-1):0] PB_3_1, PB_3_2, PB_4_1, PB_4_2,
    output wire [1:0] PB_FLAG_1, PB_FLAG_2, PB_FLAG_3, PB_FLAG_4
  );

  // general
  reg [(GENERAL_RANGE_WIDTH-1):0] reg_Range_s3;
  reg [(GENERAL_LOW_WIDTH-1):0] reg_Low_s34;
  reg [(GENERAL_D_SIZE-1):0] reg_cnt_s34;
  reg [1:0] reg_pb_flag_1, reg_pb_flag_2, reg_pb_flag_3, reg_pb_flag_4;
  reg [(GENERAL_RANGE_WIDTH-1):0] reg_pb_1_1, reg_pb_1_2;
  reg [(GENERAL_RANGE_WIDTH-1):0] reg_pb_2_1, reg_pb_2_2;
  reg [(GENERAL_RANGE_WIDTH-1):0] reg_pb_3_1, reg_pb_3_2;
  reg [(GENERAL_RANGE_WIDTH-1):0] reg_pb_4_1, reg_pb_4_2;
  assign RANGE_OUTPUT = reg_Range_s3;
  assign LOW_OUTPUT = reg_Low_s34;
  assign PB_FLAG_1 = reg_pb_flag_1;
  assign PB_1_1 = reg_pb_1_1;
  assign PB_1_2 = reg_pb_1_2;
  assign PB_FLAG_2 = reg_pb_flag_2;
  assign PB_2_1 = reg_pb_2_1;
  assign PB_2_2 = reg_pb_2_2;
  assign PB_FLAG_3 = reg_pb_flag_3;
  assign PB_3_2 = reg_pb_3_2;
  assign PB_3_2 = reg_pb_3_2;
  assign PB_FLAG_4 = reg_pb_flag_4;
  assign PB_4_2 = reg_pb_4_2;
  assign PB_4_2 = reg_pb_4_2;
  assign CNT_OUTPUT = reg_cnt_s34;

  // control unit
  wire ctrl_reg_1_2, ctrl_reg_2_3, ctrl_reg_final, ctrl_mux_reset;

  control_unit control (
    .clk (general_clk),
    .reset_ctrl (reset),
    //outputs
    .pipeline_reg_1_2 (ctrl_reg_1_2),
    .pipeline_reg_2_3 (ctrl_reg_2_3),
    .pipeline_reg_final (ctrl_reg_final)
    );


  // stage 1
  wire [(GENERAL_LUT_DATA_WIDTH-1):0] lut_u_output, lut_v_output;
  wire [(GENERAL_RANGE_WIDTH-1):0] uu_out, vv_out;
  wire [(GENERAL_SYMBOL_WIDTH-1):0] symbol_out_s12_1, symbol_out_s12_2;
  wire [(GENERAL_SYMBOL_WIDTH-1):0] symbol_out_s12_3, symbol_out_s12_4;
  wire COMP_mux_1_out, bool_out_s12_1, bool_out_s12_2;
  wire bool_out_s12_3, bool_out_s12_4;
  reg [(GENERAL_LUT_DATA_WIDTH-1):0] reg_lut_u, reg_lut_v;
  reg [(GENERAL_RANGE_WIDTH-1):0] reg_UU, reg_VV;
  reg [(GENERAL_SYMBOL_WIDTH-1):0] reg_symbol_s12_1, reg_symbol_s12_2;
  reg [(GENERAL_SYMBOL_WIDTH-1):0] reg_symbol_s12_3, reg_symbol_s12_4;
  reg reg_COMP_mux_1, reg_bool_s12_1, reg_bool_s12_2, reg_bool_s12_3;
  reg reg_bool_s12_4;
  // stage 2
  wire [(GENERAL_RANGE_WIDTH-1):0] initial_range_out_1, range_ready_out;
  wire [(GENERAL_RANGE_WIDTH-1):0] initial_range_out_2, initial_range_out_3;
  wire [(GENERAL_RANGE_WIDTH-1):0] initial_range_out_4;
  wire [GENERAL_RANGE_WIDTH:0] u_out;
  wire [(GENERAL_RANGE_WIDTH-1):0] pre_low_out_1, pre_low_out_2;
  wire [(GENERAL_RANGE_WIDTH-1):0] pre_low_out_3, pre_low_out_4;
  wire [(GENERAL_D_SIZE-1):0] d_out_1, d_out_2, d_out_3, d_out_4;
  wire [GENERAL_RANGE_WIDTH:0] v_bool_out;
  wire bool_s23_1, bool_s23_2, symbol_s23_1, symbol_s23_2;
  wire bool_s23_3, bool_s23_4, symbol_s23_3, symbol_s23_4;
  wire COMP_mux_1_out_s23;
  reg [(GENERAL_RANGE_WIDTH-1):0] reg_range_initial_1, reg_range_ready;
  reg [(GENERAL_RANGE_WIDTH-1):0] reg_range_initial_2, reg_pre_low_1;
  reg [(GENERAL_RANGE_WIDTH-1):0] reg_range_initial_3, reg_range_initial_4;
  reg [(GENERAL_RANGE_WIDTH-1):0] reg_pre_low_2, reg_pre_low_3, reg_pre_low_4;
  reg [GENERAL_RANGE_WIDTH:0] reg_u;
  reg [(GENERAL_D_SIZE-1):0] reg_d_1, reg_d_2, reg_d_3, reg_d_4;
  reg reg_bool_s23_1, reg_bool_s23_2, reg_symbol_s23_1, reg_symbol_s23_2;
  reg reg_bool_s23_3, reg_bool_s23_4, reg_symbol_s23_3, reg_symbol_s23_4;
  reg reg_COMP_mux_1_s23;
  // --------------------------------------------------
  // Stage 3
  wire [(GENERAL_RANGE_WIDTH-1):0] range_out_s3;
  wire [(GENERAL_LOW_WIDTH-1):0] low_out_s3;
  wire [(GENERAL_D_SIZE-1):0] s_out_s3;
  // Below are the output pins for the stage 3.
  wire [(GENERAL_RANGE_WIDTH-1):0] pb_1_1, pb_1_2, pb_2_1, pb_2_2;
  wire [(GENERAL_RANGE_WIDTH-1):0] pb_3_1, pb_3_2, pb_4_1, pb_4_2;
  wire [1:0] pb_flag_1, pb_flag_2, pb_flag_3, pb_flag_4;
  // ---------------------------------------------------
  // reset
  always @ (posedge general_clk) begin
    if(reset) begin
      reg_cnt_s34 <= 5'd0;
      reg_Range_s3 <= 16'd32768;     // not necessary
      reg_Low_s34 <= 24'd0;
    end
    else if(ctrl_reg_final) begin  //already saving stuff from the Stage [3,4,5]
      reg_Range_s3 <= range_out_s3;
      reg_Low_s34 <= low_out_s3;
      reg_cnt_s34 <= s_out_s3;
    end
  end
  // ---------------------------------------------------
  stage_1 #(
    .RANGE_WIDTH (GENERAL_RANGE_WIDTH),
    .SYMBOL_WIDTH (GENERAL_SYMBOL_WIDTH),
    .LUT_ADDR_WIDTH (GENERAL_LUT_ADDR_WIDTH),
    .LUT_DATA_WIDTH (GENERAL_LUT_DATA_WIDTH)
    ) state_pipeline_1 (
      .clk_stage_1 (general_clk),
      .FL (general_fl),
      .FH (general_fh),
      .SYMBOL_1 (general_symbol_1),
      .SYMBOL_2 (general_symbol_2),
      .SYMBOL_3 (general_symbol_3),
      .SYMBOL_4 (general_symbol_4),
      .NSYMS (general_nsyms),
      .bool_flag_1 (general_bool_1),
      .bool_flag_2 (general_bool_2),
      .bool_flag_3 (general_bool_3),
      .bool_flag_4 (general_bool_4),
      // outputs
      .lut_u_out (lut_u_output),
      .lut_v_out (lut_v_output),
      .UU (uu_out),
      .VV (vv_out),
      .COMP_mux_1 (COMP_mux_1_out),
      .bool_out_1 (bool_out_s12_1),
      .bool_out_2 (bool_out_s12_2),
      .bool_out_3 (bool_out_s12_3),
      .bool_out_4 (bool_out_s12_4),
      .out_symbol_1 (symbol_out_s12_1),
      .out_symbol_2 (symbol_out_s12_2),
      .out_symbol_3 (symbol_out_s12_3),
      .out_symbol_4 (symbol_out_s12_4)
    );

  always @ (posedge general_clk) begin
    if(ctrl_reg_1_2) begin
      reg_lut_u <= lut_u_output;
      reg_lut_v <= lut_v_output;
      reg_UU <= uu_out;
      reg_VV <= vv_out;
      reg_COMP_mux_1 <= COMP_mux_1_out;
      reg_bool_s12_1 <= bool_out_s12_1;
      reg_bool_s12_2 <= bool_out_s12_2;
      reg_bool_s12_3 <= bool_out_s12_3;
      reg_bool_s12_4 <= bool_out_s12_4;
      reg_symbol_s12_1 <= symbol_out_s12_1;
      reg_symbol_s12_2 <= symbol_out_s12_2;
      reg_symbol_s12_3 <= symbol_out_s12_3;
      reg_symbol_s12_4 <= symbol_out_s12_4;
    end
  end
  // ---------------------------------------------------
  stage_2 #(
    .RANGE_WIDTH (GENERAL_RANGE_WIDTH),
    .D_SIZE (GENERAL_D_SIZE),
    .SYMBOL_WIDTH (GENERAL_SYMBOL_WIDTH)
    ) state_pipeline_2 (
      // inputs from stage 1
      .lut_u (reg_lut_u), .lut_v (reg_lut_v),
      .UU (reg_UU), .VV (reg_VV),
      .COMP_mux_1 (reg_COMP_mux_1),
      // bool
      .bool_flag_1 (reg_bool_s12_1), .bool_flag_2 (reg_bool_s12_2),
      .bool_flag_3 (reg_bool_s12_3), .bool_flag_4 (reg_bool_s12_4),
      .symbol_1 (reg_symbol_s12_1), .symbol_2 (reg_symbol_s12_2),
      .symbol_3 (reg_symbol_s12_3), .symbol_4 (reg_symbol_s12_4),
      .in_range (reg_range_ready),
      // outputs
      .u (u_out),
      .out_range (range_ready_out),
      .COMP_mux_1_out (COMP_mux_1_out_s23),
      .pre_low_1 (pre_low_out_1), .pre_low_2 (pre_low_out_2),
      .pre_low_3 (pre_low_out_3), .pre_low_4 (pre_low_out_4),
      .out_d_1 (d_out_1), .out_d_2 (d_out_2),
      .out_d_3 (d_out_3), .out_d_4 (d_out_4),
      .initial_range_1 (initial_range_out_1),
      .initial_range_2 (initial_range_out_2),
      .initial_range_3 (initial_range_out_3),
      .initial_range_4 (initial_range_out_4),
      .bool_1 (bool_s23_1), .bool_2 (bool_s23_2),
      .bool_3 (bool_s23_3), .bool_4 (bool_s23_4),
      .symbol_out_1  (symbol_s23_out_1), .symbol_out_2  (symbol_s23_out_2),
      .symbol_out_3  (symbol_s23_out_3), .symbol_out_4  (symbol_s23_out_4)
    );

    always @ (posedge general_clk) begin
      if(reset) begin
        reg_range_ready <= 16'd32768;
      end
      else if(ctrl_reg_2_3) begin
        reg_range_ready <= range_ready_out;
      end
    end
    always @ (posedge general_clk) begin
      if(ctrl_reg_2_3) begin
        reg_u <= u_out;
        reg_range_initial_1 <= initial_range_out_1;
        reg_range_initial_2 <= initial_range_out_2;
        reg_range_initial_3 <= initial_range_out_3;
        reg_range_initial_4 <= initial_range_out_4;
        reg_d_1 <= d_out_1;
        reg_d_2 <= d_out_2;
        reg_d_3 <= d_out_3;
        reg_d_4 <= d_out_4;
        reg_pre_low_1 <= pre_low_out_1;
        reg_pre_low_2 <= pre_low_out_2;
        reg_pre_low_3 <= pre_low_out_3;
        reg_pre_low_4 <= pre_low_out_4;
        reg_bool_s23_1 <= bool_s23_1;
        reg_bool_s23_2 <= bool_s23_2;
        reg_bool_s23_3 <= bool_s23_3;
        reg_bool_s23_4 <= bool_s23_4;
        reg_symbol_s23_1 <= symbol_s23_out_1;
        reg_symbol_s23_2 <= symbol_s23_out_2;
        reg_symbol_s23_3 <= symbol_s23_out_3;
        reg_symbol_s23_4 <= symbol_s23_out_4;
        reg_COMP_mux_1_s23 <= COMP_mux_1_out_s23;
      end
    end

  // ---------------------------------------------------
  stage_3 #(
    .RANGE_WIDTH (GENERAL_RANGE_WIDTH),
    .LOW_WIDTH (GENERAL_LOW_WIDTH),
    .D_SIZE (GENERAL_D_SIZE)
    ) stage_pipeline_3 (
      .bool_flag_1 (reg_bool_s23_1), .bool_flag_2 (reg_bool_s23_2),
      .bool_flag_3 (reg_bool_s23_3), .bool_flag_4 (reg_bool_s23_4),
      .symbol_1 (reg_symbol_s23_1), .symbol_2 (reg_symbol_s23_2),
      .symbol_3 (reg_symbol_s23_3), .symbol_4 (reg_symbol_s23_4),
      .d_1 (reg_d_1), .d_2 (reg_d_2), .d_3 (reg_d_3), .d_4 (reg_d_4),
      .pre_low_1 (reg_pre_low_1), .pre_low_2 (reg_pre_low_2),
      .pre_low_3 (reg_pre_low_3), .pre_low_4 (reg_pre_low_4),
      .range_in_1 (reg_range_initial_1), .range_in_2 (reg_range_initial_2),
      .range_in_3 (reg_range_initial_3), .range_in_4 (reg_range_initial_4),
      .range_ready (reg_range_ready),
      .COMP_mux_1 (reg_COMP_mux_1_s23),
      .u (reg_u),
      .in_s (reg_cnt_s34),
      .in_low (reg_Low_s34),
      // Outputs
      .out_low (low_out_s3),
      .out_range (range_out_s3),
      .out_s (s_out_s3),
      // ----
      .flag_bitstream_1 (pb_flag_1),
      .out_bit_1_1 (pb_1_1), .out_bit_1_2 (pb_1_2),
      .flag_bitstream_2 (pb_flag_2),
      .out_bit_2_1 (pb_2_1), .out_bit_2_2 (pb_2_2),
      .flag_bitstream_3 (pb_flag_3),
      .out_bit_3_1 (pb_3_1), .out_bit_3_2 (pb_2_2),
      .flag_bitstream_4 (pb_flag_4),
      .out_bit_4_1 (pb_4_1), .out_bit_4_2 (pb_4_2)
    );
  always @ (posedge general_clk) begin
    if(ctrl_reg_final) begin
      reg_pb_flag_1 <= pb_flag_1;
      reg_pb_1_1 <= pb_1_1;
      reg_pb_1_2 <= pb_1_2;
      reg_pb_flag_2 <= pb_flag_2;
      reg_pb_2_1 <= pb_2_1;
      reg_pb_2_2 <= pb_2_2;
      reg_pb_flag_3 <= pb_flag_3;
      reg_pb_3_1 <= pb_3_1;
      reg_pb_3_2 <= pb_3_2;
      reg_pb_flag_4 <= pb_flag_4;
      reg_pb_4_1 <= pb_4_1;
      reg_pb_4_2 <= pb_4_2;
    end
  end
endmodule
