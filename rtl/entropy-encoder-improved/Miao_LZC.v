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
  assign out_z[0] = (!in[7] & (in[6] | (!in[5] & (in[4] |
                    (!in[3] & (in[2] | !in[1]))))));
  assign out_z[1] = (!in[6] & (!in[7] & (in[5] | (!in[2] & !in[3]) | in[4])));
  assign out_z[2] = (!in[4] & !in[5] & !in[6] & !in[7]);
  assign v = (!in[0] & !in[1] & !in[2] & !in[3] & !in[4] &
              !in[5] & !in[6] & !in[7]);

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
