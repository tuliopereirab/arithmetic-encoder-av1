module stage_2 #(
    parameter DATA_16 = 16,
    parameter DATA_32 = 32
    )(
        input [(DATA_16-1):0] UU, VV, A, in_range, in_low,
        input COMP_mux_1,
        output wire [(DATA_16-1):0] low, range
    );
    wire [(DATA_16-1):0] RR, range_1, range_2, low_1;
    wire [(DATA_32-1):0] mult_low_1, mult_range_1, mult_range_2;

    assign RR = in_range >> 8;

    assign mult_low_1 = RR * UU;
    assign mult_range_1 = RR * A;
    assign mult_range_2 = RR * VV;

    // From the multiplications above I am just considering the 16 less significant bits
    // As all multiplications will result in 32 bits results, I need to choose which 16 bits to use.
    assign low_1 = (in_low + in_range) - mult_low_1[(DATA_16-1):0];
    assign range_1 = mult_range_1[(DATA_16-1):0];
    assign range_2 = in_range - mult_range_2[(DATA_16-1):0];


    // muxes
    assign low = (COMP_mux_1 == 1'b1) ? low_1 :
                 in_low;
    assign range = (COMP_mux_1 == 1'b1) ? range_1 :
                    range_2;

endmodule
