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
