/*
This module is a 32-bit adaptation of:
  @ARTICLE{4539802,
    author={G. {Dimitrakopoulos} and K. {Galanopoulos} and C. {Mavrokefalidis}
  and D. {Nikolos}},
    journal={IEEE Transactions on Very Large Scale Integration (VLSI) Systems},
    title={Low-Power Leading-Zero Counting and Anticipation Logic for
  High-Speed Floating Point Units},
    year={2008},
    volume={16},
    number={7},
    pages={837-850},
    doi={10.1109/TVLSI.2008.2000458}
  }
*/


module leading_zero #(
  parameter RANGE_WIDTH_LCZ = 16,
  parameter D_SIZE_LZC = 4
  )(
    input [(RANGE_WIDTH_LCZ)-1:0] in_range,
    output wire v,
    output wire [(D_SIZE_LZC-1):0] lzc_out
  );

  wire g1_1, g2_1, g3_1, g4_1;
  wire g1_2, g2_2, g3_2, g4_2;
  wire g1_3, g2_3, g3_3, g4_3;
  wire g3_4, g4_4;

  wire q1_1, q2_1, q3_1, q4_1, q5_1, q6_1;
  wire q1_2, q2_2, q3_2;


  // G
  assign g4_1 = (in_range[15] | in_range[14]) | (in_range[13] | in_range[12]);
  assign g3_1 = in_range[15] | ((!in_range[14]) & in_range[13]);
  assign g2_1 = (!in_range[14]) & (!in_range[12]);
  assign g1_1 = !(in_range[13] | in_range[12]);

  assign g4_2 = (in_range[11] | in_range[10]) | (in_range[9] | in_range[8]);
  assign g3_2 = in_range[11] | ((!in_range[10]) & in_range[9]);
  assign g2_2 = (!in_range[10]) & (!in_range[8]);
  assign g1_2 = !(in_range[9] | in_range[8]);

  assign g4_3 = (in_range[7] | in_range[6]) | (in_range[5] | in_range[4]);
  assign g3_3 = in_range[7] | ((!in_range[6]) & in_range[5]);
  assign g2_3 = (!in_range[6]) & (!in_range[4]);
  assign g1_3 = !(in_range[5] | in_range[4]);

  assign g4_4 = (in_range[3] | in_range[2]) | (in_range[1] | in_range[0]);
  assign g3_4 = in_range[3] | ((!in_range[2]) & in_range[1]);

  // ------------------------------
  // Q
  assign q1_1 = g4_1 | g4_2;
  assign q2_1 = g3_1 | (g2_1 & g3_2);
  assign q3_1 = g2_1 & g2_2;
  assign q4_1 = (in_range[15] | in_range[14]) | (g1_1 & (in_range[11] |
                                                                in_range[10]));
  assign q5_1 = g1_1 & g1_2;
  assign q6_1 = !g4_2;

  assign q1_2 = g4_3 | g4_4;
  assign q2_2 = g3_3 | (g2_3 & g3_4);
  assign q3_2 = (in_range[7] | in_range[6]) | (g1_3 & (in_range[3] |
                                                                in_range[2]));

  // ------------------------------
  // final
  assign v = q1_1 | q1_2;
  assign lzc_out[0] = !(q2_1 | (q3_1 & q2_2));
  assign lzc_out[1] = !(q4_1 | (q5_1 & q3_2));
  assign lzc_out[2] = !(g4_1 | (q6_1 & g4_3));
  assign lzc_out[3] = !q1_1;
  assign lzc_out[4] = 1'b0;

endmodule
