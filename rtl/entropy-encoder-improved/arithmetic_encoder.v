module arithmetic_encoder #(
  parameter GENERAL_RANGE_WIDTH = 16,
  parameter GENERAL_LOW_WIDTH = 24,
  parameter GENERAL_SYMBOL_WIDTH = 4,
  parameter GENERAL_LUT_ADDR_WIDTH = 8,
  parameter GENERAL_LUT_DATA_WIDTH = 16,
  parameter GENERAL_D_SIZE = 5
  )(
    /*
      New inputs for parallel bool:
         1-> general_symbol_2 and general_bool_2;
         2-> general_symbol_3 and general_bool_3;
      New outputs:
    */
    input general_clk, reset,
    input [(GENERAL_RANGE_WIDTH-1):0] general_fl, general_fh,
    input [(GENERAL_SYMBOL_WIDTH-1):0] general_symbol_1, general_symbol_2,
    input [(GENERAL_SYMBOL_WIDTH-1):0] general_symbol_3,
    input [GENERAL_SYMBOL_WIDTH:0] general_nsyms,
    input general_bool_1, general_bool_2, general_bool_3,
    output wire [(GENERAL_RANGE_WIDTH-1):0] RANGE_OUTPUT,
    output wire [(GENERAL_LOW_WIDTH-1):0] LOW_OUTPUT,
    output wire [(GENERAL_D_SIZE-1):0] CNT_OUTPUT,
    output wire [(GENERAL_RANGE_WIDTH-1):0] OUT_BIT_1_1, OUT_BIT_1_2,
    output wire [(GENERAL_RANGE_WIDTH-1):0] OUT_BIT_2_1, OUT_BIT_2_2,
    output wire [(GENERAL_RANGE_WIDTH-1):0] OUT_BIT_3_1, OUT_BIT_3_2,
    output wire [1:0] OUT_FLAG_BITSTREAM_1, OUT_FLAG_BITSTREAM_2,
    output wire [1:0] OUT_FLAG_BITSTREAM_3
  );

  // general
  reg [(GENERAL_RANGE_WIDTH-1):0] reg_Range_s3;
  reg [(GENERAL_LOW_WIDTH-1):0] reg_Low_s3;
  reg [(GENERAL_D_SIZE-1):0] reg_S_s3;
  reg [1:0] reg_flag_bitstream_1, reg_flag_bitstream_2, reg_flag_bitstream_3;
  reg [(GENERAL_RANGE_WIDTH-1):0] reg_pre_bitstream_1_1, reg_pre_bitstream_1_2;
  reg [(GENERAL_RANGE_WIDTH-1):0] reg_pre_bitstream_2_1, reg_pre_bitstream_2_2;
  reg [(GENERAL_RANGE_WIDTH-1):0] reg_pre_bitstream_3_1, reg_pre_bitstream_3_2;
  assign RANGE_OUTPUT = reg_Range_s3;
  assign LOW_OUTPUT = reg_Low_s3;
  // Parallel Bool  -- Output Assignments
  assign OUT_BIT_1_1 = reg_pre_bitstream_1_1;
  assign OUT_BIT_1_2 = reg_pre_bitstream_1_2;
  assign OUT_FLAG_BITSTREAM_1 = reg_flag_bitstream_1;
  // Second
  assign OUT_BIT_2_1 = reg_pre_bitstream_2_1;
  assign OUT_BIT_2_2 = reg_pre_bitstream_2_2;
  assign OUT_FLAG_BITSTREAM_2 = reg_flag_bitstream_2;
  // Third
  assign OUT_BIT_3_1 = reg_pre_bitstream_3_1;
  assign OUT_BIT_3_2 = reg_pre_bitstream_3_2;
  assign OUT_FLAG_BITSTREAM_3 = reg_flag_bitstream_3;
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
  wire COMP_mux_1_out, bool_output_s12_1, bool_output_s12_2, bool_output_s12_3;
  wire [(GENERAL_RANGE_WIDTH-1):0] uu_out, vv_out;
  wire [(GENERAL_LUT_DATA_WIDTH-1):0] lut_u_output, lut_v_output;
  wire [(GENERAL_SYMBOL_WIDTH-1):0] symbol_output_s12_1, symbol_output_s12_2;
  wire [(GENERAL_SYMBOL_WIDTH-1):0] symbol_output_s12_3;
  reg reg_COMP_mux_1, reg_bool_s12_1, reg_bool_s12_2, reg_bool_s12_3;
  reg [(GENERAL_LUT_DATA_WIDTH-1):0] reg_lut_u, reg_lut_v;
  reg [(GENERAL_RANGE_WIDTH-1):0] reg_UU, reg_VV;
  reg [(GENERAL_SYMBOL_WIDTH-1):0] reg_symbol_s12_1, reg_symbol_s12_2;
  reg [(GENERAL_SYMBOL_WIDTH-1):0] reg_symbol_s12_3;
  // stage 2
  wire COMP_mux_1_out_s23;
  wire bool_output_s23_1, bool_output_s23_2, bool_output_s23_3;
  wire symbol_output_s23_1, symbol_output_s23_2, symbol_output_s23_3;
  wire [(GENERAL_D_SIZE-1):0] d_out_1, d_out_2, d_out_3;
  wire [GENERAL_RANGE_WIDTH:0] uv_out_1, v_bool_out_2, v_bool_out_3;
  wire [(GENERAL_RANGE_WIDTH-1):0] initial_range_out_1, initial_range_out_2;
  wire [(GENERAL_RANGE_WIDTH-1):0] initial_range_out_3, range_ready_out;
  reg reg_COMP_mux_1_s23;
  reg reg_bool_s23_1, reg_bool_s23_2, reg_bool_s23_3;
  reg reg_symbol_s23_1, reg_symbol_s23_2, reg_symbol_s23_3;
  reg [(GENERAL_D_SIZE-1):0] reg_d_1, reg_d_2, reg_d_3;
  reg [GENERAL_RANGE_WIDTH:0] reg_uv_1, reg_v_bool_2, reg_v_bool_3;
  reg [(GENERAL_RANGE_WIDTH-1):0] reg_initial_range_1, reg_initial_range_2;
  reg [(GENERAL_RANGE_WIDTH-1):0] reg_initial_range_3, reg_range_ready;
  // --------------------------------------------------
  // Stage 3
  wire [(GENERAL_RANGE_WIDTH-1):0] range_out_s3;
  wire [(GENERAL_LOW_WIDTH-1):0] low_out_s3;
  wire [(GENERAL_D_SIZE-1):0] s_out_s3;
  // Below are the output pins for the stage 3.
  wire [(GENERAL_RANGE_WIDTH-1):0] pre_bitstream_out_1_1, pre_bitstream_out_1_2;
  wire [(GENERAL_RANGE_WIDTH-1):0] pre_bitstream_out_2_1, pre_bitstream_out_2_2;
  wire [(GENERAL_RANGE_WIDTH-1):0] pre_bitstream_out_3_1, pre_bitstream_out_3_2;
  wire [1:0] out_flag_bitstream_1, out_flag_bitstream_2, out_flag_bitstream_3;
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
      .NSYMS (general_nsyms),
      .SYMBOL_1 (general_symbol_1),
      .SYMBOL_2 (general_symbol_2),     // Parallel Bool
      .SYMBOL_3 (general_symbol_3),     // Parallel Bool
      .bool_flag_1 (general_bool_1),
      .bool_flag_2 (general_bool_2),    // Parallel Bool
      .bool_flag_3 (general_bool_3),    // Parallel Bool
      // outputs
      .lut_u_out (lut_u_output),
      .lut_v_out (lut_v_output),
      .UU (uu_out),
      .VV (vv_out),
      .COMP_mux_1 (COMP_mux_1_out),
      .bool_out_1 (bool_output_s12_1),
      .bool_out_2 (bool_output_s12_2),      // Parallel Bool
      .bool_out_3 (bool_output_s12_3),      // Parallel Bool
      .out_symbol_1 (symbol_output_s12_1),
      .out_symbol_2 (symbol_output_s12_2),  // Parallel Bool
      .out_symbol_3 (symbol_output_s12_3)   // Parallel Bool
    );

  always @ (posedge general_clk) begin
    if(ctrl_reg_1_2) begin
      reg_lut_u <= lut_u_output;
      reg_lut_v <= lut_v_output;
      reg_UU <= uu_out;
      reg_VV <= vv_out;
      reg_COMP_mux_1 <= COMP_mux_1_out;
      reg_bool_s12_1 <= bool_output_s12_1;
      reg_bool_s12_2 <= bool_output_s12_2;      // Parallel Bool
      reg_bool_s12_3 <= bool_output_s12_3;      // Parallel Bool
      reg_symbol_s12_1 <= symbol_output_s12_1;
      reg_symbol_s12_2 <= symbol_output_s12_2;  // Parallel Bool
      reg_symbol_s12_3 <= symbol_output_s12_3;  // Parallel Bool
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
      .in_range (reg_range_ready),
      // Parallel Bool
      .bool_flag_1 (reg_bool_s12_1),
      .bool_flag_2 (reg_bool_s12_2),
      .bool_flag_3 (reg_bool_s12_3),
      .in_symbol_1 (reg_symbol_s12_1),
      .in_symbol_2 (reg_symbol_s12_2),
      .in_symbol_3 (reg_symbol_s12_3),
      // outputs
      .out_d_1 (d_out_1),
      .out_d_2 (d_out_2),
      .out_d_3 (d_out_3),
      .uv_1 (uv_out_1),
      .v_bool_2 (v_bool_out_2),
      .v_bool_3 (v_bool_out_3),
      .out_range (range_ready_out),
      .out_bool_1 (bool_output_s23_1),
      .out_bool_2 (bool_output_s23_2),
      .out_bool_3 (bool_output_s23_3),
      .out_symbol_1 (symbol_output_s23_1),
      .out_symbol_2 (symbol_output_s23_2),
      .out_symbol_3 (symbol_output_s23_3),
      .COMP_mux_1_out (COMP_mux_1_out_s23),
      .initial_range_1 (initial_range_out_1),
      .initial_range_2 (initial_range_out_2),
      .initial_range_3 (initial_range_out_3)
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
        reg_COMP_mux_1_s23 = COMP_mux_1_out_s23;
        // Parallel Bool
        reg_initial_range_1 = initial_range_out_1;
        reg_initial_range_2 = initial_range_out_2;
        reg_initial_range_3 = initial_range_out_3;
        reg_bool_s23_1 = bool_output_s23_1;
        reg_bool_s23_2 = bool_output_s23_2;
        reg_bool_s23_3 = bool_output_s23_3;
        reg_symbol_s23_1 = symbol_output_s23_1;
        reg_symbol_s23_2 = symbol_output_s23_2;
        reg_symbol_s23_3 = symbol_output_s23_3;
        reg_uv_1 = uv_out_1;
        reg_v_bool_2 = v_bool_out_2;
        reg_v_bool_3 = v_bool_out_3;
        reg_d_1 = d_out_1;
        reg_d_2 = d_out_2;
        reg_d_3 = d_out_3;
      end
    end

  // ---------------------------------------------------
  stage_3 #(
    .RANGE_WIDTH (GENERAL_RANGE_WIDTH),
    .LOW_WIDTH (GENERAL_LOW_WIDTH),
    .D_SIZE (GENERAL_D_SIZE)
    ) stage_pipeline_3 (
      .d_1 (reg_d_1),
      .d_2 (reg_d_2),
      .d_3 (reg_d_3),
      .in_s (reg_S_s3),
      .uv_1 (reg_uv_1),
      .in_low (reg_Low_s3),
      .v_bool_2 (reg_v_bool_2),
      .v_bool_3 (reg_v_bool_3),
      .in_bool_1 (reg_bool_s23_1),
      .in_bool_2 (reg_bool_s23_2),
      .in_bool_3 (reg_bool_s23_3),
      .range_ready (reg_range_ready),
      .in_symbol_1 (reg_symbol_s23_1),
      .in_symbol_2 (reg_symbol_s23_2),
      .in_symbol_3 (reg_symbol_s23_3),
      .COMP_mux_1 (reg_COMP_mux_1_s23),
      .in_range_1 (reg_initial_range_1),
      .in_range_2 (reg_initial_range_2),
      .in_range_3 (reg_initial_range_3),
      // Outputs
      .out_s (s_out_s3),
      .out_low (low_out_s3),
      .out_range (range_out_s3),
      // First
      .FLAG_BIT_1 (out_flag_bitstream_1),
      .OUT_BIT_1_1 (pre_bitstream_out_1_1),
      .OUT_BIT_1_2 (pre_bitstream_out_1_2),
      // Second
      .FLAG_BIT_2 (out_flag_bitstream_2),
      .OUT_BIT_2_1 (pre_bitstream_out_2_1),
      .OUT_BIT_2_2 (pre_bitstream_out_2_2),
      // Third
      .FLAG_BIT_3 (out_flag_bitstream_3),
      .OUT_BIT_3_1 (pre_bitstream_out_3_1),
      .OUT_BIT_3_2 (pre_bitstream_out_3_2)
    );
  always @ (posedge general_clk) begin
    if(ctrl_reg_final) begin
      // First
      reg_flag_bitstream_1 <= out_flag_bitstream_1;
      reg_pre_bitstream_1_1 <= pre_bitstream_out_1_1;
      reg_pre_bitstream_1_2 <= pre_bitstream_out_1_2;
      // Second
      reg_flag_bitstream_2 <= out_flag_bitstream_2;
      reg_pre_bitstream_2_1 <= pre_bitstream_out_2_1;
      reg_pre_bitstream_2_2 <= pre_bitstream_out_2_2;
      // Third
      reg_flag_bitstream_3 <= out_flag_bitstream_3;
      reg_pre_bitstream_3_1 <= pre_bitstream_out_3_1;
      reg_pre_bitstream_3_2 <= pre_bitstream_out_3_2;
    end
  end
endmodule
