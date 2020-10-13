// This module was based on the following article:

    // @INPROCEEDINGS{7034180,
    //     author={Y. B. {Prasad} and G. {Chokkakula} and P. S. {Reddy} and N. R. {Samhitha}},
    //     booktitle={International Conference on Information Communication and Embedded Systems (ICICES2014)},
    //     title={Design of low power and high speed modified carry select adder for 16 bit Vedic Multiplier},
    //     year={2014},
    //     volume={},
    //     number={},
    //     pages={1-6},
    //     doi={10.1109/ICICES.2014.7034180}
    // }

// -----------------------------
// Some other articles talking about the Vedic multiplier are:
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

module vedic_2x2 (
    input [1:0] a, b,
    output wire [3:0] r
    );
    wire a1b1, a0b1, a1b0, a0b0;
    wire carry_1;

    assign a0b0 = a[0] * b[0];
    assign a0b1 = a[0] * b[1];
    assign a1b0 = a[1] * b[0];
    assign a1b1 = a[1] * b[1];

    assign r[0] = a0b0;

    half_adder half_adder_1 (
        .a (a0b1),
        .b (a1b0),
        .c (carry_1),
        .s (r[1])
        );

    half_adder half_adder_2 (
        .a (a1b1),
        .b (carry_1),
        .c (r[3]),
        .s (r[2])
        );


endmodule
