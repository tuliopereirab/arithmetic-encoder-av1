module stage_4 #(
    parameter OUTPUT_DATA_WIDTH = 8,
    parameter INPUT_DATA_WIDTH = 16,
    ) (
        input [1:0] flag,             // 01: save only bit_1; 11: save both
        input [(INPUT_DATA_WIDTH-1):0] in_new_bitstream_1, in_new_bitstream_2,          // 1- first (sometimes the only) to be generated, 2- only used when 2 bitstreams are being generated
        input [(OUTPUT_DATA_WIDTH-1):0] in_previous_bitstream,
        output wire [(OUTPUT_DATA_WIDTH-1):0] out_bitstream_1, out_bitstream_2, bitstream_hold,
        output wire out_flag
    );
    assign out_flag = flag;

    assign out_bitstream_1 = in_previous_bitstream + in_new_bitstream_1[(INPUT_DATA_WIDTH-1):OUTPUT_DATA_WIDTH];

    assign out_bitstream_2 = (flag == 2'b11) ? in_new_bitstream_1[(OUTPUT_DATA_WIDTH-1):0] +  in_new_bitstream_2[(INPUT_DATA_WIDTH-1):OUTPUT_DATA_WIDTH]:
                            8'd0;

    assign bitstream_hold = (flag == 2'b11) ? in_new_bitstream_2[(OUTPUT_DATA_WIDTH-1):0] :
                            (flag == 2'b10) ? in_new_bitstream_1[(OUTPUT_DATA_WIDTH-1):0] :
                            in_previous_bitstream;

endmodule
