/*
In short, the stage 3 generates a 9-bit bitstream and the normal output for the architecture is 8-bit wide.
Therefore, stage 4 uses the 9th bit as a carry and propagate it into previous bitstreams generated.
For most of the cases, only one bitstream is affected (b[i-1]), where i corresponds to the current bitstream.
However, when the bitstream b[i-1] is 255 in decimal, the carry also affects b[i-2]
This architecture is responsible for:
  1 -> receive up to two 9-bit bitstreams per cycle and propagate the carry;
  2 -> when identifying 255, start counting the number of 255s received in sequence;
  3 -> The architecture generates up to five 8-bit bitstreams as outputs.
The architecture's behavior is describe in:
  https://docs.google.com/spreadsheets/d/1TxM0V8Arepv4CVbWq-B_VGT77I1iNx7inVRwQACSpPo/edit?usp=sharing
*/
module carry_propagation #(
  parameter OUTPUT_DATA_WIDTH = 8,
  parameter INPUT_DATA_WIDTH = 16
  ) (
    input reg_1st_bitstream,
    input [1:0] flag_in,       // 01: save only bit_1; 10: save both
    input flag_final, flag_first,
    input [(OUTPUT_DATA_WIDTH-1):0] in_counter, in_previous,
    /*
    Bitstreams:
      in_bitstream_1- first and sometimes the only,
      in_bitstream_2- only used when 2 bitstreams are being generated
    */
    input [(INPUT_DATA_WIDTH-1):0] in_bitstream_1, in_bitstream_2,
    output wire [(OUTPUT_DATA_WIDTH-1):0] previous, counter,
    output wire [(OUTPUT_DATA_WIDTH-1):0] out_bitstream_1, out_bitstream_2,
    output wire [(OUTPUT_DATA_WIDTH-1):0] out_bitstream_3, out_bitstream_4,
    output wire [(OUTPUT_DATA_WIDTH-1):0] out_bitstream_5,
    output wire [2:0] out_flag,
    output wire out_flag_last, flag_1st_bitstream
  );
  assign out_flag_last = flag_final;

  wire [(OUTPUT_DATA_WIDTH-1):0] previous_c0, previous_c1;
  wire [(OUTPUT_DATA_WIDTH-1):0] counter_c0, counter_c1;
  wire [(OUTPUT_DATA_WIDTH-1):0] out_1_c0, out_1_c1, out_1_c0_final;
  wire [(OUTPUT_DATA_WIDTH-1):0] out_1_c0_not_final, out_1_c1_not_final;
  wire [(OUTPUT_DATA_WIDTH-1):0] out_1_c1_final;
  wire [(OUTPUT_DATA_WIDTH-1):0] out_2_c0, out_2_c1, out_2_c0_final;
  wire [(OUTPUT_DATA_WIDTH-1):0] out_2_c0_not_final, out_2_c1_not_final;
  wire [(OUTPUT_DATA_WIDTH-1):0] out_2_c1_final;
  wire [(OUTPUT_DATA_WIDTH-1):0] out_3_c0, out_3_c1, out_3_c0_final;
  wire [(OUTPUT_DATA_WIDTH-1):0] out_3_c0_not_final, out_3_c1_not_final;
  wire [(OUTPUT_DATA_WIDTH-1):0] out_3_c1_final;
  wire [(OUTPUT_DATA_WIDTH-1):0] out_4_c1, out_5_c1;
  wire [2:0] flag_c0, flag_c1, flag_c0_final, flag_c0_not_final, flag_c1_final;
  wire [2:0] flag_c1_not_final;

  // The explanation for this variable in locate where the variable is declared
  assign flag_1st_bitstream = ((reg_1st_bitstream) && (flag_in == 0)) ? 1'b1 :
                              1'b0;

  assign previous = (flag_first) ? 8'd0 :
                    ((reg_1st_bitstream) && (flag_in == 0)) ? 8'd0 :
                    ((reg_1st_bitstream) && (flag_in == 1)) ? in_bitstream_1[(OUTPUT_DATA_WIDTH-1):0] :
                    ((reg_1st_bitstream) && (flag_in == 2)) ? in_bitstream_2[(OUTPUT_DATA_WIDTH-1):0] :
                    (in_counter == 8'd0) ? previous_c0 :
                    previous_c1;

  assign counter =  (flag_first) ? 8'd0 :
                    (reg_1st_bitstream) ? 8'd0 :
                    (in_counter == 8'd0) ? counter_c0 :
                    counter_c1;

  assign out_bitstream_1 =  ((reg_1st_bitstream) && (flag_in != 2)) ? 8'd0 :
                            ((reg_1st_bitstream) && (flag_in == 2)) ? in_bitstream_1[(OUTPUT_DATA_WIDTH-1):0] + in_bitstream_2[(INPUT_DATA_WIDTH-1):OUTPUT_DATA_WIDTH] :
                            (in_counter == 8'd0) ? out_1_c0 :
                            out_1_c1;
  assign out_bitstream_2 =  (in_counter == 8'd0) ? out_2_c0 :
                            out_2_c1;
  assign out_bitstream_3 =  (in_counter == 8'd0) ? out_3_c0 :
                            out_3_c1;

  assign out_flag = ((reg_1st_bitstream) && (flag_in != 2)) ? 3'd0 :
                    ((reg_1st_bitstream) && (flag_in == 2)) ? 3'd1 :
                    (in_counter == 8'd0) ? flag_c0 :
                    flag_c1;

  // -------------------------------------
  assign out_bitstream_4 =  ((in_counter != 0) && (!flag_final) && (flag_in == 2) && (in_bitstream_1 != 255) && (in_bitstream_2 != 255)) ? in_bitstream_1[(OUTPUT_DATA_WIDTH-1):0] + in_bitstream_2[(INPUT_DATA_WIDTH-1):OUTPUT_DATA_WIDTH] :
                            ((in_counter != 0) && (flag_final) && (flag_in == 1) && (in_bitstream_1 != 255)) ? in_bitstream_1[(OUTPUT_DATA_WIDTH-1):0] :
                            ((in_counter != 0) && (flag_final) && (flag_in == 2) && (in_bitstream_1 != 255) && ((in_bitstream_2 != 255) || (in_bitstream_2 == 255))) ? in_bitstream_1[(OUTPUT_DATA_WIDTH-1):0] + in_bitstream_2[(INPUT_DATA_WIDTH-1):OUTPUT_DATA_WIDTH] :
                            ((in_counter != 0) && (flag_final) && (flag_in == 2) && (in_bitstream_1 == 255) && (in_bitstream_2 != 255)) ? in_bitstream_2[(OUTPUT_DATA_WIDTH-1):0] :
                            8'd0;

  assign out_bitstream_5 =  ((flag_final) && (flag_in == 2) && (in_bitstream_1 != 255) && ((in_bitstream_2 == 255) || (in_bitstream_2 != 255))) ? in_bitstream_2[(OUTPUT_DATA_WIDTH-1):0] :
                            8'd0;
  // -------------------------------------
  assign previous_c0 =  (flag_final) ? 8'd0 :
                        (flag_in == 0) ? in_previous :
                        ((flag_in == 1) && (in_bitstream_1 != 255)) ? in_bitstream_1[(OUTPUT_DATA_WIDTH-1):0] :
                        ((flag_in == 2) && (in_bitstream_1 != 255) && (in_bitstream_2 != 255)) ? in_bitstream_2[(OUTPUT_DATA_WIDTH-1):0] :
                        ((flag_in == 1) && (in_bitstream_1 == 255)) ? in_previous :
                        ((flag_in == 2) && (in_bitstream_1 == 255) && (in_bitstream_2 == 255)) ? in_previous :
                        ((flag_in == 2) && (in_bitstream_1 != 255) && (in_bitstream_2 == 255)) ? in_bitstream_1[(OUTPUT_DATA_WIDTH-1):0] :
                        ((flag_in == 2) && (in_bitstream_1 == 255) && (in_bitstream_2 != 255)) ? in_bitstream_2[(OUTPUT_DATA_WIDTH-1):0] :
                        8'd0;

  assign previous_c1 =  (flag_final) ? 8'd0 :
                        (flag_in == 0) ? in_previous :
                        ((flag_in == 1) && (in_bitstream_1 == 255)) ? in_previous :
                        ((flag_in == 2) && (in_bitstream_1 == 255) && (in_bitstream_2 == 255)) ? in_previous :
                        ((flag_in == 1) && (in_bitstream_1 != 255)) ? in_bitstream_1[(OUTPUT_DATA_WIDTH-1):0] :
                        ((flag_in == 2) && (in_bitstream_1 != 255) && (in_bitstream_2 != 255)) ? in_bitstream_2[(OUTPUT_DATA_WIDTH-1):0] :
                        ((flag_in == 2) && (in_bitstream_1 == 255) && (in_bitstream_2 != 255)) ? in_bitstream_2[(OUTPUT_DATA_WIDTH-1):0] :
                        ((flag_in == 2) && (in_bitstream_1 != 255) && (in_bitstream_2 == 255)) ? in_bitstream_1[(OUTPUT_DATA_WIDTH-1):0] :
                        8'd0;
  // -------------------------------------
  assign counter_c0 = ((!flag_final) && (flag_in == 0)) ? in_counter :
                      ((!flag_final) && (flag_in == 1) && (in_bitstream_1 == 255)) ? 8'd1 :
                      ((!flag_final) && (flag_in == 2) && (in_bitstream_1 == 255) && (in_bitstream_2 == 255)) ? 8'd2 :
                      ((!flag_final) && (flag_in == 2) && (in_bitstream_1 != 255) && (in_bitstream_2 == 255)) ? 8'd1 :
                      8'd0;

  assign counter_c1 = ((!flag_final) && (flag_in == 0)) ? in_counter :
                      ((!flag_final) && (flag_in == 1) && (in_bitstream_1 == 255)) ? in_counter + 8'd1 :
                      ((!flag_final) && (flag_in == 2) && (in_bitstream_1 == 255) && (in_bitstream_2 == 255)) ? in_counter + 8'd2 :
                      ((!flag_final) && (flag_in == 2) && (in_bitstream_1 != 255) && (in_bitstream_2 == 255)) ? 8'd1 :
                      8'd0;
  // -------------------------------------
  assign out_1_c0 = (flag_final) ? out_1_c0_final :
                    out_1_c0_not_final;
  assign out_1_c1 = (flag_final) ? out_1_c1_final :
                    out_1_c1_not_final;

  assign out_2_c0 = (flag_final) ? out_2_c0_final :
                    out_2_c0_not_final;
  assign out_2_c1 = (flag_final) ? out_2_c1_final :
                    out_2_c1_not_final;

  assign out_3_c0 = ((flag_final) && (flag_in == 2)) ? in_bitstream_2[(OUTPUT_DATA_WIDTH-1):0] :
                    8'd0;
  assign out_3_c1 = (flag_final) ? out_3_c1_final :
                    out_3_c1_not_final;
  assign flag_c0 =  (flag_final) ? flag_c0_final :
                    flag_c0_not_final;
  assign flag_c1 =  (flag_final) ? flag_c1_final :
                    flag_c1_not_final;
  // -------------------------------------

  assign out_1_c0_not_final = ((flag_in == 1) && (in_bitstream_1 != 255)) ? in_previous + in_bitstream_1[(INPUT_DATA_WIDTH-1):OUTPUT_DATA_WIDTH] :
                              ((flag_in == 2) && (in_bitstream_1 != 255) && (in_bitstream_2 != 255)) ? in_previous + in_bitstream_1[(INPUT_DATA_WIDTH-1):OUTPUT_DATA_WIDTH] :
                              ((flag_in == 2) && (in_bitstream_1 != 255) && (in_bitstream_2 == 255)) ? in_previous + in_bitstream_1[(INPUT_DATA_WIDTH-1):OUTPUT_DATA_WIDTH] :
                              ((flag_in == 2) && (in_bitstream_1 == 255) && (in_bitstream_2 != 255)) ? in_previous + in_bitstream_2[(INPUT_DATA_WIDTH-1):OUTPUT_DATA_WIDTH] :
                              8'd0;
  assign out_1_c0_final = (flag_in == 0) ? in_previous :
                          (flag_in == 1) ? in_previous + in_bitstream_1[(INPUT_DATA_WIDTH-1):OUTPUT_DATA_WIDTH] :
                          ((flag_in == 2) && (in_bitstream_1 != 255)) ? in_previous + in_bitstream_1[(INPUT_DATA_WIDTH-1):OUTPUT_DATA_WIDTH] :
                          ((flag_in == 2) && (in_bitstream_1 == 255)) ? in_previous + in_bitstream_2[(INPUT_DATA_WIDTH-1):OUTPUT_DATA_WIDTH] :
                          8'd0;

  assign out_1_c1_not_final = ((flag_in == 1) && (in_bitstream_1 != 255)) ? in_previous + in_bitstream_1[(INPUT_DATA_WIDTH-1):OUTPUT_DATA_WIDTH] :
                              ((flag_in == 2) && (in_bitstream_1 != 255) && (in_bitstream_2 != 255)) ? in_previous + in_bitstream_1[(INPUT_DATA_WIDTH-1):OUTPUT_DATA_WIDTH] :
                              ((flag_in == 2) && (in_bitstream_1 == 255) && (in_bitstream_2 != 255)) ? in_previous + in_bitstream_2[(INPUT_DATA_WIDTH-1):OUTPUT_DATA_WIDTH] :
                              ((flag_in == 2) && (in_bitstream_1 != 255) && (in_bitstream_2 == 255)) ? in_previous + in_bitstream_1[(INPUT_DATA_WIDTH-1):OUTPUT_DATA_WIDTH] :
                              8'd0;
  assign out_1_c1_final = (flag_in == 0) ? in_previous :
                          ((flag_in == 1) && (in_bitstream_1 == 255)) ? in_previous :
                          ((flag_in == 2) && (in_bitstream_1 == 255) && (in_bitstream_2 == 255)) ? in_previous :
                          ((flag_in == 1) && (in_bitstream_1 != 255)) ? in_previous + in_bitstream_1[(INPUT_DATA_WIDTH-1):OUTPUT_DATA_WIDTH] :
                          ((flag_in == 2) && (in_bitstream_1 != 255) && ((in_bitstream_2 != 255) || (in_bitstream_2 == 255))) ? in_previous + in_bitstream_1[(INPUT_DATA_WIDTH-1):OUTPUT_DATA_WIDTH] :
                          ((flag_in == 2) && (in_bitstream_1 == 255) && (in_bitstream_2 != 255)) ? in_previous + in_bitstream_2[(INPUT_DATA_WIDTH-1):OUTPUT_DATA_WIDTH] :
                          8'd0;
  // -------------------------------------
  assign out_2_c0_not_final = ((flag_in == 2) && (in_bitstream_1 != 255) && (in_bitstream_2 != 255)) ? in_bitstream_1[(OUTPUT_DATA_WIDTH-1):0] + in_bitstream_2[(INPUT_DATA_WIDTH-1):OUTPUT_DATA_WIDTH] :
                              ((flag_in == 2) && (in_bitstream_1 == 255) && (in_bitstream_2 != 255)) ? in_bitstream_1[(OUTPUT_DATA_WIDTH-1):0] + in_bitstream_2[(INPUT_DATA_WIDTH-1):OUTPUT_DATA_WIDTH] :
                              8'd0;
  assign out_2_c0_final = (flag_in == 1) ? in_bitstream_1[(OUTPUT_DATA_WIDTH-1):0] :
                          ((flag_in == 2) && (in_bitstream_1 != 255)) ? in_bitstream_1[(OUTPUT_DATA_WIDTH-1):0] + in_bitstream_2[(INPUT_DATA_WIDTH-1):OUTPUT_DATA_WIDTH] :
                          ((flag_in == 2) && (in_bitstream_1 == 255)) ? in_bitstream_1[(OUTPUT_DATA_WIDTH-1):0] + in_bitstream_2[(INPUT_DATA_WIDTH-1):OUTPUT_DATA_WIDTH] :
                          8'd0;

  assign out_2_c1_not_final = ((flag_in == 1) && (in_bitstream_1 != 255)) ? 8'd255 + in_bitstream_1[(INPUT_DATA_WIDTH-1):OUTPUT_DATA_WIDTH] :
                              ((flag_in == 2) && (in_bitstream_1 != 255) && (in_bitstream_2 != 255)) ? 8'd255 + in_bitstream_1[(INPUT_DATA_WIDTH-1):OUTPUT_DATA_WIDTH] :
                              ((flag_in == 2) && (in_bitstream_1 == 255) && (in_bitstream_2 != 255)) ? 8'd255 + in_bitstream_2[(INPUT_DATA_WIDTH-1):OUTPUT_DATA_WIDTH] :
                              ((flag_in == 2) && (in_bitstream_1 != 255) && (in_bitstream_2 == 255)) ? 8'd255 + in_bitstream_1[(INPUT_DATA_WIDTH-1):OUTPUT_DATA_WIDTH] :
                              8'd0;
  assign out_2_c1_final = (flag_in == 0) ? 8'd255 :
                          ((flag_in == 1) && (in_bitstream_1 == 255)) ? 8'd255 :
                          ((flag_in == 2) && (in_bitstream_1 == 255) && (in_bitstream_2 == 255)) ? 8'd255 :
                          ((flag_in == 1) && (in_bitstream_1 != 255)) ? 8'd255 + in_bitstream_1[(INPUT_DATA_WIDTH-1):OUTPUT_DATA_WIDTH] :
                          ((flag_in == 2) && (in_bitstream_1 != 255) && ((in_bitstream_2 == 255) || (in_bitstream_2 != 255))) ? 8'd255 + in_bitstream_1[(INPUT_DATA_WIDTH-1):OUTPUT_DATA_WIDTH] :
                          ((flag_in == 2) && (in_bitstream_1 == 255) && (in_bitstream_2 != 255)) ? 8'd255 + in_bitstream_2[(INPUT_DATA_WIDTH-1):OUTPUT_DATA_WIDTH] :
                          8'd0;

  // -------------------------------------

  assign out_3_c1_not_final = ((flag_in == 1) && (in_bitstream_1 != 255)) ? in_counter :
                              ((flag_in == 2) && (in_bitstream_1 != 255) && (in_bitstream_2 != 255)) ? in_counter :
                              ((flag_in == 2) && (in_bitstream_1 == 255) && (in_bitstream_2 != 255)) ? in_counter + 8'd1 :
                              ((flag_in == 2) && (in_bitstream_1 != 255) && (in_bitstream_2 == 255)) ? in_counter :
                              8'd0;
  assign out_3_c1_final = (flag_in == 0) ? in_counter :
                          ((flag_in == 1) && (in_bitstream_1 == 255)) ? in_counter + 8'd1 :
                          ((flag_in == 2) && (in_bitstream_1 == 255) && (in_bitstream_2 == 255)) ? in_counter + 8'd2 :
                          ((flag_in == 1) && (in_bitstream_1 != 255)) ? in_counter :
                          ((flag_in == 2) && (in_bitstream_1 != 255) && ((in_bitstream_2 == 255) || (in_bitstream_2 != 255))) ? in_counter :
                          ((flag_in == 2) && (in_bitstream_1 == 255) && (in_bitstream_2 != 255)) ? in_counter + 8'd1 :
                          8'd0;

  // -------------------------------------

  assign flag_c0_not_final =  ((flag_in == 1) && (in_bitstream_1 != 255)) ? 3'b001 :
                              ((flag_in == 2) && (in_bitstream_1 != 255) && (in_bitstream_2 != 255)) ? 3'b010 :
                              ((flag_in == 2) && (in_bitstream_1 != 255) && (in_bitstream_2 == 255)) ? 3'b001 :
                              ((flag_in == 2) && (in_bitstream_1 == 255) && (in_bitstream_2 != 255)) ? 3'b010 :
                              3'b000;
  assign flag_c0_final =  (flag_in == 0) ? 3'b001 :
                          (flag_in == 1) ? 3'b010 :
                          (flag_in == 2) ? 3'b011 :
                          3'b000;


  assign flag_c1_not_final =  ((flag_in == 1) && (in_bitstream_1 != 255)) ? 3'b101 :
                              ((flag_in == 2) && (in_bitstream_1 != 255) && (in_bitstream_2 != 255)) ? 3'b110 :
                              ((flag_in == 2) && (in_bitstream_1 == 255) && (in_bitstream_2 != 255)) ? 3'b101 :
                              ((flag_in == 2) && (in_bitstream_1 != 255) && (in_bitstream_2 == 255)) ? 3'b101 :
                              3'b000;

  assign flag_c1_final =  (flag_in == 0) ? 3'b101 :
                          ((flag_in == 1) && (in_bitstream_1 == 255)) ? 3'b101 :
                          ((flag_in == 2) && (in_bitstream_1 == 255) && (in_bitstream_2 == 255)) ? 3'b101 :
                          ((flag_in == 1) && (in_bitstream_1 != 255)) ? 3'b110 :
                          ((flag_in == 2) && (in_bitstream_1 != 255) && ((in_bitstream_2 != 255) || (in_bitstream_2 == 255))) ? 3'b111 :
                          ((flag_in == 2) && (in_bitstream_1 == 255) && (in_bitstream_2 != 255)) ? 3'b110 :
                          3'b000;
endmodule
