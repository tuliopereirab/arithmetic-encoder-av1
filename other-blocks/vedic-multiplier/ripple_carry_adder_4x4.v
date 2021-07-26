module ripple_carry_4x4 (
    input [3:0] a, b,
    input cin_ripple,
    output wire [3:0] s_out,
    output wire c_out
    );
    wire c0, c1, c2;

    full_adder full_adder_1 (
        .in0 (a[0]),
        .in1 (b[0]),
        .cin (cin_ripple),
        .s (s_out[0]),
        .c (c0)
        );

    full_adder full_adder_2 (
        .in0 (a[1]),
        .in1 (b[1]),
        .cin (c0),
        .s (s_out[1]),
        .c (c1)
        );

    full_adder full_adder_3 (
        .in0 (a[2]),
        .in1 (b[2]),
        .cin (c1),
        .s (s_out[2]),
        .c (c2)
        );

    full_adder full_adder_4 (
        .in0 (a[3]),
        .in1 (b[3]),
        .cin (c2),
        .s (s_out[3]),
        .c (c_out)
        );

endmodule
