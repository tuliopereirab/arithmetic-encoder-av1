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
    parameter D_SIZE = 5,
    parameter SYMBOL_WIDTH = 4
    )(
        input [(RANGE_WIDTH-1):0] UU, VV, in_range, lut_u, lut_v,
        input COMP_mux_1,
        // bool
        input [(SYMBOL_WIDTH-1):0] symbol,
        input bool_flag,
        // former stage 3 outputs
        output wire [RANGE_WIDTH:0] u, v_bool,
        output wire [(RANGE_WIDTH-1):0] initial_range, out_range,
        output wire [(D_SIZE-1):0] out_d,
        output wire bool_out, lsb_symbol,
        output wire COMP_mux_1_out
    );
    wire [(RANGE_WIDTH-1):0] RR, range_1, range_2, range_bool, range_not_bool;
    // ==========================================================================================
    // Operand isolation
    wire [(RANGE_WIDTH-1):0] op_iso_and_comp_mux_1, op_iso_and_bool, op_iso_and_symbol;
    wire [(RANGE_WIDTH-1):0] op_iso_lut_u, op_iso_lut_v;
    wire [(RANGE_WIDTH-1):0] op_iso_UU, op_iso_range_in;

    assign op_iso_and_comp_mux_1 =  (COMP_mux_1) ? 16'd65535 :
                                    16'd0;

    assign op_iso_and_bool = (bool_flag) ? 16'd65535 :
                            16'd0;

    assign op_iso_and_symbol = (symbol[0]) ? 16'd65535 :
                                16'd0;

    assign op_iso_lut_u = lut_u & (~op_iso_and_bool & op_iso_and_comp_mux_1);  // Isolating Lut_u
    assign op_iso_UU = UU & (~op_iso_and_bool & op_iso_and_comp_mux_1); // Isolating UU - Bool = 0 and COMP_mux_1 = 1
    assign op_iso_lut_v = lut_v & (~op_iso_and_bool);  // Isolating lut_v in std V
    assign op_iso_range_in = in_range & (op_iso_and_bool & ~op_iso_and_symbol);   // Isolating in_range in boolean, symbol = 1
    // ==========================================================================================

    // former stage 3 input
    wire [(RANGE_WIDTH-1):0] range;

    // -------------------------------

    wire [(RANGE_WIDTH):0] v, RV;


    assign RR = in_range >> 8;
    assign RV = (RR * VV >> 1);

    assign u = (RR * op_iso_UU >> 1) + op_iso_lut_u;    // Using Operand Isolation
    assign v = RV + op_iso_lut_v;                       // Using Operand Isolation


    assign range_1 = u[(RANGE_WIDTH-1):0] - v[(RANGE_WIDTH-1):0];
    assign range_2 = in_range - v[(RANGE_WIDTH-1):0];


    // muxes

    assign range_not_bool = (COMP_mux_1 == 1'b1) ? range_1 :
                    range_2;

    // bool
    assign v_bool = RV + 16'd4;

    assign range_bool = (symbol[0] == 1'b1) ? v_bool[(RANGE_WIDTH-1):0] :
                        op_iso_range_in - v_bool[(RANGE_WIDTH-1):0];   // Using Operand Isolation
    // -------------------

    // final stage 2
    // this part define which function results will be used:
        // Q15 normal
        // Boolean

    assign range = (bool_flag == 1'b1) ? range_bool :
                    range_not_bool;


    // -------------------------------
    // former stage 3
    // normalization for range
    wire [(D_SIZE-1):0] d;
    wire v_lzc;     // this is the bit that shows if lzc is valid or not (I'm not really sure about this)

    leading_zero #(
        .RANGE_WIDTH_LCZ (RANGE_WIDTH),
        .D_SIZE_LZC (D_SIZE)
        ) lzc (
            .in_range (range),
            .lzc_out (d),
            .v (v_lzc)
        );


    // outputs
    // v_bool is above
    // u is above
    assign initial_range = in_range;
    assign out_d = d;
    assign out_range = range << d;
    assign bool_out = bool_flag;
    assign lsb_symbol = symbol[0];    // The definition of Low_bool uses the lsb symbol.
    assign COMP_mux_1_out = COMP_mux_1;
    //-----------------------------------------
endmodule
