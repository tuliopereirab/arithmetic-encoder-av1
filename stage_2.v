// This stage finishes the encoding Q15 process and also executes the one-round normalization
// The One-round normalization is an adaptation of the following article:
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

// Everytime it is shown 'Former Stage 3', it is actually talking about the one-round normalization


module stage_2 #(
    parameter RANGE_WIDTH = 16,
    parameter LOW_WIDTH = 24,
    parameter D_SIZE = 5,
    parameter SYMBOL_WIDTH = 4
    )(
        input [(RANGE_WIDTH-1):0] UU, VV, in_range, lut_u, lut_v,
        input [(LOW_WIDTH-1):0] in_low,
        input COMP_mux_1,
        // bool
        input [(SYMBOL_WIDTH-1):0] symbol,
        input bool,
        // former stage 3 input
        input [(D_SIZE-1):0] in_s,
        // former stage 3 outputs
        output wire [(D_SIZE-1):0] out_s,
        output wire [(RANGE_WIDTH-1):0] out_range,
        output wire [(LOW_WIDTH-1):0] out_low
    );
    wire [(RANGE_WIDTH-1):0] RR, range_1, range_2, range_bool, range_not_bool;
    wire [(LOW_WIDTH-1):0] low_1, low_bool, low_not_bool;

    // former stage 3 input
    wire [(RANGE_WIDTH-1):0] range;
    wire [(LOW_WIDTH-1):0] low;
    // -------------------------------

    wire [(RANGE_WIDTH):0] u, v, v_bool;

    assign RR = in_range >> 8;

    assign u = (RR * UU >> 1) + lut_u;
    assign v = (RR * VV >> 1) + lut_v;

    assign low_1 = in_low + (in_range - u[(RANGE_WIDTH-1):0]);
    assign range_1 = u[(RANGE_WIDTH-1):0] - v[(RANGE_WIDTH-1):0];
    assign range_2 = in_range - v[(RANGE_WIDTH-1):0];


    // muxes
    assign low_not_bool = (COMP_mux_1 == 1'b1) ? low_1 :
                 in_low;
    assign range_not_bool = (COMP_mux_1 == 1'b1) ? range_1 :
                    range_2;

    // bool
    assign v_bool = (RR * VV >> 1) + 16'd4;
    assign low_bool = (symbol[0] == 1'b1) ? (in_low + (in_range - v_bool[(RANGE_WIDTH-1):0])) :
                        in_low;
    assign range_bool = (symbol[0] == 1'b1) ? v_bool[(RANGE_WIDTH-1):0] :
                        in_range - v_bool[(RANGE_WIDTH-1):0];
    // -------------------

    // final stage 2
    // this part define which function results will be used:
        // Q15 normal
        // Boolean
    assign low = (bool == 1'b1) ? low_bool :
                low_not_bool;
    assign range = (bool == 1'b1) ? range_bool :
                    range_not_bool;


    // -------------------------------
    // former stage 3

    wire [(LOW_WIDTH-1):0] low_1_s3;
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

    assign low_1_s3 = low << d;
    assign s_internal_1 = in_s + d;
    assign s_internal_2 = ((in_s + 5'd16) + d) - 5'd24;

    assign mux_2 = (s_internal_1 >= 5'd9) ? 8'd0 :
                    8'd255;

    assign out_s = (s_internal_1 >= 5'd9) ? s_internal_2 :
                    s_internal_1;

    assign most_sig_low = low_1_s3[(LOW_WIDTH-1):RANGE_WIDTH] & mux_2;

    // outputs
    assign out_low = {most_sig_low, low_1_s3[(RANGE_WIDTH-1):0]};
    assign out_range = range << d;
    //-----------------------------------------
endmodule
