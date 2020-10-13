module vedic_8x8 (
    input [7:0] a, b,
    output [15:0] r
    );

    wire [7:0] vedic_1_out, vedic_2_out, vedic_3_out, vedic_4_out;
    wire [7:0] out_ripple_1, out_ripple_2, out_ripple_3;
    wire carry_ripple_1, carry_ripple_2, carry_ripple_3;


    // first line
    vedic_4x4 vedic_4x4_1 (
        .a (a[7:4]),
        .b (b[7:4]),
        .r (vedic_1_out)
        );

    vedic_4x4 vedic_4x4_2 (
        .a (a[3:0]),
        .b (b[7:4]),
        .r (vedic_2_out)
        );

    vedic_4x4 vedic_4x4_3 (
        .a (a[7:4]),
        .b (b[3:0]),
        .r (vedic_3_out)
        );

    vedic_4x4 vedic_4x4_4 (
        .a (a[3:0]),
        .b (b[3:0]),
        .r (vedic_4_out)
        );

    // ripple carries
    wire [7:0] lsb1_msb4;

    assign lsb1_msb4 = {vedic_1_out[3:0], vedic_4_out[7:4]};


    // it is supposed to use RIPPLE ADDER, BUT I'LL USE NORMAL ADD FOR NOW
    wire [9:0] adder_out;
    assign adder_out = lsb1_msb4 + vedic_2_out + vedic_3_out;



    // final
    assign r[3:0] = vedic_4_out[3:0];
    assign r[11:4] = adder_out[7:0];
    assign r[15:12] = vedic_1_out[7:4] + adder_out[9:8];
    //assign r[7] = carry_ripple_3;
endmodule
