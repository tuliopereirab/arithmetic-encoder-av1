module stage_1 #(
    parameter DATA_16 = 16,
    parameter SYMBOL_WIDTH = 4,
    parameter LUT_ADDR_WIDTH = 8,
    parameter LUT_DATA_WIDTH = 16
    )(
        input clk_stage_1,      // only used for the LUTs
        input [(DATA_16-1):0] FL, FH,
        input [(SYMBOL_WIDTH-1):0] SYMBOL,  // receives the symbol in the range 0 to 15
        input [SYMBOL_WIDTH:0] NSYMS,       // defined as 1 bit longer than SYMBOL; receives the number of symbols used
        output wire [(DATA_16-1):0] UU, VV, A,
        output wire COMP_mux_1
    );

    wire [SYMBOL_WIDTH:0] N_5bits;
    wire [(SYMBOL_WIDTH-1):0] N;
    wire [(LUT_ADDR_WIDTH-1):0] lut_addr;
    wire [(LUT_DATA_WIDTH-1):0] lut_u_output, lut_v_output;

    assign N_5bits = NSYMS - 5'b00001;
    assign N = N_5bits[(SYMBOL_WIDTH-1):0];
    assign lut_addr = {N, SYMBOL};

    assign UU = ((FL >> 16'b0000_0000_0000_0110) >> 16'b0000_0000_0000_0001) + lut_u_output;
    assign VV = ((FH >> 16'b0000_0000_0000_0110) >> 16'b0000_0000_0000_0001) + lut_v_output;
    assign A = UU - VV;

    assign COMP_mux_1 = (FL < 16'b1000_0000_0000_0000) ? 1'b1 :
                        1'b0;

    lut_u #(
        .DATA_WIDTH (LUT_DATA_WIDTH),
        .ADDR_WIDTH (LUT_ADDR_WIDTH)
        ) lut_u (
            .clk (clk_stage_1),
            .addr (lut_addr),
            .q (lut_u_output)
        );
    lut_v #(
        .DATA_WIDTH (LUT_DATA_WIDTH),
        .ADDR_WIDTH (LUT_ADDR_WIDTH)
        ) lut_v (
            .clk (clk_stage_1),
            .addr (lut_addr),
            .q (lut_v_output)
        );
endmodule
