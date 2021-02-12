// This module will be responsible for generating the final bitstreams according to the CNT
// This module corresponds to the beginning of the OD_EC_ENC_DONE function
module final_bits_generator #(
    parameter OUTPUT_BITSTREAM_WIDTH = 16,
    parameter D_SIZE = 5,
    parameter LOW_WIDTH = 24
    ) (
        input [(D_SIZE-1):0] in_cnt,
        input [(LOW_WIDTH-1):0] in_low,
        input in_flag_final,        // s4_final_flag_2_3 at stage_4.v
        output wire [1:0] flag,
        output wire [(OUTPUT_BITSTREAM_WIDTH-1):0] out_bit_1, out_bit_2
    );
    wire [(LOW_WIDTH-1):0] e_1, e_2, m, n;
    wire [(D_SIZE-1):0] c_1, c_2, s;

    // =======================
    // Operand Isolation
    wire [(LOW_WIDTH-1):0] op_iso_and;
    wire [(LOW_WIDTH-1):0] op_iso_in_low, op_iso_in_n, op_iso_e_1, op_iso_e_2;
    wire [(D_SIZE-1):0] op_iso_in_cnt, op_iso_c_1, op_iso_c_2;

    assign op_iso_and = (in_flag_final) ? 24'b1111_1111_1111_1111_1111_1111 :
                        24'd0;

    assign op_iso_in_cnt = in_cnt & op_iso_and[(D_SIZE-1):0];   // Used in n, c_1, c_2, s
    assign op_iso_in_low = in_low & op_iso_and; // Used in e_1
    assign op_iso_e_1 = e_1 & op_iso_and;   // Used in e_2
    assign op_iso_e_2 = e_2 & op_iso_and;    // Used in out_bit_2
    assign op_iso_in_n = n & op_iso_and;    // Used in e_2
    // ---
    assign op_iso_c_1 = c_1 & op_iso_and[(D_SIZE-1):0];
    assign op_iso_c_2 = c_2 & op_iso_and[(D_SIZE-1):0];
    // ---
    assign m = (in_flag_final) ? 24'h3FFF :     // Some kind of operand isolation
                24'd0;
    // =======================

    assign n = (5'd1 << (op_iso_in_cnt + 5'd7)) - 5'd1;   // Using Operand Isolation

    assign e_1 = ((op_iso_in_low + m) & ~m) | (m + 24'd1);      // Using Operand Isolation
    assign e_2 = op_iso_e_1 & op_iso_in_n;      // Using Operand Isolation

    assign c_1 = op_iso_in_cnt + 5'd7;    // Using Operand Isolation
    assign c_2 = op_iso_in_cnt - 5'd1;    // Using Operand Isolation

    assign s = op_iso_in_cnt + 5'd10; // Using Operand Isolation

    // outputs
    assign flag =   ((s > 9) && (s <= 17)) ? 2'b01 :
                    (s > 17) ? 2'b10 :
                    2'b00;

    assign out_bit_1 = op_iso_e_1 >> op_iso_c_1;
    assign out_bit_2 = op_iso_e_2 >> op_iso_c_2;


endmodule
