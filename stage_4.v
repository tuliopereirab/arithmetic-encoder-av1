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
// SOLUTION
    // Create a stand-by output for the number before 255
        // 1- In case I get 255, hold the number before
        // 2- Wait for the next input
            // 2.1- Next input flag 01: output bit_1 and bit_2, out_flag 11
            // 2.2- Next input flag 11: output bit_1, bit_2 and bit_3, out_flag 10

// Final bits generation sequence
    // 1. Generate the last bitstream
    // 2. get the flag
        // 2.1. Input flag 01: output bit_1 and bit_2, out_flag 11
        // 2.2. Input flag 11: output bit_1, bit_2 and bit_3, out_flag 10
        // 2.3. Input flag 00: output bit_1, out_flag 01

// The idea behind this block can be found: https://docs.google.com/spreadsheets/d/1TxM0V8Arepv4CVbWq-B_VGT77I1iNx7inVRwQACSpPo/edit?usp=sharing

module stage_4 #(
    parameter OUTPUT_DATA_WIDTH = 8,
    parameter INPUT_DATA_WIDTH = 16
    ) (
        input [1:0] flag,             // 01: save only bit_1; 11: save both
        input flag_final_bits, in_flag_standby, flag_possible_error_in, flag_first,
        input [(INPUT_DATA_WIDTH-1):0] in_new_bitstream_1, in_new_bitstream_2,          // 1- first (sometimes the only) to be generated, 2- only used when 2 bitstreams are being generated
        input [(OUTPUT_DATA_WIDTH-1):0] in_previous_bitstream, in_standby_bitstream,
        output wire [(OUTPUT_DATA_WIDTH-1):0] out_bitstream_1, out_bitstream_2, out_bitstream_3, bitstream_hold, out_standby_bitstream,
        output wire [2:0] out_flag,
        output wire out_flag_last, out_flag_standby, flag_possible_error_out, confirmed_error
    );
    assign out_flag_last = flag_final_bits;

    wire [(INPUT_DATA_WIDTH-1):0] out_3, out_2;

    // Error detectiong will only be activated if
        // Flag possible error = 1
        // Bit_1 > 255
    assign confirmed_error =    ((flag_possible_error_in) && (in_new_bitstream_1 > 16'd255)) ? 1'b1 :
                                1'b0;
    assign flag_possible_error_out =    ((in_flag_standby) && (!flag_final_bits) && (flag == 2'b01) && (in_new_bitstream_1 == 16'd255)) ? 1'b1 :
                                        ((in_new_bitstream_1 == 16'd255) && (in_new_bitstream_2 == 16'd255)) ? 1'b1 :
                                        1'b0;

    // The flag[2] bit will only be activated when:
        // Stand-by flag = 1;
        // in_flag = 11
        // Final flag = 1
    assign out_flag[2] =    (flag_first) ? 1'b0 :
                            ((in_flag_standby) && (flag_final_bits) && (flag == 2'b11))   ? 1'b1 :
                            1'b0;

    assign out_flag[1:0] =  (flag_first) ? 2'b00 :
                            ((!in_flag_standby) && (!flag_final_bits) && (flag == 2'b01) && (in_new_bitstream_1 != 16'd255)) ? 2'b01 :
                            ((!in_flag_standby) && (!flag_final_bits) && (flag == 2'b11) && (in_new_bitstream_1 != 16'd255) && (in_new_bitstream_2 != 16'd255)) ? 2'b11 :
                            ((!in_flag_standby) && (flag_final_bits) && (flag == 2'b00)) ? 2'b01 :
                            ((!in_flag_standby) && (flag_final_bits) && (flag == 2'b01) && (in_new_bitstream_1 != 16'd255)) ? 2'b11 :
                            ((!in_flag_standby) && (flag_final_bits) && (flag == 2'b11)) ? 2'b10 :
                            ((!in_flag_standby) && (!flag_final_bits) && (flag == 2'b01) && (in_new_bitstream_1 == 16'd255)) ? 2'b00 :
                            ((!in_flag_standby) && (!flag_final_bits) && (flag == 2'b11) && (in_new_bitstream_1 == 16'd255) && (in_new_bitstream_2 != 16'd255)) ? 2'b11 :
                            ((!in_flag_standby) && (!flag_final_bits) && (flag == 2'b11) && (in_new_bitstream_1 != 16'd255) && (in_new_bitstream_2 == 16'd255)) ? 2'b01 :
                            ((!in_flag_standby) && (!flag_final_bits) && (flag == 2'b11) && (in_new_bitstream_1 == 16'd255) && (in_new_bitstream_2 == 16'd255)) ? 2'b01 :
                            ((in_flag_standby) && (!flag_final_bits) && (flag == 2'b01) && (in_new_bitstream_1 != 16'd255)) ? 2'b11 :
                            ((in_flag_standby) && (!flag_final_bits) && (flag == 2'b11) && (in_new_bitstream_1 != 16'd255) && (in_new_bitstream_2 != 16'd255)) ? 2'b10 :
                            ((in_flag_standby) && (!flag_final_bits) && (flag == 2'b01) && (in_new_bitstream_1 == 16'd255)) ? 2'b01 :
                            ((in_flag_standby) && (!flag_final_bits) && (flag == 2'b11) && (in_new_bitstream_1 != 16'd255) && (in_new_bitstream_2 == 16'd255)) ? 2'b11 :
                            ((in_flag_standby) && (!flag_final_bits) && (flag == 2'b11) && (in_new_bitstream_1 == 16'd255) && (in_new_bitstream_2 != 16'd255)) ? 2'b10 :
                            ((in_flag_standby) && (!flag_final_bits) && (flag == 2'b11) && (in_new_bitstream_1 == 16'd255) && (in_new_bitstream_2 == 16'd255)) ? 2'b10 :
                            ((in_flag_standby) && (flag_final_bits) && (flag == 2'b00)) ? 2'b11 :
                            ((in_flag_standby) && (flag_final_bits) && (flag == 2'b01)) ? 2'b10 :
                            2'b00;

    assign out_flag_standby =   (flag_first) ? 1'b0 :       // This is the solution to ensure that Standby output will be zero when the first input reaches this block
                                ((!in_flag_standby) && (!flag_final_bits) && (flag == 2'b01) && (in_new_bitstream_1 != 16'd255)) ? 1'b0 :
                                ((!in_flag_standby) && (!flag_final_bits) && (flag == 2'b11) && (in_new_bitstream_1 != 16'd255) && (in_new_bitstream_2 != 16'd255)) ? 1'b0 :
                                ((!in_flag_standby) && (flag_final_bits) && (flag == 2'b00)) ? 1'b0 :
                                ((!in_flag_standby) && (flag_final_bits) && (flag == 2'b01) && (in_new_bitstream_1 != 16'd255)) ? 1'b0 :
                                ((!in_flag_standby) && (flag_final_bits) && (flag == 2'b11)) ? 1'b0 :
                                ((!in_flag_standby) && (!flag_final_bits) && (flag == 2'b01) && (in_new_bitstream_1 == 16'd255)) ? 1'b1 :
                                ((!in_flag_standby) && (!flag_final_bits) && (flag == 2'b11) && (in_new_bitstream_1 == 16'd255) && (in_new_bitstream_2 != 16'd255)) ? 1'b0 :
                                ((!in_flag_standby) && (!flag_final_bits) && (flag == 2'b11) && (in_new_bitstream_1 != 16'd255) && (in_new_bitstream_2 == 16'd255)) ? 1'b1 :
                                ((!in_flag_standby) && (!flag_final_bits) && (flag == 2'b11) && (in_new_bitstream_1 == 16'd255) && (in_new_bitstream_2 == 16'd255)) ? 1'b1 :
                                ((in_flag_standby) && (!flag_final_bits) && (flag == 2'b01) && (in_new_bitstream_1 != 16'd255)) ? 1'b0 :
                                ((in_flag_standby) && (!flag_final_bits) && (flag == 2'b11) && (in_new_bitstream_1 != 16'd255) && (in_new_bitstream_2 != 16'd255)) ? 1'b0 :
                                ((in_flag_standby) && (!flag_final_bits) && (flag == 2'b01) && (in_new_bitstream_1 == 16'd255)) ? 1'b1 :
                                ((in_flag_standby) && (!flag_final_bits) && (flag == 2'b11) && (in_new_bitstream_1 != 16'd255) && (in_new_bitstream_2 == 16'd255)) ? 1'b1 :
                                ((in_flag_standby) && (!flag_final_bits) && (flag == 2'b11) && (in_new_bitstream_1 == 16'd255) && (in_new_bitstream_2 != 16'd255)) ? 1'b0 :
                                ((in_flag_standby) && (!flag_final_bits) && (flag == 2'b11) && (in_new_bitstream_1 == 16'd255) && (in_new_bitstream_2 == 16'd255)) ? 1'b0 :
                                ((in_flag_standby) && (flag_final_bits) && (flag == 2'b00)) ? 1'b0 :
                                ((in_flag_standby) && (flag_final_bits) && (flag == 2'b01)) ? 1'b0 :
                                ((in_flag_standby) && (flag_final_bits) && (flag == 2'b11)) ? 1'b0 :
                                ((!flag_final_bits) && (flag == 2'b00)) ? in_flag_standby :
                                1'b0;

    // Bitstreams
    assign out_3 = in_new_bitstream_1 + in_new_bitstream_2[(INPUT_DATA_WIDTH-1):OUTPUT_DATA_WIDTH];

    assign out_2 =  (!in_flag_standby) ? in_new_bitstream_1 + in_new_bitstream_2[(INPUT_DATA_WIDTH-1):OUTPUT_DATA_WIDTH] :
                    ((in_flag_standby) && (flag == 2'b01)) ? in_previous_bitstream + in_new_bitstream_1[(INPUT_DATA_WIDTH-1):OUTPUT_DATA_WIDTH] :
                    ((in_flag_standby) && (!flag_final_bits) && (flag == 2'b11) && (in_new_bitstream_1 != 16'd255)) ? in_previous_bitstream + in_new_bitstream_1[(INPUT_DATA_WIDTH-1):OUTPUT_DATA_WIDTH] :
                    in_previous_bitstream + out_3[(INPUT_DATA_WIDTH-1):OUTPUT_DATA_WIDTH];

    assign out_bitstream_1 =    ((!in_flag_standby) && (!flag_final_bits) && (flag == 2'b01) && (in_new_bitstream_1 != 16'd255)) ? in_previous_bitstream + in_new_bitstream_1[(INPUT_DATA_WIDTH-1):OUTPUT_DATA_WIDTH] :
                                ((!in_flag_standby) && (!flag_final_bits) && (flag == 2'b11) && (in_new_bitstream_1 != 16'd255) && (in_new_bitstream_2 != 16'd255)) ? in_previous_bitstream + out_2[(INPUT_DATA_WIDTH-1):OUTPUT_DATA_WIDTH] :
                                ((!in_flag_standby) && (flag_final_bits) && (flag == 2'b00)) ? in_previous_bitstream :
                                ((!in_flag_standby) && (flag_final_bits) && (flag == 2'b01) && (in_new_bitstream_1 != 16'd255)) ? in_previous_bitstream + in_new_bitstream_1[(INPUT_DATA_WIDTH-1):OUTPUT_DATA_WIDTH] :
                                ((!in_flag_standby) && (flag_final_bits) && (flag == 2'b11)) ? in_previous_bitstream + out_2[(INPUT_DATA_WIDTH-1):OUTPUT_DATA_WIDTH] :
                                ((!in_flag_standby) && (!flag_final_bits) && (flag == 2'b01) && (in_new_bitstream_1 == 16'd255)) ? 8'd0 :
                                ((!in_flag_standby) && (!flag_final_bits) && (flag == 2'b11) && (in_new_bitstream_1 == 16'd255) && (in_new_bitstream_2 != 16'd255)) ? in_previous_bitstream + out_2[(INPUT_DATA_WIDTH-1):OUTPUT_DATA_WIDTH] :
                                ((!in_flag_standby) && (!flag_final_bits) && (flag == 2'b11) && (in_new_bitstream_1 != 16'd255) && (in_new_bitstream_2 == 16'd255)) ? in_previous_bitstream + in_new_bitstream_1[(INPUT_DATA_WIDTH-1):OUTPUT_DATA_WIDTH] :
                                ((!in_flag_standby) && (!flag_final_bits) && (flag == 2'b11) && (in_new_bitstream_1 == 16'd255) && (in_new_bitstream_2 == 16'd255)) ? in_previous_bitstream + in_new_bitstream_1[(INPUT_DATA_WIDTH-1):OUTPUT_DATA_WIDTH] :
                                ((in_flag_standby) && (!flag_final_bits) && (flag == 2'b01) && (in_new_bitstream_1 != 16'd255)) ? in_standby_bitstream + out_2[(INPUT_DATA_WIDTH-1):OUTPUT_DATA_WIDTH] :
                                ((in_flag_standby) && (!flag_final_bits) && (flag == 2'b11) && (in_new_bitstream_1 != 16'd255) && (in_new_bitstream_2 != 16'd255)) ? in_standby_bitstream + out_2[(INPUT_DATA_WIDTH-1):OUTPUT_DATA_WIDTH] :
                                ((in_flag_standby) && (!flag_final_bits) && (flag == 2'b01) && (in_new_bitstream_1 == 16'd255)) ? in_standby_bitstream :
                                ((in_flag_standby) && (!flag_final_bits) && (flag == 2'b11) && (in_new_bitstream_1 != 16'd255) && (in_new_bitstream_2 == 16'd255)) ? in_standby_bitstream + out_2[(INPUT_DATA_WIDTH-1):OUTPUT_DATA_WIDTH] :
                                ((in_flag_standby) && (!flag_final_bits) && (flag == 2'b11) && (in_new_bitstream_1 == 16'd255) && (in_new_bitstream_2 != 16'd255)) ? in_standby_bitstream + out_2[(INPUT_DATA_WIDTH-1):OUTPUT_DATA_WIDTH] :
                                ((in_flag_standby) && (!flag_final_bits) && (flag == 2'b11) && (in_new_bitstream_1 == 16'd255) && (in_new_bitstream_2 == 16'd255)) ? in_standby_bitstream + out_2[(INPUT_DATA_WIDTH-1):OUTPUT_DATA_WIDTH] :
                                ((in_flag_standby) && (flag_final_bits) && (flag == 2'b00)) ? in_standby_bitstream :
                                ((in_flag_standby) && (flag_final_bits) && (flag == 2'b01)) ? in_standby_bitstream + out_2[(INPUT_DATA_WIDTH-1):OUTPUT_DATA_WIDTH] :
                                ((in_flag_standby) && (flag_final_bits) && (flag == 2'b11)) ? in_standby_bitstream + out_2[(INPUT_DATA_WIDTH-1):OUTPUT_DATA_WIDTH] :
                                8'd0;

    assign out_bitstream_2 =    ((!in_flag_standby) && (!flag_final_bits) && (flag == 2'b11) && (in_new_bitstream_1 != 16'd255) && (in_new_bitstream_2 != 16'd255)) ? out_3[(OUTPUT_DATA_WIDTH-1):0] :
                                ((!in_flag_standby) && (flag_final_bits) && (flag == 2'b01) && (in_new_bitstream_1 != 16'd255)) ? in_new_bitstream_1[(OUTPUT_DATA_WIDTH-1):0] :
                                ((!in_flag_standby) && (flag_final_bits) && (flag == 2'b11)) ? out_3[(OUTPUT_DATA_WIDTH-1):0] :
                                ((!in_flag_standby) && (!flag_final_bits) && (flag == 2'b11) && (in_new_bitstream_1 == 16'd255) && (in_new_bitstream_2 != 16'd255)) ? out_3[(OUTPUT_DATA_WIDTH-1):0] :
                                ((in_flag_standby) && (!flag_final_bits) && (flag == 2'b01) && (in_new_bitstream_1 != 16'd255)) ? in_previous_bitstream + in_new_bitstream_1[(INPUT_DATA_WIDTH-1):OUTPUT_DATA_WIDTH] :
                                ((in_flag_standby) && (!flag_final_bits) && (flag == 2'b11) && (in_new_bitstream_1 != 16'd255) && (in_new_bitstream_2 != 16'd255)) ? in_previous_bitstream + out_3[(INPUT_DATA_WIDTH-1):OUTPUT_DATA_WIDTH] :
                                ((in_flag_standby) && (!flag_final_bits) && (flag == 2'b11) && (in_new_bitstream_1 != 16'd255) && (in_new_bitstream_2 == 16'd255)) ? in_previous_bitstream + in_new_bitstream_1[(INPUT_DATA_WIDTH-1):OUTPUT_DATA_WIDTH] :
                                ((in_flag_standby) && (!flag_final_bits) && (flag == 2'b11) && (in_new_bitstream_1 == 16'd255) && (in_new_bitstream_2 != 16'd255)) ? in_previous_bitstream + out_3[(INPUT_DATA_WIDTH-1):OUTPUT_DATA_WIDTH] :
                                ((in_flag_standby) && (!flag_final_bits) && (flag == 2'b11) && (in_new_bitstream_1 == 16'd255) && (in_new_bitstream_2 == 16'd255)) ? in_previous_bitstream + out_3[(INPUT_DATA_WIDTH-1):OUTPUT_DATA_WIDTH] :
                                ((in_flag_standby) && (flag_final_bits) && (flag == 2'b00)) ? in_previous_bitstream :
                                ((in_flag_standby) && (flag_final_bits) && (flag == 2'b01)) ? in_previous_bitstream + in_new_bitstream_1[(INPUT_DATA_WIDTH-1):OUTPUT_DATA_WIDTH] :
                                ((in_flag_standby) && (flag_final_bits) && (flag == 2'b11)) ? in_previous_bitstream + out_3[(INPUT_DATA_WIDTH-1):OUTPUT_DATA_WIDTH] :
                                8'd0;

    assign out_bitstream_3 =    ((!in_flag_standby) && (flag_final_bits) && (flag == 2'b11)) ? in_new_bitstream_2[(OUTPUT_DATA_WIDTH-1):0] :
                                ((in_flag_standby) && (!flag_final_bits) && (flag == 2'b11) && (in_new_bitstream_1 != 16'd255) && (in_new_bitstream_2 != 16'd255)) ? out_3[(OUTPUT_DATA_WIDTH-1):0] :
                                ((in_flag_standby) && (!flag_final_bits) && (flag == 2'b11) && (in_new_bitstream_1 == 16'd255) && (in_new_bitstream_2 != 16'd255)) ? out_3[(OUTPUT_DATA_WIDTH-1):0] :
                                ((in_flag_standby) && (!flag_final_bits) && (flag == 2'b11) && (in_new_bitstream_1 == 16'd255) && (in_new_bitstream_2 == 16'd255)) ? out_3[(OUTPUT_DATA_WIDTH-1):0] :
                                ((in_flag_standby) && (flag_final_bits) && (flag == 2'b01)) ? in_new_bitstream_1[(OUTPUT_DATA_WIDTH-1):0] :
                                ((in_flag_standby) && (flag_final_bits) && (flag == 2'b11)) ? out_3[(OUTPUT_DATA_WIDTH-1):0] :
                                8'd0;


    assign bitstream_hold =     (flag_first) ? 8'd0 :
                                ((!in_flag_standby) && (!flag_final_bits) && (flag == 2'b01) && (in_new_bitstream_1 != 16'd255)) ? in_new_bitstream_1[(OUTPUT_DATA_WIDTH-1):0] :
                                ((!in_flag_standby) && (!flag_final_bits) && (flag == 2'b11) && (in_new_bitstream_1 != 16'd255) && (in_new_bitstream_2 != 16'd255)) ? in_new_bitstream_2[(OUTPUT_DATA_WIDTH-1):0] :
                                ((!in_flag_standby) && (flag_final_bits) && (flag == 2'b00)) ? 8'd0 :
                                ((!in_flag_standby) && (flag_final_bits) && (flag == 2'b01) && (in_new_bitstream_1 != 16'd255)) ? 8'd0 :
                                ((!in_flag_standby) && (flag_final_bits) && (flag == 2'b11)) ? 8'd0 :
                                ((!in_flag_standby) && (!flag_final_bits) && (flag == 2'b01) && (in_new_bitstream_1 == 16'd255)) ? in_new_bitstream_1[(OUTPUT_DATA_WIDTH-1):0] :
                                ((!in_flag_standby) && (!flag_final_bits) && (flag == 2'b11) && (in_new_bitstream_1 == 16'd255) && (in_new_bitstream_2 != 16'd255)) ? in_new_bitstream_2[(OUTPUT_DATA_WIDTH-1):0] :
                                ((!in_flag_standby) && (!flag_final_bits) && (flag == 2'b11) && (in_new_bitstream_1 != 16'd255) && (in_new_bitstream_2 == 16'd255)) ? in_new_bitstream_2[(OUTPUT_DATA_WIDTH-1):0] :
                                ((!in_flag_standby) && (!flag_final_bits) && (flag == 2'b11) && (in_new_bitstream_1 == 16'd255) && (in_new_bitstream_2 == 16'd255)) ? in_new_bitstream_2[(OUTPUT_DATA_WIDTH-1):0]:
                                ((in_flag_standby) && (!flag_final_bits) && (flag == 2'b01) && (in_new_bitstream_1 != 16'd255)) ? in_new_bitstream_1[(OUTPUT_DATA_WIDTH-1):0] :
                                ((in_flag_standby) && (!flag_final_bits) && (flag == 2'b11) && (in_new_bitstream_1 != 16'd255) && (in_new_bitstream_2 != 16'd255)) ? in_new_bitstream_2[(OUTPUT_DATA_WIDTH-1):0] :
                                ((in_flag_standby) && (!flag_final_bits) && (flag == 2'b01) && (in_new_bitstream_1 == 16'd255)) ? in_new_bitstream_1[(OUTPUT_DATA_WIDTH-1):0] :
                                ((in_flag_standby) && (!flag_final_bits) && (flag == 2'b11) && (in_new_bitstream_1 != 16'd255) && (in_new_bitstream_2 == 16'd255)) ? in_new_bitstream_2[(OUTPUT_DATA_WIDTH-1):0] :
                                ((in_flag_standby) && (!flag_final_bits) && (flag == 2'b11) && (in_new_bitstream_1 == 16'd255) && (in_new_bitstream_2 != 16'd255)) ? in_new_bitstream_2[(OUTPUT_DATA_WIDTH-1):0] :
                                ((in_flag_standby) && (!flag_final_bits) && (flag == 2'b11) && (in_new_bitstream_1 == 16'd255) && (in_new_bitstream_2 == 16'd255)) ? in_new_bitstream_2[(OUTPUT_DATA_WIDTH-1):0] :
                                ((in_flag_standby) && (flag_final_bits) && (flag == 2'b00)) ? 8'd0 :
                                ((in_flag_standby) && (flag_final_bits) && (flag == 2'b01)) ? 8'd0 :
                                ((in_flag_standby) && (flag_final_bits) && (flag == 2'b11)) ? in_new_bitstream_2[(OUTPUT_DATA_WIDTH-1):0] :
                                in_previous_bitstream;

    assign out_standby_bitstream =  (flag_first) ? 8'd0 :
                                    ((!in_flag_standby) && (!flag_final_bits) && (flag == 2'b01) && (in_new_bitstream_1 != 16'd255)) ? 8'd0 :
                                    ((!in_flag_standby) && (!flag_final_bits) && (flag == 2'b11) && (in_new_bitstream_1 != 16'd255) && (in_new_bitstream_2 != 16'd255)) ? 8'd0 :
                                    ((!in_flag_standby) && (flag_final_bits) && (flag == 2'b00)) ? 8'd0 :
                                    ((!in_flag_standby) && (flag_final_bits) && (flag == 2'b01) && (in_new_bitstream_1 != 16'd255)) ? 8'd0 :
                                    ((!in_flag_standby) && (flag_final_bits) && (flag == 2'b11)) ? 8'd0 :
                                    ((!in_flag_standby) && (!flag_final_bits) && (flag == 2'b01) && (in_new_bitstream_1 == 16'd255)) ? in_previous_bitstream :
                                    ((!in_flag_standby) && (!flag_final_bits) && (flag == 2'b11) && (in_new_bitstream_1 == 16'd255) && (in_new_bitstream_2 != 16'd255)) ? 8'd0 :
                                    ((!in_flag_standby) && (!flag_final_bits) && (flag == 2'b11) && (in_new_bitstream_1 != 16'd255) && (in_new_bitstream_2 == 16'd255)) ? out_3[(OUTPUT_DATA_WIDTH-1):0] :
                                    ((!in_flag_standby) && (!flag_final_bits) && (flag == 2'b11) && (in_new_bitstream_1 == 16'd255) && (in_new_bitstream_2 == 16'd255)) ? in_new_bitstream_1[(OUTPUT_DATA_WIDTH-1):0] :
                                    ((in_flag_standby) && (!flag_final_bits) && (flag == 2'b01) && (in_new_bitstream_1 != 16'd255)) ? 8'd0 :
                                    ((in_flag_standby) && (!flag_final_bits) && (flag == 2'b11) && (in_new_bitstream_1 != 16'd255) && (in_new_bitstream_2 != 16'd255)) ? 8'd0 :
                                    ((in_flag_standby) && (!flag_final_bits) && (flag == 2'b01) && (in_new_bitstream_1 == 16'd255)) ? in_previous_bitstream :
                                    ((in_flag_standby) && (!flag_final_bits) && (flag == 2'b11) && (in_new_bitstream_1 != 16'd255) && (in_new_bitstream_2 == 16'd255)) ? in_new_bitstream_1[(OUTPUT_DATA_WIDTH-1):0] :
                                    ((in_flag_standby) && (!flag_final_bits) && (flag == 2'b11) && (in_new_bitstream_1 == 16'd255) && (in_new_bitstream_2 != 16'd255)) ? 8'd0 :
                                    ((in_flag_standby) && (!flag_final_bits) && (flag == 2'b11) && (in_new_bitstream_1 == 16'd255) && (in_new_bitstream_2 == 16'd255)) ? 8'd0 :
                                    ((in_flag_standby) && (flag_final_bits) && (flag == 2'b00)) ? 8'd0 :
                                    ((in_flag_standby) && (flag_final_bits) && (flag == 2'b01)) ? 8'd0 :
                                    ((in_flag_standby) && (flag_final_bits) && (flag == 2'b11)) ? 8'd0 :
                                    in_standby_bitstream;

    // assign out_flag =   ((flag_final_bits || in_flag_standby) && (flag == 2'b00)) ? 2'b01 :            // 1 output
    //                     ((flag_final_bits || in_flag_standby) && (flag == 2'b01)) ? 2'b11 :            // 2 outputs
    //                     ((flag_final_bits || in_flag_standby) && (flag == 2'b11)) ? 2'b10 :            // 3 outputs!
    //                     ()
    //                     flag;
    //
    // assign out_bitstream_1 = in_previous_bitstream + in_new_bitstream_1[(INPUT_DATA_WIDTH-1):OUTPUT_DATA_WIDTH];
    //
    // assign out_bitstream_2 = (flag == 2'b11) ? in_new_bitstream_1[(OUTPUT_DATA_WIDTH-1):0] +  in_new_bitstream_2[(INPUT_DATA_WIDTH-1):OUTPUT_DATA_WIDTH]:
    //                         8'd0;
    //
    // assign bitstream_hold = ((flag == 2'b11) || (flag_final_bits)) ? in_new_bitstream_2[(OUTPUT_DATA_WIDTH-1):0] :
    //                         (flag == 2'b01) ? in_new_bitstream_1[(OUTPUT_DATA_WIDTH-1):0] :
    //                         in_previous_bitstream;

endmodule
