module stage_3 #(
    parameter RANGE_WIDTH = 16,
    parameter LOW_WIDTH = 24,
    parameter D_SIZE = 5
    ) (
        input [1:0] bool_symbol,            // this input is a mix between the least significant bit of symbol and the bool flag
                                            // [1]: bool flag; [0]: symbol[0]
        input [(RANGE_WIDTH-1):0] in_range, range_ready,
        input [(D_SIZE-1):0] d,
        input COMP_mux_1,
        input [RANGE_WIDTH:0] u, v_bool,
        input [(D_SIZE-1):0] in_s,
        input [(LOW_WIDTH-1):0] in_low,
        output wire [(LOW_WIDTH-1):0] out_low,
        output wire [(RANGE_WIDTH-1):0] out_range,
        output wire [(D_SIZE-1):0] out_s
    );
    wire [(LOW_WIDTH-1):0] low_1, low_bool, low_not_bool;
    wire [(LOW_WIDTH-1):0] low;

    assign low_1 = in_low + (in_range - u[(RANGE_WIDTH-1):0]);

    assign low_bool = (bool_symbol[0] == 1'b1) ? (in_low + (in_range - v_bool[(RANGE_WIDTH-1):0])) :
                        in_low;

    // ------------------------------------------------------
    assign low_not_bool = (COMP_mux_1 == 1'b1) ? low_1 :
                            in_low;
    assign low = (bool_symbol[1] == 1'b1) ? low_bool :
                low_not_bool;

    // =============================================================================
    // normalization
    wire [(LOW_WIDTH-1):0] low_s0, low_s8, m_s8, m_s0;
    wire [(D_SIZE-1):0] c_internal_s0, c_internal_s8, c_norm_s0, s_s0, s_s8, s_comp;

    assign s_comp = in_s + d;
    // ----------------------
    assign c_norm_s0 = in_s + 5'd7;
    assign c_internal_s0 = in_s + 5'd16;
    assign m_s0 = (24'd1 << c_norm_s0) - 24'd1;

    assign s_s0 = c_internal_s0 + d - 5'd24;
    assign low_s0 = low & m_s0;
    // -----------------------
    assign c_internal_s8 = in_s + 5'd8;
    assign m_s8 = m_s0 >> 5'd8;

    assign s_s8 = c_internal_s8 + d - 5'd24;
    assign low_s8 = low_s0 & m_s8;
    // =============================================================================
    // outputs
    assign out_range = range_ready;

    assign out_low = ((s_comp >= 9) && (s_comp < 17)) ? low_s0 << d :
                        (s_comp >= 17) ? low_s8 << d :
                        low << d;

    assign out_s = ((s_comp >= 9) && (s_comp < 17)) ? s_s0 :
                    (s_comp >= 17) ? s_s8 :
                    s_comp;

endmodule
