module tb_vedic_2x2 #(
    parameter TB_RANGE_WIDTH = 16,
    parameter TOTAL_TESTS = 1000000
    ) ();

    int general_counter, wrongs, rights;

    reg [1:0] tb_a, tb_b;
    wire [3:0] tb_r;

    vedic_2x2 vedic_tb_2x2 (
            .a (tb_a),
            .b (tb_b),
            .r (tb_r)
        );
    int i, val1, val2;
    initial begin
        general_counter = 0;
        wrongs = 0;
        rights = 0;
        while(general_counter < TOTAL_TESTS) begin
            val1 = $urandom_range(0,3);
            val2 = $urandom_range(0,3);
            tb_a <= val1;
            tb_b <= val2;
            #5ns;
            if(tb_r != (val1*val2)) begin
                $display("Erro! Got %d, expected %d * %d = %d\n", tb_r, val1, val2, val1*val2);
                wrongs = wrongs + 1;
                $stop;
            end else begin
                rights = rights + 1;
                //$display("Correto! %d * %d = %d\n", val1, val2, val1*val2);
            end
            general_counter = general_counter + 1;
            #5ns;
        end
        $display("--------------\nOperations: %d\nMatches: %d\nMisses: %d\n--------------\n", general_counter, rights, wrongs);
        $stop;
    end

endmodule
