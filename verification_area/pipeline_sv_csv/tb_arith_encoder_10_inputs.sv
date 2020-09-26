module tb_arith_encoder_10 #(
    parameter TB_RANGE_WIDTH = 16,
    parameter TB_LOW_WIDTH = 24,
    parameter TB_SYMBOL_WIDTH = 4,
    parameter TB_LUT_ADDR_WIDTH = 8,
    parameter TB_LUT_DATA_WIDTH = 16,
    parameter TB_D_SIZE = 4
    ) ();

    typedef struct {
        int input_fl;
        int input_fh;
        int output_range;
        int input_symbol;
        int input_nsyms;
        int output_low;
    } sim_data;

    sim_data simulation [9:0];      // creates the simulation vector

    // file reader
    integer fd;
    int temp_fl, temp_fh, temp_range;
    int temp_symbol;
    int temp_nsyms;
    int temp_low;
    int status;
    int i;
    // ----------------------

    reg tb_clk, tb_reset;
    reg [(TB_RANGE_WIDTH-1):0] tb_fl, tb_fh;
    reg [(TB_SYMBOL_WIDTH-1):0] tb_symbol;
    reg [TB_SYMBOL_WIDTH:0] tb_nsyms;
    wire [(TB_RANGE_WIDTH-1):0] tb_range;
    wire [(TB_LOW_WIDTH-1):0] tb_low;


    arithmetic_encoder #(
        .GENERAL_RANGE_WIDTH (TB_RANGE_WIDTH),
        .GENERAL_LOW_WIDTH (TB_LOW_WIDTH),
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
            .LOW_OUTPUT (tb_low)
        );

        always #6ns tb_clk <= ~tb_clk;

        initial begin
            tb_clk <= 1'b0;
            fd = $fopen("C:/Users/Tulio/Desktop/arithmetic_encoder_av1/verification_area/simulation_data/decimal-csv-files/miss-video_10-rows.csv", "r");
            for(i=0; i<10; i++) begin
                status = $fscanf (fd, "%d;%d;%d;%d;%d;%d\n", temp_fl, temp_fh, temp_symbol, temp_nsyms, temp_low, temp_range);
                if(status != 6) begin
                    $display("Not read %d\n", i);
                end
                else begin
                    simulation[i].input_fl = temp_fl;
                    simulation[i].input_fh = temp_fh;
                    simulation[i].output_range = temp_range;
                    simulation[i].input_symbol = temp_symbol;
                    simulation[i].input_nsyms = temp_nsyms;
                    simulation[i].output_low = temp_low;
                    $display("Test print: \tInput_FL: %d\tOutput_low: %d\n----------\n", simulation[i].input_fl, simulation[i].output_low);
                end
            end
            $fclose(fd);
            $display("==============\nDone reading the file\n=============\n");

            // first assignment
            $display("-> Setting start values\n");
            tb_reset <= 1'b1;
            tb_fl <= simulation[0].input_fl;
            tb_fh <= simulation[0].input_fh;
            tb_symbol <= simulation[0].input_symbol;
            tb_nsyms <= simulation[0].input_nsyms;
            #12ns;
            $display("-> Setting reset 0\n");
            tb_reset <= 1'b0;
            #24ns;
            for(i=1; i<10; i++) begin
                $display("\t-> Setting data test # %d\n", i);
                tb_fl <= simulation[i].input_fl;
                tb_fh <= simulation[i].input_fh;
                tb_symbol <= simulation[i].input_symbol;
                tb_nsyms <= simulation[i].input_nsyms;
                if(i >= 2) begin
                    if(tb_range == simulation[i-2].output_range)
                        $display("\t\t-> Range matching with expected.\n---------\n");
                    else
                        $display("\t\t-> Range doesn't match with what was expected. Got %d, expecting %d\n---------\n", tb_range, simulation[i-2].output_range);

                    if(tb_low == simulation[i-2].output_low)
                        $display("\t\t-> Low matching with expected.\n");
                    else
                        $display("\t\t-> Low doesn't match with what was expected. Got %d, expecting %d\n", tb_low, simulation[i-2].output_low);
                end
                $display("=================\n");
                #24ns;
            end

        end
endmodule
