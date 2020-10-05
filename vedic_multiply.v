// This module is a 8-bit adaptation of the following articles:

    //@INPROCEEDINGS{8554743,
    //  author={S. {Sujina} and R. {Remya}},
    //  booktitle={2018 International Conference on Advances in Computing, Communications and Informatics (ICACCI)},
    //  title={An Effective Method For Hardware Multiplication Using Vedic Mathematics},
    //  year={2018},
    //  volume={},
    //  number={},
    //  pages={1499-1504},
    //  doi={10.1109/ICACCI.2018.8554743}
    //}

    // @INPROCEEDINGS{5423043,
        // author={M. E. {Paramasivam} and R. S. {Sabeenian}},
        // booktitle={2010 IEEE 2nd International Advance Computing Conference (IACC)},
        // title={An efficient bit reduction binary multiplication algorithm using vedic methods},
        // year={2010},
        // volume={},
        // number={},
        // pages={25-28},
        // doi={10.1109/IADCC.2010.5423043}
    // }

// -------------------------------------------
// Didn't work
    // @INPROCEEDINGS{7894719,
        // author={K. D. {Rao} and C. {Gangadhar} and P. K. {Korrai}},
        // booktitle={2016 IEEE Uttar Pradesh Section International Conference on Electrical, Computer and Electronics Engineering (UPCON)},
        // title={FPGA implementation of complex multiplier using minimum delay Vedic real multiplier architecture},
        // year={2016},
        // volume={},
        // number={},
        // pages={580-584},
        // doi={10.1109/UPCON.2016.7894719}
    // }

module vedic_multiply #(
    parameter RANGE_WIDTH = 16
    )(
        input [((RANGE_WIDTH/2)-1):0] m, p,
        output wire [(RANGE_WIDTH-1):0] r
    );
    wire [1:0] temp_sum_1, temp_sum_2, temp_sum_3, temp_sum_4, temp_sum_5;
    wire [1:0] temp_sum_6, temp_sum_7, temp_sum_8, temp_sum_9, temp_sum_10;
    wire [1:0] temp_sum_11, temp_sum_12, temp_sum_13, temp_sum_14;
    wire [12:0] c;

    assign r[1] = temp_sum_1[0];
    assign r[2] = temp_sum_2[0];
    assign r[3] = temp_sum_3[0];
    assign r[4] = temp_sum_4[0];
    assign r[5] = temp_sum_5[0];
    assign r[6] = temp_sum_6[0];
    assign r[7] = temp_sum_7[0];
    assign r[8] = temp_sum_8[0];
    assign r[9] = temp_sum_9[0];
    assign r[10] = temp_sum_10[0];
    assign r[11] = temp_sum_11[0];
    assign r[12] = temp_sum_12[0];
    assign r[13] = temp_sum_13[0];
    assign r[14] = temp_sum_14[0];
    assign r[15] = temp_sum_14[1];

    assign c[0] = temp_sum_1[1];
    assign c[1] = temp_sum_2[1];
    assign c[2] = temp_sum_3[1];
    assign c[3] = temp_sum_4[1];
    assign c[4] = temp_sum_5[1];
    assign c[5] = temp_sum_6[1];
    assign c[6] = temp_sum_7[1];
    assign c[7] = temp_sum_8[1];
    assign c[8] = temp_sum_9[1];
    assign c[9] = temp_sum_10[1];
    assign c[10] = temp_sum_11[1];
    assign c[11] = temp_sum_12[1];
    assign c[12] = temp_sum_13[1];

    // equations
    assign r[0] = m[0] * p[0];
    assign temp_sum_1 = m[1]*p[0] + m[0]*p[1];
    assign temp_sum_2 = c[0] + m[2]*p[0] + m[1]*p[1] + m[0]*p[2];
    assign temp_sum_3 = c[1] + m[3]*p[0] + m[2]*p[1] + m[1]*p[2] + m[0]*p[3];
    assign temp_sum_4 = c[2] + m[4]*p[0] + m[3]*p[1] + m[2]*p[2] + m[1]*p[3] + m[0]*p[4];
    assign temp_sum_5 = c[3] + m[5]*p[0] + m[4]*p[1] + m[3]*p[2] + m[2]*p[3] + m[1]*p[4] + m[0]*p[5];
    assign temp_sum_6 = c[4] + m[6]*p[0] + m[5]*p[1] + m[4]*p[2] + m[3]*p[3] + m[2]*p[4] + m[1]*p[5] + m[0]*p[6];
    assign temp_sum_7 = c[5] + m[7]*p[0] + m[6]*p[1] + m[5]*p[2] + m[4]*p[3] + m[3]*p[4] + m[2]*p[5] + m[1]*p[6] + m[0]*p[7];
    assign temp_sum_8 = c[6] + m[7]*p[1] + m[6]*p[2] + m[5]*p[3] + m[4]*p[4] + m[3]*p[5] + m[2]*p[6] + m[1]*p[7];
    assign temp_sum_9 = c[7] + m[7]*p[2] + m[6]*p[3] + m[5]*p[4] + m[4]*p[5] + m[3]*p[6] + m[2]*p[7];
    assign temp_sum_10 = c[8] + m[7]*p[3] + m[6]*p[4] + m[5]*p[5] + m[4]*p[6] + m[3]*p[7];
    assign temp_sum_11 = c[9] + m[7]*p[4] + m[6]*p[5] + m[5]*p[6] + m[4]*p[7];
    assign temp_sum_12 = c[10] + m[7]*p[5] + m[6]*p[6] + m[5]*p[7];
    assign temp_sum_13 = c[11] + m[7]*p[6] + m[6]*p[7];
    assign temp_sum_14 = c[12] + m[7]*p[7];


endmodule
