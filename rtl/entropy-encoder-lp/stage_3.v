module stage_3 #(
    parameter RANGE_WIDTH = 16,
    parameter LOW_WIDTH = 24,
    parameter D_SIZE = 5
    ) (
        input [(RANGE_WIDTH-1):0] in_range, range_ready,
        input [(D_SIZE-1):0] d,
        input COMP_mux_1, bool_flag, lsb_symbol,
        input [RANGE_WIDTH:0] u, v_bool,
        input [(D_SIZE-1):0] in_s,
        input [(LOW_WIDTH-1):0] in_low,
        output wire [(LOW_WIDTH-1):0] out_low,
        output wire [(RANGE_WIDTH-1):0] out_range,
        output wire [(RANGE_WIDTH-1):0] out_bit_1, out_bit_2,       // I'll keep 16-bit output for bitstream because I'm not sure it will work with less.
        output wire [1:0] flag_bitstream,
        output wire [(D_SIZE-1):0] out_s
    );
    wire [(LOW_WIDTH-1):0] low_1, low_bool, low_not_bool;
    wire [(LOW_WIDTH-1):0] low;

    // ==================================
    // Operand Isolation for Low Updating process
    wire [(LOW_WIDTH-1):0] op_iso_and_bool, op_iso_and_lsb_symbol, op_iso_and_comp_mux_1;
    wire [(RANGE_WIDTH-1):0] op_iso_bool_range, op_iso_v_bool;
    wire [(LOW_WIDTH-1):0] op_iso_bool_low, op_iso_low_1;
    wire [(RANGE_WIDTH-1):0] op_iso_range_1, op_iso_u_1;

    assign op_iso_and_bool = (bool_flag) ? 24'd16777215 :
                            24'd0;
    assign op_iso_and_lsb_symbol = (lsb_symbol) ? 24'd16777215 :
                                    24'd0;
    assign op_iso_and_comp_mux_1 = (COMP_mux_1) ? 24'd16777215 :
                                    24'd0;

    assign op_iso_bool_range = in_range & (op_iso_and_lsb_symbol[(RANGE_WIDTH-1):0] & op_iso_and_bool[(RANGE_WIDTH-1):0]);     // Operand Isolation targeting the in_range in low_bool assignment
    assign op_iso_v_bool = v_bool[(RANGE_WIDTH-1):0] & (op_iso_and_lsb_symbol[(RANGE_WIDTH-1):0] & op_iso_and_bool[(RANGE_WIDTH-1):0]);         // Op Isolation targeting v_bool in low_bool assignment
    assign op_iso_bool_low = in_low & (op_iso_and_lsb_symbol & op_iso_and_bool);        // Operand Isolation targeting in_low in low_bool assignement when (lsb_symbol == 1)
    assign op_iso_low_1 = in_low & (op_iso_and_comp_mux_1 & ~op_iso_and_bool);   // Operand Isolation targeting in_low in low_1 assignment
    assign op_iso_range_1 = in_range & (op_iso_and_comp_mux_1[(RANGE_WIDTH-1):0] & ~op_iso_and_bool[(RANGE_WIDTH-1):0]);    // Operand Isolating targeting in_range in low_1 assignment
    assign op_iso_u_1 = u[(RANGE_WIDTH-1):0] & (op_iso_and_comp_mux_1[(RANGE_WIDTH-1):0] & ~op_iso_and_bool[(RANGE_WIDTH-1):0]);       // Operand Isolation targeting u in low_1 assignment
    // ==================================

    assign low_1 = op_iso_low_1 + (op_iso_range_1 - op_iso_u_1[(RANGE_WIDTH-1):0]);

    assign low_bool = (lsb_symbol == 1'b1) ? (op_iso_bool_low + (op_iso_bool_range - op_iso_v_bool[(RANGE_WIDTH-1):0])) :
                        in_low;

    // ------------------------------------------------------
    assign low_not_bool = (COMP_mux_1 == 1'b1) ? low_1 :
                            in_low;
    assign low = (bool_flag == 1'b1) ? low_bool :
                low_not_bool;

    // =============================================================================
    // normalization
    wire [(LOW_WIDTH-1):0] low_s0, low_s8, m_s8, m_s0;
    wire [(D_SIZE-1):0] c_internal_s0, c_internal_s8, c_norm_s0, s_s0, s_s8, s_comp;
    wire [(D_SIZE-1):0] c_bit_s0, c_bit_s8;

    // ==================================
    // Operand Isolation for Low Normalization and bitstream generation processes
    wire [(LOW_WIDTH-1):0] op_iso_and_greater_17, op_iso_and_greater_9;
    wire [(LOW_WIDTH-1):0] op_iso_m_s0, op_iso_m_s8, op_iso_m_s0_8;
    wire [(LOW_WIDTH-1):0] op_iso_low_low_s0, op_iso_low_s0, op_iso_low_s0_8, op_iso_low_s8, op_iso_low_out;
    wire [(D_SIZE-1):0] op_iso_c_norm_s0, op_iso_in_s_c_norm_s0;
    wire [(D_SIZE-1):0] op_iso_in_s_s0, op_iso_d_s0, op_iso_in_s_s8, op_iso_d_s8;
    wire [(D_SIZE-1):0] op_iso_c_int_s0, op_iso_c_int_s8;
    wire [(LOW_WIDTH-1):0] op_iso_c_bit_s0, op_iso_c_bit_s8, op_iso_low_bit_s0, op_iso_low_s0_bit_s8;
    wire [(D_SIZE-1):0] op_iso_in_s_c_bit_s0, op_iso_in_s_c_bit_s8;

    assign op_iso_and_greater_17 = (s_comp >= 17) ? 24'd16777215 :
                                    24'd0;
    assign op_iso_and_greater_9 = (s_comp >= 9) ? 24'd16777215 :
                                    24'd0;

    assign op_iso_low_low_s0 = low & op_iso_and_greater_9;  // Used in low_s0 assignment
    assign op_iso_c_norm_s0 = c_norm_s0 & op_iso_and_greater_9[(D_SIZE-1):0]; // Used in m_s0 assignment
    assign op_iso_in_s_c_norm_s0 = in_s & op_iso_and_greater_9[(D_SIZE-1):0]; // Used in c_norm_s0
    assign op_iso_m_s0 = m_s0 & op_iso_and_greater_9;   // Used in low_s0 assignment
    assign op_iso_m_s0_8 = m_s0 & op_iso_and_greater_17; // used in m_s8 assignment
    assign op_iso_m_s8 = m_s8 & op_iso_and_greater_17;  // Used in low_s8 assignment
    assign op_iso_low_s0_8 = low_s0 & op_iso_and_greater_17;    // Used in low_s8 assignment
    assign op_iso_low_s0 = low_s0 & (op_iso_and_greater_9 & ~op_iso_and_greater_17);   // Used in out_low assignment
    assign op_iso_low_s8 = low_s8 & op_iso_and_greater_17;  // Used in out_low assignment
    assign op_iso_low_out = low & (~op_iso_and_greater_9);  // Used in out_low assignment
    // -----
    assign op_iso_in_s_s0 = in_s & (op_iso_and_greater_9[(D_SIZE-1):0] & ~op_iso_and_greater_17[(D_SIZE-1):0]); // Used in c_internal_s0 assignment
    assign op_iso_in_s_s8 = in_s & op_iso_and_greater_17[(D_SIZE-1):0];   // Used in c_internal_s8 assignment
    assign op_iso_d_s0 = d & (op_iso_and_greater_9[(D_SIZE-1):0] & ~op_iso_and_greater_17[(D_SIZE-1):0]);   // Used in s_s0 assignment
    assign op_iso_d_s8 = d & op_iso_and_greater_17[(D_SIZE-1):0];   // Used in c_internal_s8 assignment
    assign op_iso_c_int_s0 = c_internal_s0 & (op_iso_and_greater_9[(D_SIZE-1):0] & ~op_iso_and_greater_17[(D_SIZE-1):0]);   // Used in s_s0 assignment
    assign op_iso_c_int_s8 = c_internal_s8 & op_iso_and_greater_17[(D_SIZE-1):0];   // Used in c_internal_s8 assignment
    // -----
    assign op_iso_c_bit_s0 = c_bit_s0 & op_iso_and_greater_9;   // Used in out_bit_1
    assign op_iso_c_bit_s8 = c_bit_s8 & op_iso_and_greater_17;  // Used in out_bit_2
    assign op_iso_low_bit_s0 = low & op_iso_and_greater_9;  // Used in out_bit_1
    assign op_iso_low_s0_bit_s8 = low_s0 & op_iso_and_greater_17;   // Used in out_bit_2
    assign op_iso_in_s_c_bit_s0 = in_s & op_iso_and_greater_9[(D_SIZE-1):0];  // Used in c_bit_s0
    assign op_iso_in_s_c_bit_s8 = in_s & op_iso_and_greater_17[(D_SIZE-1):0]; // Used in c_bit_s8
    // ==================================


    assign s_comp = in_s + d;
    // ----------------------
    assign c_norm_s0 = op_iso_in_s_c_norm_s0 + 5'd7;    // Using Operand Isolation
    assign c_internal_s0 = op_iso_in_s_s0 + 5'd16;        // Used to update cnt (s) || Using Operand Isolation
    assign m_s0 = (24'd1 << op_iso_c_norm_s0) - 24'd1;  // Using Operand Isolation

    assign s_s0 = op_iso_c_int_s0 + op_iso_d_s0 - 5'd24;    // Used to update cnt (s)   || Using Operand Isolation
    assign low_s0 = op_iso_low_low_s0 & op_iso_m_s0;  // Using Operand Isolation
    // -----------------------
    assign c_internal_s8 = op_iso_in_s_s8 + 5'd8;   // Using Operand Isolation
    assign m_s8 = op_iso_m_s0_8 >> 5'd8;    // Using Operand Isolation

    assign s_s8 = op_iso_c_int_s8 + op_iso_d_s8 - 5'd24;    // Using Operand Isolation
    assign low_s8 = op_iso_low_s0_8 & op_iso_m_s8;   // Using Operand Isolation
    // =============================================================================
    // outputs
    assign out_range = range_ready;

    assign out_low = ((s_comp >= 9) && (s_comp < 17)) ? op_iso_low_s0 << d :    // Using Operand Isolation
                        (s_comp >= 17) ? op_iso_low_s8 << d :   // Using Operand Isolation
                        op_iso_low_out << d;    // Using Operand Isolation

    assign out_s = ((s_comp >= 9) && (s_comp < 17)) ? s_s0 :
                    (s_comp >= 17) ? s_s8 :
                    s_comp;
    // pre-bitstream generation
    assign c_bit_s0 = op_iso_in_s_c_bit_s0 + 5'd7;
    assign c_bit_s8 = op_iso_in_s_c_bit_s8 - 5'd1;

    assign out_bit_1 = (s_comp >= 9) ? op_iso_low_bit_s0 >> op_iso_c_bit_s0 :                 // Bit_1 will always be saved in the position addr in the buffer
                        16'd0;
    assign out_bit_2 = (s_comp >= 17) ? op_iso_low_s0_bit_s8 >> op_iso_c_bit_s8 :                // Bit_2 will be saved in the position addr+1 in the buffer
                        16'd0;

    assign flag_bitstream = ((s_comp >= 9) && (s_comp < 17)) ? 2'd1 :       // The flag will be used to show the register in the end of this module when to save the new bits
                            (s_comp >= 17) ? 2'd2 :                         // As it can give a different number of outputs, it's necessary to indicate when to save both or only 1
                            2'd0;                                           // 01: save only bit_1; 11: save both


    // Architecture for Offs is officially removed from the final AV1's architecture due to be useless
    // The Offs are useful for the methodology used by the AV1's reference software to propagate the carry
    // However, with the carry propagation block designed here, it is not useful at all.

    // assign out_offs = ((s_comp >= 9) && (s_comp < 17)) ? in_offs + 5'd1 :   // This is the offs_counter which will be used in the carry propagation block (which will be created as stage 4)
    //                     (s_comp >= 17) ? in_offs + 5'd2 :
    //                     in_offs;

endmodule
