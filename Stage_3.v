module stage_3 #(
    parameter RANGE_WIDTH = 16,
    parameter LOW_WIDTH = 24,
    parameter D_SIZE = 5
    )(
        input [(RANGE_WIDTH-1):0] range,
        input [(LOW_WIDTH-1):0] low,
        output wire [(RANGE_WIDTH-1):0] out_range,
        output wire [(LOW_WIDTH-1):0] out_low
    );


    wire [(LOW_WIDTH-1):0] low_1, low_m;
    wire [((RANGE_WIDTH/2)-1):0] mux_2, most_sig_low;
    wire [(D_SIZE-1):0] d;
    wire [(RANGE_WIDTH-1):0] m;
    wire v_lzc;     // this is the bit that shows if lzc is valid or not (I'm not really sure about this)



    assign m = 16'h7FFF;

    leading_zero #(
        .RANGE_WIDTH_LCZ (RANGE_WIDTH),
        .D_SIZE_LZC (D_SIZE)
        ) lzc (
            .in_range (range),
            .lzc_out (d),
            .v (v_lzc)
        );

    assign low_1 = low << d;
    assign low_m = low_1[(LOW_WIDTH-1):(RANGE_WIDTH/2)] | m;

    assign mux_2 = (low_m > 24'h7FFF) ? 8'd0 :
                    8'd255;

    assign most_sig_low = low_1[(LOW_WIDTH-1):RANGE_WIDTH] & mux_2;

    // outputs
    assign out_low = {most_sig_low, low_1[(RANGE_WIDTH-1):0]};
    assign out_range = range << d;
endmodule
