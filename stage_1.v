module stage_1 #(
    parameter RANGE_WIDTH = 16,
    parameter SYMBOL_WIDTH = 4,
    parameter LUT_ADDR_WIDTH = 8,
    parameter LUT_DATA_WIDTH = 16
    )(
        input clk_stage_1,      // only used for the LUTs
        input [(RANGE_WIDTH-1):0] FL, FH,
        input [(SYMBOL_WIDTH-1):0] SYMBOL,  // receives the symbol in the range 0 to 15
        input [SYMBOL_WIDTH:0] NSYMS,       // defined as 1 bit longer than SYMBOL; receives the number of symbols used
        input bool,                         // is the flag showing if it is a bool or not
        output wire COMP_mux_1, bool_out,
        output wire [(LUT_DATA_WIDTH-1):0] lut_u_out, lut_v_out,
        output wire [(SYMBOL_WIDTH-1):0] out_symbol,
        output wire [(RANGE_WIDTH-1):0] UU, VV

    );

    wire [SYMBOL_WIDTH:0] N_5bits;
    wire [(SYMBOL_WIDTH-1):0] N;
    wire [(LUT_ADDR_WIDTH-1):0] lut_addr;


    assign N_5bits = NSYMS - 5'd1;
    assign N = N_5bits[(SYMBOL_WIDTH-1):0];
    assign lut_addr = {N, SYMBOL};

    assign UU = FL >> 16'd6;
    assign VV = FH >> 16'd6;

    assign COMP_mux_1 = (FL < 16'd32768) ? 1'b1 :
                        1'b0;

    assign bool_out = ~bool;
    assign out_symbol = SYMBOL;

    lut_u_module #(
        .DATA_WIDTH (LUT_DATA_WIDTH),
        .ADDR_WIDTH (LUT_ADDR_WIDTH)
        ) lut_u (
            .addr (lut_addr),
            .q (lut_u_out)
        );
    lut_v_module #(
        .DATA_WIDTH (LUT_DATA_WIDTH),
        .ADDR_WIDTH (LUT_ADDR_WIDTH)
        ) lut_v (
            .addr (lut_addr),
            .q (lut_v_out)
        );
endmodule
