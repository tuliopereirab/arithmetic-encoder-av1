module vedic_4x4 (
    input [3:0] a, b,
    output [7:0] r
    );

    wire [3:0] vedic_1_out, vedic_2_out, vedic_3_out, vedic_4_out;
    wire [3:0] out_ripple_1, out_ripple_2, out_ripple_3;
    wire carry_ripple_1, carry_ripple_2, carry_ripple_3;


    // first line
    vedic_2x2 vedic_2x2_1 (
        .a (a[3:2]),
        .b (b[3:2]),
        .r (vedic_1_out)
        );

    vedic_2x2 vedic_2x2_2 (
        .a (a[1:0]),
        .b (b[3:2]),
        .r (vedic_2_out)
        );

    vedic_2x2 vedic_2x2_3 (
        .a (a[3:2]),
        .b (b[1:0]),
        .r (vedic_3_out)
        );

    vedic_2x2 vedic_2x2_4 (
        .a (a[1:0]),
        .b (b[1:0]),
        .r (vedic_4_out)
        );

    // ripple carries
    wire [3:0] input_2_ripple_3, input_2_ripple_2;

    assign input_2_ripple_2 = {vedic_1_out[1:0], vedic_4_out[3:2]};


    // it is supposed to use RIPPLE ADDER, BUT I'LL USE NORMAL ADD FOR NOW
    wire [4:0] adder_out;
    assign adder_out = input_2_ripple_2 + vedic_2_out + vedic_3_out;


    // final
    assign r[1:0] = vedic_4_out[1:0];
    assign r[5:2] = adder_out[3:0];
    assign r[7:6] = vedic_1_out[3:2] + adder_out[4];
    //assign r[7] = carry_ripple_3;
endmodule
