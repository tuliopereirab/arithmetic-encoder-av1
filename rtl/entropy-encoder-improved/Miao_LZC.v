/*
@INPROCEEDINGS{8355536,
  author={Miao, Jia and Li, Shuguo},
  booktitle={2017 IEEE International Symposium on Consumer Electronics (ISCE)},
  title={A design for high speed leading-zero counter},
  year={2017},
  volume={},
  number={},
  pages={22-23},
  doi={10.1109/ISCE.2017.8355536}
} */

module lzc_miao_8 (
  input [7:0] in,
  output wire [2:0] out_z,
  output wire v
  );
  wire q1, q2, q3, q4, q5, q6, q7;
  wire g1, g2, g3, g4;

  assign q1 = !(in[7] | in[6]);
  assign q2 = !(in[7] | (!in[6] & in[5]));
  assign q3 = !(in[5] | in[4]);
  assign q4 = in[4] | in[6];
  assign q5 = !(in[3] | in[2]);
  assign q6 = !(in[3] | (!in[2] & in[1]));
  assign q7 = !(in[1] | in[0]);

  assign g1 = q1 & q3;
  assign g2 = q1 & (!q3 | q5);
  assign g3 = q2 & (q4 | q5);
  assign g4 = q5 & q7;

  assign out_z[0] = g3;
  assign out_z[1] = g2;
  assign out_z[2] = g1;
  assign v = !(g1 | g4);
endmodule

module lzc_miao_16 (
  input [15:0] in,
  output wire [3:0] out_z,
  output wire v
  );
  wire [2:0] zh, zl;
  wire vh, vl, temp_v;
  lzc_miao_8 lzc_8_h (.in (in[15:8]), .out_z (zh), .v (vh));
  lzc_miao_8 lzc_8_l (.in (in[7:0]), .out_z (zl), .v (vl));

  assign out_z[0] = (zh[0] & (!vh | zl[0]));
  assign out_z[1] = (zh[1] & (!vh | zl[1]));
  assign out_z[2] = (zh[2] & (!vh | zl[2]));
  assign out_z[3] = vh;
  assign v = vh & vl;
endmodule
