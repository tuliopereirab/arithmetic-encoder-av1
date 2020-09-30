module tb_multiply #(
    parameter TB_RANGE_WIDTH = 16
    ) ();

    reg [((TB_RANGE_WIDTH/2)-1):0] tb_m, tb_p;
    wire [(TB_RANGE_WIDTH-1):0] tb_r;

    vedic_multiply #(
        .RANGE_WIDTH (TB_RANGE_WIDTH)
        ) multiply (
            .m (tb_m),
            .p (tb_p),
            .r (tb_r)
        );
    int i, val1, val2;
    initial begin
        while(1) begin
            val1 = $urandom_range(0,255);
            val2 = $urandom_range(0,255);
            tb_m <= val1;
            tb_p <= val2;
            #10ns;
            if(tb_r != (val1*val2))
                $display("Erro! Got %d, expected %d * %d = %d\n", tb_r, val1, val2, val1*val2);
            else
                $display("Correto! %d * %d = %d\n", val1, val2, val1*val2);
            #5ns;
        end
    end

endmodule
