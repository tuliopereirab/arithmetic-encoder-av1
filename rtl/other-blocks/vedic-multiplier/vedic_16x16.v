// This architecture, vedic_8x8 and vedic_4x4 were based on the following article:
    // @INPROCEEDINGS{7100233,
    //       author={U. {Narula} and R. {Tripathi} and G. {Wakhle}},
    //       booktitle={2015 2nd International Conference on Computing for Sustainable Global Development (INDIACom)},
    //       title={High speed 16-bit digital Vedic multiplier using FPGA},
    //       year={2015},
    //       volume={},
    //       number={},
    //       pages={121-124},
    // }

module vedic_16x16 (
    input [15:0] a, b,
    output [31:0] r
    );

    wire [15:0] vedic_1_out, vedic_2_out, vedic_3_out, vedic_4_out;
    wire [15:0] out_ripple_1, out_ripple_2, out_ripple_3;
    wire carry_ripple_1, carry_ripple_2, carry_ripple_3;


    // first line
    vedic_8x8 vedic_8x8_1 (
        .a (a[15:8]),
        .b (b[15:8]),
        .r (vedic_1_out)
        );

    vedic_8x8 vedic_8x8_2 (
        .a (a[7:0]),
        .b (b[15:8]),
        .r (vedic_2_out)
        );

    vedic_8x8 vedic_8x8_3 (
        .a (a[15:8]),
        .b (b[7:0]),
        .r (vedic_3_out)
        );

    vedic_8x8 vedic_8x8_4 (
        .a (a[7:0]),
        .b (b[7:0]),
        .r (vedic_4_out)
        );

    // ripple carries
    wire [15:0] lsb1_msb4;

    assign lsb1_msb4 = {vedic_1_out[7:0], vedic_4_out[15:8]};


    // it is supposed to use RIPPLE ADDER, BUT I'LL USE NORMAL ADD FOR NOW
    wire [19:0] adder_out;
    assign adder_out = lsb1_msb4 + vedic_2_out + vedic_3_out;



    // final
    assign r[7:0] = vedic_4_out[7:0];
    assign r[23:8] = adder_out[15:0];
    assign r[31:24] = vedic_1_out[15:8] + adder_out[19:16];
    //assign r[7] = carry_ripple_3;
endmodule
