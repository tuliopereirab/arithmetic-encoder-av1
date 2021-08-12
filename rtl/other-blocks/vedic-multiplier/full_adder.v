module full_adder #() (
    input in0, in1, cin,
    output s, c
    );

    assign s = in0 ^ in1 ^ cin;
    assign c = ((in0 ^ in1) & cin) | (in0 & in1);

endmodule
