module stage_2 #(
    parameter RANGE_WIDTH = 16,
    parameter LOW_WIDTH = 24
    )(
        input [(RANGE_WIDTH-1):0] UU, VV, in_range, lut_u, lut_v,
        input [(LOW_WIDTH-1):0] in_low,
        input COMP_mux_1,
        output wire [(RANGE_WIDTH-1):0] range,
        output wire [(LOW_WIDTH-1):0] low
    );
    wire [(RANGE_WIDTH-1):0] RR, range_1, range_2;
    wire [(LOW_WIDTH-1):0] low_1;

    wire [(RANGE_WIDTH-1):0] u, v;

    assign RR = in_range >> 8;

    assign u = (RR * UU >> 32'd1) + lut_u;
    assign v = (RR * VV >> 32'd1) + lut_v;

    assign low_1 = in_low + (in_range - u);
    assign range_1 = u - v;
    assign range_2 = in_range - v;


    // muxes
    assign low = (COMP_mux_1 == 1'b1) ? low_1 :
                 in_low;
    assign range = (COMP_mux_1 == 1'b1) ? range_1 :
                    range_2;

endmodule
