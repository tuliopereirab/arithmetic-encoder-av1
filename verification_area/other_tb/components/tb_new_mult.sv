module tb_new_mult #(
    parameter TB_RANGE_WIDTH = 16,
    parameter TOTAL_TESTS = 10000
    ) ();

    int general_counter, wrongs, rights;

    reg [15:0] tb_a, tb_b;
    wire [31:0] tb_r;

    new_multiplier #(
        .DATA_WIDTH (TB_RANGE_WIDTH)
        ) new_mult (
            .op1 (tb_a),
            .op2 (tb_b),
            .r (tb_r)
        );
    int i, val1, val2;
    initial begin
        general_counter = 0;
        wrongs = 0;
        rights = 0;
        while(general_counter < TOTAL_TESTS) begin
            val1 = $urandom_range(0,65535);
            val2 = $urandom_range(0,65535);
            tb_a <= val1;
            tb_b <= val2;
            #5ns;
            if(tb_r != (val1*val2)) begin
                $display("Erro! Got %d, expected %d * %d = %d\n\tRights: %d\n", tb_r, val1, val2, val1*val2, rights);
                $display("%16b\n%16b\n-----------------------------------\nE: %b\nG: %b\n", val1, val2, val1*val2, tb_r);
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
