// The stage 3 of this architecture was adapted from the following article.
// The adaptation made was to switch the length from 8 bits to 16 bits.
// This adaptation made it possible to use this block in the AV1 arithmetic encoder.

    // @INPROCEEDINGS{6116523,
    //   author={Z. {Liu} and D. {Wang}},
    //   booktitle={2011 18th IEEE International Conference on Image Processing},
    //   title={One-round renormalization based 2-bin/cycle H.264/AVC CABAC encoder},
    //   year={2011},
    //   volume={},
    //   number={},
    //   pages={369-372},
    //   doi={10.1109/ICIP.2011.6116523}
    // }

module stage_3 #(
    parameter RANGE_WIDTH = 16,
    parameter LOW_WIDTH = 24,
    parameter D_SIZE = 5
    )(
        input [(RANGE_WIDTH-1):0] range,
        input [(LOW_WIDTH-1):0] low,
        input [(D_SIZE-1):0] in_s,
        output wire [(RANGE_WIDTH-1):0] out_range,
        output wire [(LOW_WIDTH-1):0] out_low,
        output wire [(D_SIZE-1):0] out_s
    );


    wire [(LOW_WIDTH-1):0] low_1;
    wire [((RANGE_WIDTH/2)-1):0] mux_2, most_sig_low;
    wire [(D_SIZE-1):0] d, s_internal_1, s_internal_2;
    wire v_lzc;     // this is the bit that shows if lzc is valid or not (I'm not really sure about this)




    leading_zero #(
        .RANGE_WIDTH_LCZ (RANGE_WIDTH),
        .D_SIZE_LZC (D_SIZE)
        ) lzc (
            .in_range (range),
            .lzc_out (d),
            .v (v_lzc)
        );


    assign low_1 = low << d;
    assign s_internal_1 = in_s + d;
    assign s_internal_2 = ((in_s + 5'd16) + d) - 5'd24;

    assign mux_2 = (s_internal_1 >= 5'd9) ? 8'd0 :
                    8'd255;

    assign out_s = (s_internal_1 >= 5'd9) ? s_internal_2 :
                    s_internal_1;

    assign most_sig_low = low_1[(LOW_WIDTH-1):RANGE_WIDTH] & mux_2;

    // outputs
    assign out_low = {most_sig_low, low_1[(RANGE_WIDTH-1):0]};
    assign out_range = range << d;
endmodule
