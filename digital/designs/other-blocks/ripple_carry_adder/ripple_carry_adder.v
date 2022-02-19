module ripple_carry_adder #(
    parameter DATA_WIDTH = 10
    ) (
        input [(DATA_WIDTH-1):0] in0, in1,
        output wire [(DATA_WIDTH-1):0] out,
        output wire cout
    );
    wire [(DATA_WIDTH-1):0] c;
    genvar i;

    generate
        for(i=0; i<DATA_WIDTH;i = i+1) begin    : gen_loop
            if(i == (DATA_WIDTH-1)) begin
                full_adder fa (
                    .in0 (in0[i]),
                    .in1 (in1[i]),
                    .cin (c[i]),
                    .out (out[i]),
                    .cout (cout)
                    );
            end else begin
                full_adder fb (
                    .in0 (in0[i]),
                    .in1 (in1[i]),
                    .cin (c[i]),
                    .out (out[i]),
                    .cout (c[i+1])
                    );
            end
        end
    endgenerate
endmodule
