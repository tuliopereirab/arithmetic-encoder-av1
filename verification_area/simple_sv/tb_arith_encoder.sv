module tb_artih_encoder #(
    parameter TB_DATA_16 = 16,
    parameter TB_DATA_32 = 32,
    parameter TB_SYMBOL_WIDTH = 4,
    parameter TB_LUT_ADDR_WIDTH = 8,
    parameter TB_LUT_DATA_WIDTH = 16,
    parameter TB_D_SIZE = 4
    ) ();

    reg tb_clk, tb_reset;
    reg [(TB_DATA_16-1):0] tb_fl, tb_fh;
    reg [(TB_SYMBOL_WIDTH-1):0] tb_symbol;
    reg [TB_SYMBOL_WIDTH:0] tb_nsyms;
    wire [(TB_DATA_16-1):0] tb_range, tb_low;
    wire [(TB_DATA_32-1):0] tb_cnt;


    arithmetic_encoder #(
        .GENERAL_DATA_16 (TB_DATA_16),
        .GENERAL_DATA_32 (TB_DATA_32),
        .GENERAL_SYMBOL_WIDTH (TB_SYMBOL_WIDTH),
        .GENERAL_LUT_ADDR_WIDTH (TB_LUT_ADDR_WIDTH),
        .GENERAL_LUT_DATA_WIDTH (TB_LUT_DATA_WIDTH),
        .GENERAL_D_SIZE (TB_D_SIZE)
        ) arith_encoder (
            .general_clk (tb_clk),
            .reset (tb_reset),
            .general_fl (tb_fl),
            .general_fh (tb_fh),
            .general_symbol (tb_symbol),
            .general_nsyms (tb_nsyms),
            // outputs
            .RANGE_OUTPUT (tb_range),
            .LOW_OUTPUT (tb_low),
            .CNT_OUTPUT (tb_cnt)
        );

        always #6ns tb_clk <= ~tb_clk;

        initial begin
            tb_clk <= 1'b0;
            tb_reset <= 1'b1;
            tb_fl <= 16'd9690;
            tb_fh <= 16'd3202;
            tb_symbol <= 4'd3;
            tb_nsyms <= 5'd10;

            #15ns tb_reset <= 1'b0;
        end
endmodule
