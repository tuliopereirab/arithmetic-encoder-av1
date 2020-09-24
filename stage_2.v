module stage_2 #(
    parameter DATA_16 = 16,
    parameter DATA_32 = 32
    )(
        input [(DATA_16-1):0] UU, VV, in_range, in_low, lut_u, lut_v,
        input COMP_mux_1,
        output wire [(DATA_16-1):0] low, range
    );
    wire [(DATA_16-1):0] RR, range_1, range_2, low_1;

    wire [(DATA_32-1):0] u, v;

    assign RR = in_range >> 8;

    assign u = (RR * UU >> 32'd1) + lut_u;
    assign v = (RR * VV >> 32'd1) + lut_v;

    assign low_1 = in_low + (in_range - u[(DATA_16-1):0]);
    assign range_1 = u[(DATA_16-1):0] - v[(DATA_16-1):0];
    assign range_2 = in_range - v[(DATA_16-1):0];


    // muxes
    assign low = (COMP_mux_1 == 1'b1) ? low_1 :
                 in_low;
    assign range = (COMP_mux_1 == 1'b1) ? range_1 :
                    range_2;

endmodule
