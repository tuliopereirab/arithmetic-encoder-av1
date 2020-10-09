module tb_arith_encoder_entire_file #(
    parameter TB_RANGE_WIDTH = 16,
    parameter TB_LOW_WIDTH = 24,
    parameter TB_SYMBOL_WIDTH = 4,
    parameter TB_LUT_ADDR_WIDTH = 8,
    parameter TB_LUT_DATA_WIDTH = 16,
    parameter TB_D_SIZE = 4
    ) ();

    // file reader
    integer fd;
    int temp_fl, temp_fh, temp_range;
    int temp_bool;
    int temp_symbol;
    int temp_nsyms;
    int temp_low;
    int status;
    int verify_save, verify_read;       // J will be used to define the result to be compared
    // extra variables
    int temp_init_range, temp_init_low;
    int temp_norm_in_rng, temp_norm_in_low;
    // ----------------------
    // Verification
    int counter, verify_range[3], verify_low[3];
    // ----------------------
    // architecture
    reg tb_clk, tb_reset;
    reg [(TB_RANGE_WIDTH-1):0] tb_fl, tb_fh;
    reg [(TB_SYMBOL_WIDTH-1):0] tb_symbol;
    reg [TB_SYMBOL_WIDTH:0] tb_nsyms;
    reg tb_bool;
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
            .general_bool (tb_bool),
            // outputs
            .RANGE_OUTPUT (tb_range),
            .LOW_OUTPUT (tb_low)
        );

        always #6ns tb_clk <= ~tb_clk;

        initial begin
            $display("Start to read the file.\n");
            tb_clk <= 1'b0;
            fd = $fopen("C:/Users/Tulio/Desktop/arithmetic_encoder_av1/verification_area/simulation_data/full_data/new-data-miss-video_full-video.csv", "r");
            status = $fscanf (fd, "%d;%d;%d;%d;%d;%d;%d;%d;%d;%d;%d;\n", temp_bool, temp_init_range, temp_init_low, temp_fl, temp_fh, temp_symbol, temp_nsyms, temp_norm_in_rng, temp_norm_in_low, temp_range, temp_low);
            tb_bool = temp_bool;
            tb_fl = temp_fl;
            tb_fh = temp_fh;
            tb_symbol = temp_symbol;
            tb_nsyms = temp_nsyms;
            tb_reset <= 1'b1;
            #12ns;
            tb_reset = 1'b0;
            #12ns;
            counter = 0;
            verify_read = 1;
            verify_save = 0;
            while(!$feof(fd)) begin
                status = $fscanf (fd, "%d;%d;%d;%d;%d;%d;%d;%d;%d;%d;%d;\n", temp_bool, temp_init_range, temp_init_low, temp_fl, temp_fh, temp_symbol, temp_nsyms, temp_norm_in_rng, temp_norm_in_low, temp_range, temp_low);
                if(status != 11) begin
                    $display("Not read %d\n", counter);
                end
                else begin
                    tb_bool = temp_bool;
                    tb_fl = temp_fl;
                    tb_fh = temp_fh;
                    tb_symbol = temp_symbol;
                    tb_nsyms = temp_nsyms;
                    verify_range[verify_save] = temp_range;
                    verify_low[verify_save] = temp_low;
                    if(counter > 2) begin
                        if(verify_range[verify_read] != tb_range) begin
                            $display("%d-> Range doesn't match with expected. \t%d, got %d\n", counter, verify_range[verify_read], tb_range);
                        end else begin
                            $display("%d-> Range ok\n", counter);
                        end
                        if(verify_low[verify_read] != tb_low) begin
                            $display("%d-> Low doesn't match with expected. \t%d, got %d\n", counter, verify_low[verify_read], tb_low);
                        end else begin
                            $display("%d-> Low ok\n", counter);
                        end
                    end
                    if(verify_save >= 2) begin
                        verify_save = 0;
                    end
                    else begin
                        verify_save = verify_save + 1;
                    end

                    if(verify_read >= 2) begin
                        verify_read = 0;
                    end
                    else begin
                        verify_read = verify_read + 1;
                    end

                    counter = counter + 1;
                    #12ns;
                end
            end
            $fclose(fd);
            $display("==============\nDone reading the file\n=============\n");
        end
endmodule
