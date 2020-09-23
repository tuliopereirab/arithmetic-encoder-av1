module arithmetic_encoder #(
    parameter GENERAL_DATA_16 = 16,
    parameter GENERAL_DATA_32 = 32,
    parameter GENERAL_SYMBOL_WIDTH = 4,
    parameter GENERAL_LUT_ADDR_WIDTH = 8,
    parameter GENERAL_LUT_DATA_WIDTH = 16,
    parameter GENERAL_D_SIZE = 5
    )(
        input general_clk, reset,
        input [(GENERAL_DATA_16-1):0] general_fl, general_fh,
        input [(GENERAL_SYMBOL_WIDTH-1):0] general_symbol,
        input [GENERAL_SYMBOL_WIDTH:0] general_nsyms,
        output wire [(GENERAL_DATA_16-1):0] RANGE_OUTPUT, LOW_OUTPUT,
        output wire [(GENERAL_DATA_32-1):0] CNT_OUTPUT
    );

    // general
    reg [(GENERAL_DATA_16-1):0] reg_Range_s3, reg_Low_s3;
    reg [(GENERAL_DATA_32-1):0] reg_Cnt_s3;
    assign RANGE_OUTPUT = reg_Range_s3;
    assign LOW_OUTPUT = reg_Low_s3;
    assign CNT_OUTPUT = reg_Cnt_s3;

    // stage 1
    wire [(GENERAL_DATA_16-1):0] UU_out, VV_out, A_out;
    wire COMP_mux_1_out;
    reg [(GENERAL_DATA_16-1):0] reg_UU, reg_VV, reg_A, reg_COMP_mux_1;
    // stage 2
    wire [(GENERAL_DATA_16-1):0] range_out_s2, low_out_s2, mux_reset_range, mux_reset_low;
    reg [(GENERAL_DATA_16-1):0] reg_Range_s2, reg_Low_s2;
    // stage 3, 4, 5
    wire [(GENERAL_DATA_16-1):0] range_out_s3, low_out_s3;
    wire [(GENERAL_DATA_32-1):0] cnt_out_s3;

    // ---------------------------------------------------
    wire [(GENERAL_DATA_16-1):0] init_range, init_low;
    wire [(GENERAL_DATA_32-1):0] init_cnt;
    assign init_range = 16'b1000_0000_0000_0000;                // 16'd32768;
    assign init_low = 16'b0000_0000_0000_0000;                  // 16'd0;
    assign init_cnt = 32'b11111111_11111111_11111111_11110111;  // 32'd4294967287;
    // reset
    always @ (general_clk) begin
        if(reset) begin
            reg_Range_s3 <= init_range;
            reg_Low_s3 <= init_low;
            reg_Cnt_s3 <= init_cnt;
        end
        else begin  // already saving what comes from the Stage [3,4,5]
            reg_Range_s3 <= range_out_s3;
            reg_Low_s3 <= low_out_s3;
            reg_Cnt_s3 <= cnt_out_s3;
        end
    end
    // ---------------------------------------------------
    stage_1 #(
        .DATA_16 (GENERAL_DATA_16),
        .SYMBOL_WIDTH (GENERAL_SYMBOL_WIDTH),
        .LUT_ADDR_WIDTH (GENERAL_LUT_ADDR_WIDTH),
        .LUT_DATA_WIDTH (GENERAL_LUT_DATA_WIDTH)
        )(
            .clk_stage_1 (general_clk),
            .FL (general_fl),
            .FH (general_fh),
            .SYMBOL (general_symbol),
            .NSYMS (general_nsyms),
            // outputs
            .UU (UU_out),
            .VV (VV_out),
            .A (A_out),
            .COMP_mux_1 (COMP_mux_1_out)
        );

    always @ (general_clk) begin
        reg_UU <= UU_out;
        reg_VV <= VV_out;
        reg_A <= A_out;
        reg_COMP_mux_1 <= COMP_mux_1_out;
    end
    // ---------------------------------------------------
    stage_2 #(
        .DATA_16 (GENERAL_DATA_16),
        .DATA_32 (GENERAL_DATA_32)
        )(
            .UU (reg_UU),
            .VV (reg_VV),
            .A (reg_A),
            .in_range (RANGE_OUTPUT),
            .in_low (LOW_OUTPUT),
            .COMP_mux_1 (reg_COMP_mux_1),
            // outputs
            .range (range_out_s2),
            .low (low_out_s2)
        );

    always @ (general_clk) begin
        reg_Range_s2 <= range_out_s2;
        reg_Low_s2 <= low_out_s2;
    end
    // ---------------------------------------------------
    stage_3_4_5 #(
        .DATA_16 (GENERAL_DATA_16),
        .DATA_32 (GENERAL_DATA_32),
        .D_SIZE (GENERAL_D_SIZE)
        )(
            .low (reg_Low_s2),
            .range (reg_Range_s2),
            .in_cnt (reg_Cnt_s3),
            // outputs
            .out_low (low_out_s3),
            .out_range (range_out_s3),
            .out_cnt (cnt_out_s3)
        );
endmodule
