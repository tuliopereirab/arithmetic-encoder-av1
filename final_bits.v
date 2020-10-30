// This module will be responsible for generating the final bitstreams according to the CNT
// This module corresponds to the beginning of the OD_EC_ENC_DONE function
module final_bits_generator #(
    parameter OUTPUT_BITSTREAM_WIDTH = 16,
    parameter D_SIZE = 5,
    parameter LOW_WIDTH = 24
    ) (
        input [(D_SIZE-1):0] in_cnt,
        input [(LOW_WIDTH-1):0] in_low,
        output wire [1:0] flag,
        output wire [(OUTPUT_BITSTREAM_WIDTH-1):0] out_bit_1, out_bit_2
    );
    wire [(LOW_WIDTH-1):0] e_1, e_2, m;
    wire [(D_SIZE-1):0] c_1, c_2, n, s;

    assign m = 24'h3FFF;

    assign n = (1 << (in_cnt + 7)) - 1;

    assign e_1 = ((in_low + m) & ~m) | (m + 1);
    assign e_2 = (((in_low + m) & ~m) | (m + 1)) & n;

    assign c_1 = in_cnt + 7;
    assign c_2 = in_cnt - 1;

    assign s = in_cnt + 1;

    // outputs
    assign flag = (s > 18) ? 2'b11 :
                    2'b01;
    assign out_bit_1 = e_1 >> c_1;
    assign out_bit_2 = e_2 >> c_2;


endmodule
