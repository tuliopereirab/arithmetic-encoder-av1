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
        output wire [(GENERAL_RANGE_WIDTH-1):0] RANGE_OUTPUT,
        output wire [(GENERAL_LOW_WIDTH-1):0] LOW_OUTPUT
    );

    // general
    reg [(GENERAL_RANGE_WIDTH-1):0] reg_Range_s3;
    reg [(GENERAL_LOW_WIDTH-1):0] reg_Low_s3;
    reg [(GENERAL_D_SIZE-1):0] reg_S_s3;
    assign RANGE_OUTPUT = reg_Range_s3;
    assign LOW_OUTPUT = reg_Low_s3;

    // control unit
    wire ctrl_reg_1_2, ctrl_reg_2_3, ctrl_reg_final, ctrl_mux_reset;

    control_unit control (
        .clk (general_clk),
        .reset_ctrl (reset),
        //outputs
        .pipeline_reg_1_2 (ctrl_reg_1_2),
        .pipeline_reg_2_3 (ctrl_reg_2_3),
        .pipeline_reg_final (ctrl_reg_final),
        .mux_reset (ctrl_mux_reset)
        );


    // stage 1
    wire [(GENERAL_LUT_DATA_WIDTH-1):0] lut_u_output, lut_v_output;
    wire [(GENERAL_RANGE_WIDTH-1):0] uu_out, vv_out;
    wire COMP_mux_1_out;
    reg [(GENERAL_LUT_DATA_WIDTH-1):0] reg_lut_u, reg_lut_v;
    reg [(GENERAL_RANGE_WIDTH-1):0] reg_UU, reg_VV;
    reg reg_COMP_mux_1;
    // stage 2
    wire [(GENERAL_RANGE_WIDTH-1):0] range_out_s2, mux_reset_range;
    wire [(GENERAL_LOW_WIDTH-1):0] mux_reset_low, low_out_s2;
    reg [(GENERAL_RANGE_WIDTH-1):0] reg_Range_s2;
    reg [(GENERAL_LOW_WIDTH-1):0] reg_Low_s2;
    wire [(GENERAL_RANGE_WIDTH-1):0] s2_in_range_mux;
    wire [(GENERAL_LOW_WIDTH-1):0] s2_in_low_mux;
    // stage 3
    wire [(GENERAL_RANGE_WIDTH-1):0] range_out_s3;
    wire [(GENERAL_LOW_WIDTH-1):0] low_out_s3;
    wire [(GENERAL_D_SIZE-1):0] s_out_s3;
    // ---------------------------------------------------
    wire [(GENERAL_RANGE_WIDTH-1):0] init_range;
    wire [(GENERAL_LOW_WIDTH-1):0] init_low;
    wire [(GENERAL_D_SIZE-1):0] init_s;
    assign init_s = 5'd0;
    // reset
    always @ (posedge general_clk) begin
        if(reset) begin
            reg_S_s3 <= init_s;
        end
        else if(ctrl_reg_final) begin  // already saving what comes from the Stage [3,4,5]
            reg_Range_s3 <= range_out_s3;
            reg_Low_s3 <= low_out_s3;
            reg_S_s3 <= s_out_s3;
        end
    end
    assign s2_in_range_mux = (ctrl_mux_reset == 1'b1) ? 16'd32768 :        // reset value for range
                            range_out_s3;
    assign s2_in_low_mux = (ctrl_mux_reset == 1'b1) ? 24'd0 :              // reset value for low
                            low_out_s3;
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
            // outputs
            .lut_u_out (lut_u_output),
            .lut_v_out (lut_v_output),
            .UU (uu_out),
            .VV (vv_out),
            .COMP_mux_1 (COMP_mux_1_out)
        );

    always @ (posedge general_clk) begin
        if(ctrl_reg_1_2) begin
            reg_lut_u <= lut_u_output;
            reg_lut_v <= lut_v_output;
            reg_UU <= uu_out;
            reg_VV <= vv_out;
            reg_COMP_mux_1 <= COMP_mux_1_out;
        end
    end
    // ---------------------------------------------------
    stage_2 #(
        .RANGE_WIDTH (GENERAL_RANGE_WIDTH),
        .LOW_WIDTH (GENERAL_LOW_WIDTH)
        ) state_pipeline_2 (
            .lut_u (reg_lut_u),
            .lut_v (reg_lut_v),
            .UU (reg_UU),
            .VV (reg_VV),
            .in_range (s2_in_range_mux),
            .in_low (s2_in_low_mux),
            .COMP_mux_1 (reg_COMP_mux_1),
            // outputs
            .range (range_out_s2),
            .low (low_out_s2)
        );

    always @ (posedge general_clk) begin
        if(ctrl_reg_2_3) begin
            reg_Range_s2 <= range_out_s2;
            reg_Low_s2 <= low_out_s2;
        end
    end
    // ---------------------------------------------------
    stage_3 #(
        .RANGE_WIDTH (GENERAL_RANGE_WIDTH),
        .LOW_WIDTH (GENERAL_LOW_WIDTH),
        .D_SIZE (GENERAL_D_SIZE)
        ) state_pipeline_3 (
            .low (reg_Low_s2),
            .range (reg_Range_s2),
            .in_s (reg_S_s3),
            // outputs
            .out_low (low_out_s3),
            .out_range (range_out_s3),
            .out_s (s_out_s3)
        );
endmodule
