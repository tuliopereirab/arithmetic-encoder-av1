module full_adder #() (
    input in0, in1, cin,
    output out, cout
    );

    assign out = in0 ^ in1 ^ cin;
    assign cout = ((in0 ^ in1) & cin) | (in0 & in1);

endmodule
