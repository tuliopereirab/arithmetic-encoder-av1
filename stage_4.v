// This is the Carry Propagation stage.

// The main idea behind this architecture is to hold the a bitstream until the next comes
// By doing that it's possible to ensure that the carry propagation will be done properly


// POSSIBLE PROBLEM
    // This architecture, however, has a problem:
        // Everytime the architecture receive the following numbers, in the exact order shown below, the output will have an error
            // 255
            // 300 (or any number >= 256)
        // This happens because, usually, it's necessary to add the bits [23:16] from the second number into the first one
        // Most of the times, only the bit number 16 is on, which means that it's going to happen an overflow and the first output will be misrepresented.

module stage_4 #(
    parameter OUTPUT_DATA_WIDTH = 8,
    parameter INPUT_DATA_WIDTH = 16
    ) (
        input [1:0] flag,             // 01: save only bit_1; 11: save both
        input flag_final_bits,
        input [(INPUT_DATA_WIDTH-1):0] in_new_bitstream_1, in_new_bitstream_2,          // 1- first (sometimes the only) to be generated, 2- only used when 2 bitstreams are being generated
        input [(OUTPUT_DATA_WIDTH-1):0] in_previous_bitstream,
        output wire [(OUTPUT_DATA_WIDTH-1):0] out_bitstream_1, out_bitstream_2, bitstream_hold,
        output wire [1:0] out_flag
    );
    assign out_flag =   ((flag_final_bits) && (flag == 2'b00)) ? 2'b01 :            // 1 output
                        ((flag_final_bits) && (flag == 2'b01)) ? 2'b11 :            // 2 outputs
                        ((flag_final_bits) && (flag == 2'b11)) ? 2'b10 :            // 3 outputs!
                        flag;

    assign out_bitstream_1 = in_previous_bitstream + in_new_bitstream_1[(INPUT_DATA_WIDTH-1):OUTPUT_DATA_WIDTH];

    assign out_bitstream_2 = (flag == 2'b11) ? in_new_bitstream_1[(OUTPUT_DATA_WIDTH-1):0] +  in_new_bitstream_2[(INPUT_DATA_WIDTH-1):OUTPUT_DATA_WIDTH]:
                            8'd0;

    assign bitstream_hold = ((flag == 2'b11) || (flag_final_bits)) ? in_new_bitstream_2[(OUTPUT_DATA_WIDTH-1):0] :
                            (flag == 2'b10) ? in_new_bitstream_1[(OUTPUT_DATA_WIDTH-1):0] :
                            in_previous_bitstream;

endmodule
