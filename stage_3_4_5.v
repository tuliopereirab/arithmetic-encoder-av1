module stage_3_4_5 #(
    parameter DATA_16 = 16,
    parameter DATA_32 = 32,
    parameter D_SIZE = 5
    )(
        input [(DATA_16-1):0] low, range,
        input [(DATA_32-2):0] in_cnt,
        output wire [(DATA_16-1):0] out_low, out_range,
        output wire [(DATA_32-1):0] out_cnt
    );

    // stage 3
    wire [(D_SIZE-1):0] lzc_rng, D;
    wire [(DATA_32-1):0] C_s0, M_s0;

    leading_zero #(
        .RANGE_SIZE (DATA_16)
        ) LZC (
            .in_range (range),
            .lzc_out (lzc_rng)
        );
    assign D = 5'b10000 - lzc_rng;
    assign C_s0 = in_cnt + 32'd16;
    assign M_s0 = (32'd1 << C_s0) - 32'd1;

    // ---------------------------------------------------
    // stage 4
    wire [(DATA_32-1):0] S, M_s8, C_s8;
    wire [(DATA_16-1):0] low_s8;
    wire COMP_mux_2, COMP_mux_3;

    assign S = in_cnt + {26'd0, D};
    assign COMP_mux_2 = (S >= 32'd0) ? 1'b1 :
                        1'b0;
    assign COMP_mux_3 = (S >= 32'd8) ? 1'b1 :
                        1'b0;

    assign M_s8 = M_s0 >> 8;
    assign C_s8 = C_s0 - 32'd8;
    assign low_s8 = low & M_s0[(DATA_16-1):0];        // already reduced for 16 bits

    // ---------------------------------------------------
    // stage 5
    wire [(DATA_16):0] MUX_3_low, out_low_1, out_low_2;
    wire [(DATA_32):0] MUX_3_c, MUX_3_m, out_cnt_1;

    assign MUX_3_low = (COMP_mux_3) ? low_s8   :
                        low;
    assign MUX_3_c = (COMP_mux_3) ? C_s8    :
                        C_s0;
    assign MUX_3_m = (COMP_mux_3) ? M_s8    :
                        M_s0;

    assign out_low_1 = (MUX_3_low & MUX_3_m) << D;
    assign out_low_2 = low << D;

    assign out_cnt_1 = (MUX_3_c + {25'd0, D}) - 32'd24;

    // outputs
    assign out_range = range << D;
    assign out_low = (COMP_mux_2) ? out_low_1 :
                        out_low_2;
    assign out_cnt = (COMP_mux_2) ? out_cnt_1   :
                     S;
endmodule
