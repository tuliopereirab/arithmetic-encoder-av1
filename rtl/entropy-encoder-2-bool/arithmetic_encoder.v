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
    input [(GENERAL_SYMBOL_WIDTH-1):0] general_symbol,
    input [GENERAL_SYMBOL_WIDTH:0] general_nsyms,
    input general_bool,
    output wire [(GENERAL_RANGE_WIDTH-1):0] RANGE_OUTPUT,
    output wire [(GENERAL_LOW_WIDTH-1):0] LOW_OUTPUT,
    output wire [(GENERAL_D_SIZE-1):0] CNT_OUTPUT,
    output wire [(GENERAL_RANGE_WIDTH-1):0] OUT_BIT_1, OUT_BIT_2,
    output wire [1:0] OUT_FLAG_BITSTREAM
  );

  // general
  reg [(GENERAL_RANGE_WIDTH-1):0] reg_Range_s3;
  reg [(GENERAL_LOW_WIDTH-1):0] reg_Low_s3;
  reg [(GENERAL_D_SIZE-1):0] reg_S_s3;
  reg [1:0] reg_flag_bitstream;
  reg [(GENERAL_RANGE_WIDTH-1):0] reg_pre_bitstream_1, reg_pre_bitstream_2;
  assign RANGE_OUTPUT = reg_Range_s3;
  assign LOW_OUTPUT = reg_Low_s3;
  assign OUT_BIT_1 = reg_pre_bitstream_1;
  assign OUT_BIT_2 = reg_pre_bitstream_2;
  assign OUT_FLAG_BITSTREAM = reg_flag_bitstream;
  assign CNT_OUTPUT = reg_S_s3;

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
  wire [(GENERAL_SYMBOL_WIDTH-1):0] symbol_output;
  wire COMP_mux_1_out, bool_output;
  reg [(GENERAL_LUT_DATA_WIDTH-1):0] reg_lut_u, reg_lut_v;
  reg [(GENERAL_RANGE_WIDTH-1):0] reg_UU, reg_VV;
  reg [(GENERAL_SYMBOL_WIDTH-1):0] reg_symbol;
  reg reg_COMP_mux_1, reg_bool;
  // stage 2
  wire [(GENERAL_RANGE_WIDTH-1):0] initial_range_out, range_ready_out;
  wire [GENERAL_RANGE_WIDTH:0] u_out, v_out;
  wire [(GENERAL_D_SIZE-1):0] d_out;
  wire [GENERAL_RANGE_WIDTH:0] v_bool_out;
  wire [1:0] bool_symbol_out;
  wire COMP_mux_1_out_s2;
  reg [(GENERAL_RANGE_WIDTH-1):0] reg_initial_range, reg_range_ready;
  reg [GENERAL_RANGE_WIDTH:0] reg_u, reg_v_bool;
  reg [(GENERAL_D_SIZE-1):0] reg_d;
  reg [1:0] reg_bool_symbol;
  reg reg_COMP_mux_1_s2;
  // --------------------------------------------------
  // Stage 3
  wire [(GENERAL_RANGE_WIDTH-1):0] range_out_s3;
  wire [(GENERAL_LOW_WIDTH-1):0] low_out_s3;
  wire [(GENERAL_D_SIZE-1):0] s_out_s3;
  // Below are the output pins for the stage 3.
  wire [(GENERAL_RANGE_WIDTH-1):0] pre_bitstream_out_1, pre_bitstream_out_2;
  wire [1:0] out_flag_bitstream;
  // ---------------------------------------------------
  // reset
  always @ (posedge general_clk) begin
    if(reset) begin
      reg_S_s3 <= 5'd0;
      reg_Range_s3 <= 16'd32768;     // not necessary
      reg_Low_s3 <= 24'd0;
    end
    else if(ctrl_reg_final) begin  //already saving stuff from the Stage [3,4,5]
      reg_Range_s3 <= range_out_s3;
      reg_Low_s3 <= low_out_s3;
      reg_S_s3 <= s_out_s3;
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
      .SYMBOL (general_symbol),
      .NSYMS (general_nsyms),
      .bool_flag (general_bool),
      // outputs
      .lut_u_out (lut_u_output),
      .lut_v_out (lut_v_output),
      .UU (uu_out),
      .VV (vv_out),
      .COMP_mux_1 (COMP_mux_1_out),
      .bool_out (bool_output),
      .out_symbol (symbol_output)
    );

  always @ (posedge general_clk) begin
    if(ctrl_reg_1_2) begin
      reg_lut_u <= lut_u_output;
      reg_lut_v <= lut_v_output;
      reg_UU <= uu_out;
      reg_VV <= vv_out;
      reg_COMP_mux_1 <= COMP_mux_1_out;
      reg_bool <= bool_output;
      reg_symbol <= symbol_output;
    end
  end
  // ---------------------------------------------------
  stage_2 #(
    .RANGE_WIDTH (GENERAL_RANGE_WIDTH),
    .D_SIZE (GENERAL_D_SIZE),
    .SYMBOL_WIDTH (GENERAL_SYMBOL_WIDTH)
    ) state_pipeline_2 (
      // inputs from stage 1
      .lut_u (reg_lut_u),
      .lut_v (reg_lut_v),
      .UU (reg_UU),
      .VV (reg_VV),
      .COMP_mux_1 (reg_COMP_mux_1),
      // bool
      .bool_flag (reg_bool),
      .symbol (reg_symbol),
      // inputs from stage 3
      .in_range (reg_range_ready),
      // former stage 3
      // outputs
      .u (u_out),
      .v_bool (v_bool_out),
      .initial_range (initial_range_out),
      .out_range (range_ready_out),
      .out_d (d_out),
      .bool_symbol (bool_symbol_out),
      .COMP_mux_1_out (COMP_mux_1_out_s2)
    );

    always @ (posedge general_clk) begin
      if(reset) begin
        reg_range_ready = 16'd32768;
      end
      else if(ctrl_reg_2_3) begin
        reg_range_ready = range_ready_out;
      end
    end
    always @ (posedge general_clk) begin
      if(ctrl_reg_2_3) begin
        reg_u = u_out;
        reg_v_bool = v_bool_out;
        reg_initial_range = initial_range_out;
        reg_d = d_out;
        reg_bool_symbol = bool_symbol_out;
        reg_COMP_mux_1_s2 = COMP_mux_1_out_s2;
      end
    end

  // ---------------------------------------------------
  stage_3 #(
    .RANGE_WIDTH (GENERAL_RANGE_WIDTH),
    .LOW_WIDTH (GENERAL_LOW_WIDTH),
    .D_SIZE (GENERAL_D_SIZE)
    ) stage_pipeline_3 (
      .bool_symbol (reg_bool_symbol),
      .in_range (reg_initial_range),
      .range_ready (reg_range_ready),
      .d (reg_d),
      .COMP_mux_1 (reg_COMP_mux_1_s2),
      .u (reg_u),
      .v_bool (reg_v_bool),
      .in_s (reg_S_s3),
      .in_low (reg_Low_s3),
      // bitstream
      .flag_bitstream (out_flag_bitstream),
      .out_bit_1 (pre_bitstream_out_1),
      .out_bit_2 (pre_bitstream_out_2),
      // outputs
      .out_low (low_out_s3),
      .out_range (range_out_s3),
      .out_s (s_out_s3)
    );
  always @ (posedge general_clk) begin
    if(ctrl_reg_final) begin
      reg_flag_bitstream <= out_flag_bitstream;
      reg_pre_bitstream_1 <= pre_bitstream_out_1;
      reg_pre_bitstream_2 <= pre_bitstream_out_2;
    end
  end
endmodule
