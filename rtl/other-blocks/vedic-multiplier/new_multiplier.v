// 16-bit multiplier based on:

// @INPROCEEDINGS{6922296,
//   author={R. {Gupta} and R. {Dhar} and K. L. {Baishnab} and J. {Mehedi}},
//   booktitle={2014 International Conference on Green Computing Communication and Electrical Engineering (ICGCCEE)},
//   title={Design of high performance 16 bit multiplier using vedic multiplication algorithm with McCMOS technique},
//   year={2014},
//   volume={},
//   number={},
//   pages={1-6},
//   doi={10.1109/ICGCCEE.2014.6922296}}

// This architecture does not work
// Still trying to find a way to put it to work, but not successfully so far


// This architecture actually reduces the delay and improves the frequency, but it is not working so far.

module new_multiplier #(
    parameter DATA_WIDTH = 16
    ) (
        input [(DATA_WIDTH-1):0] op1, op2,
        output [(DATA_WIDTH*2-1):0] r
    );

    wire [1:0] s0, s1, s2;
    wire [2:0] s3, s4, s5, s6;
    wire [3:0] s7, s8, s9, s10, s11, s12, s13, s14;
    wire [4:0] s15;
    wire [3:0] s16, s17, s18, s19, s20, s21, s22, s23;
    wire [2:0] s24, s25, s26, s27;
    wire [1:0] s28, s29;
    wire s30;
    wire [72:0] c;

    // Generation of sums of partial products and carrys
    assign s0 = (op1[0] & op2[0]);
    assign c[0] = s0[1];

    assign s1 = (op1[0] & op2[1]) + (op1[1] & op2[0]);
    assign c[1] = s1[1];

    assign s2 = (op1[0] & op2[2]) + (op1[1] & op2[1]) + (op1[2] & op2[0]);
    assign c[2] = s2[1];

    assign s3 = (op1[0] & op2[3]) + (op1[1] & op2[2]) + (op1[2] & op2[1]) + (op1[3] & op2[0]);
    assign c[3] = s3[1];
    assign c[4] = s3[2];

    assign s4 = (op1[0] & op2[4]) + (op1[1] & op2[3]) + (op1[2] & op2[2]) + (op1[3] & op2[1]) + (op1[4] & op2[0]);
    assign c[5] = s4[1];
    assign c[6] = s4[2];

    assign s5 = (op1[0] & op2[5]) + (op1[1] & op2[4]) + (op1[2] & op2[3]) + (op1[3] & op2[2]) + (op1[4] & op2[1]) +
                (op1[5] & op2[0]);
    assign c[7] = s5[1];
    assign c[8] = s5[2];
    assign s6 = (op1[0] & op2[6]) + (op1[1] & op2[5]) + (op1[2] & op2[4]) + (op1[3] & op2[3]) + (op1[4] & op2[2]) +
                (op1[5] & op2[1]) + (op1[6] & op2[0]);
    assign c[9] = s6[1];
    assign c[10] = s6[2];
    //-----------------------------------
    assign s7 = (op1[0] & op2[7]) + (op1[1] & op2[6]) + (op1[2] & op2[5]) + (op1[3] & op2[4]) + (op1[4] & op2[3]) +
                (op1[5] & op2[2]) + (op1[6] & op2[1]) + (op1[7] & op2[0]);
    assign c[11] = s7[1];
    assign c[12] = s7[2];
    assign c[13] = s7[3];
    assign s8 = (op1[0] & op2[8]) + (op1[1] & op2[7]) + (op1[2] & op2[6]) + (op1[3] & op2[5]) + (op1[4] & op2[4]) +
                (op1[5] & op2[3]) + (op1[6] & op2[2]) + (op1[7] & op2[1]) + (op1[8] & op2[0]);
    assign c[14] = s8[1];
    assign c[15] = s8[2];
    assign c[16] = s8[3];
    assign s9 = (op1[0] & op2[9]) + (op1[1] & op2[8]) + (op1[2] & op2[7]) + (op1[3] & op2[6]) + (op1[4] & op2[5]) +
                (op1[5] & op2[4]) + (op1[6] & op2[3]) + (op1[7] & op2[2]) + (op1[8] & op2[1]) + (op1[9] & op2[0]);
    assign c[17] = s9[1];
    assign c[18] = s9[2];
    assign c[19] = s9[3];
    assign s10 =    (op1[0] & op2[10]) + (op1[1] & op2[9]) + (op1[2] & op2[8]) + (op1[3] & op2[7]) + (op1[4] & op2[6]) +
                    (op1[5] & op2[5]) + (op1[6] & op2[4]) + (op1[7] & op2[3]) + (op1[8] & op2[2]) + (op1[9] & op2[1]) +
                    (op1[10] & op2[0]);
    assign c[20] = s10[1];
    assign c[21] = s10[2];
    assign c[22] = s10[3];
    assign s11 =    (op1[0] & op2[11]) + (op1[1] & op2[10]) + (op1[2] & op2[9]) + (op1[3] & op2[8]) + (op1[4] & op2[7]) +
                    (op1[5] & op2[6]) + (op1[6] & op2[5]) + (op1[7] & op2[4]) + (op1[8] & op2[3]) + (op1[9] & op2[2]) +
                    (op1[10] & op2[1]) + (op1[11] & op2[0]);
    assign c[23] = s11[1];
    assign c[24] = s11[2];
    assign c[25] = s11[3];
    assign s12 =    (op1[0] & op2[12]) + (op1[1] & op2[11]) + (op1[2] & op2[10]) + (op1[3] & op2[9]) + (op1[4] & op2[8]) +
                    (op1[5] & op2[7]) + (op1[6] & op2[6]) + (op1[7] & op2[5]) + (op1[8] & op2[4]) + (op1[9] & op2[3]) +
                    (op1[10] & op2[2]) + (op1[11] & op2[1]) + (op1[12] & op2[0]);
    assign c[26] = s12[1];
    assign c[27] = s12[2];
    assign c[28] = s12[3];
    assign s13 =    (op1[0] & op2[13]) + (op1[1] & op2[12]) + (op1[2] & op2[11]) + (op1[3] & op2[10]) + (op1[4] & op2[9]) +
                    (op1[5] & op2[8]) + (op1[6] & op2[7]) + (op1[7] & op2[6]) + (op1[8] & op2[5]) + (op1[9] & op2[4]) +
                    (op1[10] & op2[3]) + (op1[11] & op2[2]) + (op1[12] & op2[1]) + (op1[13] & op2[0]);
    assign c[29] = s13[1];
    assign c[30] = s13[2];
    assign c[31] = s13[3];
    assign s14 =    (op1[0] & op2[14]) + (op1[1] & op2[13]) + (op1[2] & op2[12]) + (op1[3] & op2[11]) + (op1[4] & op2[10]) +
                    (op1[5] & op2[5]) + (op1[6] & op2[6]) + (op1[7] & op2[7]) + (op1[8] & op2[8]) + (op1[9] & op2[9]) +
                    (op1[10] & op2[4]) + (op1[11] & op2[3]) + (op1[12] & op2[2]) + (op1[13] & op2[1]) + (op1[14] & op2[0]);
    assign c[32] = s14[1];
    assign c[33] = s14[2];
    assign c[34] = s14[3];
    //-----------------------------------
    assign s15 =    (op1[0] & op2[15]) + (op1[1] & op2[14]) + (op1[2] & op2[13]) + (op1[3] & op2[12]) + (op1[4] & op2[11]) +
                    (op1[5] & op2[10]) + (op1[6] & op2[9]) + (op1[7] & op2[8]) + (op1[8] & op2[7]) + (op1[9] & op2[6]) +
                    (op1[10] & op2[5]) + (op1[11] & op2[4]) + (op1[12] & op2[3]) + (op1[13] & op2[2]) + (op1[14] & op2[1]) +
                    (op1[15] & op2[0]);
    assign c[35] = s15[1];
    assign c[36] = s15[2];
    assign c[37] = s15[3];
    assign c[38] = s15[4];
    //-----------------------------------
    assign s16 =    (op1[1] & op2[15]) + (op1[2] & op2[14]) + (op1[3] & op2[13]) + (op1[4] & op2[12]) + (op1[5] & op2[11]) +
                    (op1[6] & op2[10]) + (op1[7] & op2[9]) + (op1[8] & op2[8]) + (op1[9] & op2[7]) + (op1[10] & op2[6]) +
                    (op1[11] & op2[5]) + (op1[12] & op2[4]) + (op1[13] & op2[3]) + (op1[14] & op2[2]) + (op1[15] & op2[1]);
    assign c[39] = s16[1];
    assign c[40] = s16[2];
    assign c[41] = s16[3];
    assign s17 =    (op1[2] & op2[15]) + (op1[3] & op2[14]) + (op1[4] & op2[13]) + (op1[5] & op2[12]) + (op1[6] & op2[11]) +
                    (op1[7] & op2[10]) + (op1[8] & op2[9]) + (op1[9] & op2[8]) + (op1[10] & op2[7]) + (op1[11] & op2[6]) +
                    (op1[12] & op2[5]) + (op1[13] & op2[4]) + (op1[14] & op2[3]) + (op1[15] & op2[2]);
    assign c[42] = s17[1];
    assign c[43] = s17[2];
    assign c[44] = s17[3];
    assign s18 =    (op1[3] & op2[15]) + (op1[4] & op2[14]) + (op1[5] & op2[13]) + (op1[6] & op2[12]) + (op1[7] & op2[11]) +
                    (op1[8] & op2[10]) + (op1[9] & op2[9]) + (op1[10] & op2[8]) + (op1[11] & op2[7]) + (op1[12] & op2[6]) +
                    (op1[13] & op2[5]) + (op1[14] & op2[4]) + (op1[15] & op2[3]);
    assign c[45] = s18[1];
    assign c[46] = s18[2];
    assign c[47] = s18[3];
    assign s19 =    (op1[4] & op2[15]) + (op1[5] & op2[14]) + (op1[6] & op2[13]) + (op1[7] & op2[12]) + (op1[8] & op2[11]) +
                    (op1[9] & op2[10]) + (op1[10] & op2[9]) + (op1[11] & op2[8]) + (op1[12] & op2[7]) + (op1[13] & op2[6]) +
                    (op1[14] & op2[5]) + (op1[15] & op2[4]);
    assign c[48] = s19[1];
    assign c[49] = s19[2];
    assign c[50] = s19[3];
    assign s20 =    (op1[5] & op2[15]) + (op1[6] & op2[14]) + (op1[7] & op2[13]) + (op1[8] & op2[12]) + (op1[9] & op2[11]) +
                    (op1[10] & op2[10]) + (op1[11] & op2[9]) + (op1[12] & op2[8]) + (op1[13] & op2[7]) + (op1[14] & op2[6]) +
                    (op1[15] & op2[5]);
    assign c[51] = s20[1];
    assign c[52] = s20[2];
    assign c[53] = s20[3];
    assign s21 =    (op1[6] & op2[15]) + (op1[7] & op2[14]) + (op1[8] & op2[13]) + (op1[9] & op2[12]) + (op1[10] & op2[11]) +
                    (op1[11] & op2[10]) + (op1[12] & op2[9]) + (op1[13] & op2[8]) + (op1[14] & op2[7]) + (op1[15] & op2[6]);
    assign c[54] = s21[1];
    assign c[55] = s21[2];
    assign c[56] = s21[3];
    assign s22 =    (op1[7] & op2[15]) + (op1[8] & op2[14]) + (op1[9] & op2[13]) + (op1[10] & op2[12]) + (op1[11] & op2[11]) +
                    (op1[12] & op2[10]) + (op1[13] & op2[9]) + (op1[14] & op2[8]) + (op1[15] & op2[7]);
    assign c[57] = s22[1];
    assign c[58] = s22[2];
    assign c[59] = s22[3];
    assign s23 =    (op1[8] & op2[15]) + (op1[9] & op2[14]) + (op1[10] & op2[13]) + (op1[11] & op2[12]) + (op1[12] & op2[11]) +
                    (op1[13] & op2[10]) + (op1[14] & op2[9]) + (op1[15] & op2[8]);
    assign c[60] = s23[1];
    assign c[61] = s23[2];
    assign c[62] = s23[2];
    //-----------------------------------
    assign s24 =    (op1[9] & op2[15]) + (op1[10] & op2[14]) + (op1[11] & op2[13]) + (op1[12] & op2[12]) + (op1[13] & op2[11]) +
                    (op1[14] & op2[10]) + (op1[15] & op2[9]);
    assign c[63] = s24[1];
    assign c[64] = s24[2];
    assign s25 =    (op1[10] & op2[15]) + (op1[11] & op2[14]) + (op1[12] & op2[13]) + (op1[13] & op2[12]) + (op1[14] & op2[11]) +
                    (op1[15] & op2[10]);
    assign c[65] = s25[1];
    assign c[66] = s25[2];
    assign s26 = (op1[11] & op2[15]) + (op1[12] & op2[14]) + (op1[13] & op2[13]) + (op1[14] & op2[12]) + (op1[15] & op2[11]);
    assign c[67] = s26[1];
    assign c[68] = s26[2];
    assign s27 = (op1[12] & op2[15]) + (op1[13] & op2[14]) + (op1[14] & op2[13]) + (op1[15] & op2[12]);
    assign c[69] = s27[1];
    assign c[70] = s27[2];
    //-----------------------------------
    assign s28 = (op1[13] & op2[15]) + (op1[14] & op2[14]) + (op1[15] & op2[13]);
    assign c[71] = s28[1];
    assign s29 = (op1[14] & op2[15]) + (op1[15] & op2[14]);
    assign c[72] = s29[1];
    assign s30 = (op1[15] & op2[15]);
    // ===================================================================================
    // Generation of final multiplier output

    always #3 $display("S3 = %2b\tC[2] = %1b\tResult = %1b\n", s3, c[2], r[3]);

    assign r[0] = s0[0];
    assign r[1] = s1[0] + c[0];
    assign r[2] = s2[0] + c[1];
    assign r[3] = s3[0] + c[2];
    assign r[4] = s4[0] + c[3];
    assign r[5] = s5[0] + c[5] + c[4];
    assign r[6] = s6[0] + c[7] + c[6];
    assign r[7] = s7[0] + c[9] + c[8];
    assign r[8] = s8[0] + c[11] + c[10];
    assign r[9] = s9[0] + c[14] + c[12];
    assign r[10] = s10[0] + c[17] + c[15] + c[13];
    assign r[11] = s11[0] + c[20] + c[18] + c[16];
    assign r[12] = s12[0] + c[23] + c[21] + c[19];
    assign r[13] = s13[0] + c[26] + c[24] + c[22];
    assign r[14] = s14[0] + c[29] + c[27] + c[25];
    assign r[15] = s15[0] + c[32] + c[30] + c[28];
    assign r[16] = s16[0] + c[35] + c[33] + c[31];
    assign r[17] = s17[0] + c[39] + c[36] + c[34];
    assign r[18] = s18[0] + c[42] + c[40] + c[37];
    assign r[19] = s19[0] + c[45] + c[43] + c[41] + c[38];
    assign r[20] = s20[0] + c[48] + c[46] + c[44];
    assign r[21] = s21[0] + c[51] + c[49] + c[47];
    assign r[22] = s22[0] + c[54] + c[52] + c[50];
    assign r[23] = s23[0] + c[57] + c[55] + c[53];
    assign r[24] = s24[0] + c[60] + c[58] + c[56];
    assign r[25] = s25[0] + c[63] + c[61] + c[59];
    assign r[26] = s26[0] + c[65] + c[64] + c[62];
    assign r[27] = s27[0] + c[67] + c[66];
    assign r[28] = s28[0] + c[69] + c[68];
    assign r[29] = s29[0] + c[71] + c[70];
    assign r[31:30] = s30 + c[72];


endmodule
