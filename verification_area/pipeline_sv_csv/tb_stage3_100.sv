module tb_stage_3 #(
    parameter TB_RANGE_WIDTH = 16,
    parameter TB_LOW_WIDTH = 24,
    parameter TB_SYMBOL_WIDTH = 4,
    parameter TB_LUT_ADDR_WIDTH = 8,
    parameter TB_LUT_DATA_WIDTH = 16,
    parameter TB_D_SIZE = 4,
    parameter INTERNAL_TB_SIZE = 100
    ) ();

    typedef struct {
        int input_range;
        int input_cnt;
        int input_low;
        int output_cnt;
        int output_range;
        int output_low;
    } sim_data;

    sim_data simulation [(INTERNAL_TB_SIZE-1):0];      // creates the simulation vector

    // file reader
    integer fd;
    int temp_range_in, temp_low_in, temp_cnt_in;
    int temp_range_out, temp_low_out;
    int status;
    int i;
    // ----------------------

    //reg tb_clk;
    reg [(TB_RANGE_WIDTH-1):0] tb_range_in;
    reg [(TB_LOW_WIDTH-1):0] tb_low_in;
    reg [(TB_D_SIZE-1):0] tb_cnt_in;
    wire [(TB_RANGE_WIDTH-1):0] tb_range_out;
    wire [(TB_LOW_WIDTH-1):0] tb_low_out;
    wire [(TB_D_SIZE-1):0] tb_cnt_out;


    stage_3 #(
        .RANGE_WIDTH (TB_RANGE_WIDTH),
        .LOW_WIDTH (TB_LOW_WIDTH),
        .D_SIZE (TB_D_SIZE)
        ) pipeline_stage_3 (
            .range (tb_range_in),
            .low (tb_low_in),
            .in_s (tb_cnt_in),
            // outputs
            .out_range (tb_range_out),
            .out_low (tb_low_out),
            .out_s (tb_cnt_out)
        );

        //always #6ns tb_clk <= ~tb_clk;

        initial begin
            $display("Start to read the file.\n");
            //tb_clk <= 1'b0;
            fd = $fopen("C:/Users/Tulio/Desktop/arithmetic_encoder_av1/verification_area/simulation_data/decimal-csv-files/miss-video_stage-3_tb_100rows.csv", "r");
            for(i=0; i<INTERNAL_TB_SIZE; i++) begin
                status = $fscanf (fd, "%d;%d;%d;%d;%d\n", temp_low_in, temp_range_in, temp_cnt_in, temp_low_out, temp_range_out);
                if(status != 5) begin
                    $display("Not read %d\n", i);
                end
                else begin
                    simulation[i].input_range = temp_range_in;
                    simulation[i].input_low = temp_low_in;
                    simulation[i].input_cnt = temp_cnt_in;
                    simulation[i].output_low = temp_low_out;
                    simulation[i].output_range = temp_range_out;
                    // $display("Test print: \tInput_FL: %d\tOutput_low: %d\n----------\n", simulation[i].input_fl, simulation[i].output_low);
                end
            end
            $fclose(fd);
            $display("==============\nDone reading the file\n=============\n");

            // first assignment
            $display("-> Setting start values\n");
            for(i=0; i<INTERNAL_TB_SIZE; i++) begin
                $display("\t-> Setting data test # %d\n", i);
                tb_range_in <= simulation[i].input_range;
                tb_low_in <= simulation[i].input_low;
                tb_cnt_in <= simulation[i].input_cnt;
                #6ns
                // Now the simulation will only print values that don't match with expected.
                if(tb_range_out != simulation[i].output_range)
                    $display("\t\t-> Range doesn't match with what was expected. Got %d, expecting %d\n---------\n", tb_range_out, simulation[i].output_range);

                if(tb_low_out != simulation[i].output_low)
                    $display("\t\t-> Low doesn't match with what was expected. Got %d, expecting %d\n", tb_low_out, simulation[i].output_low);

                if(i < (INTERNAL_TB_SIZE-1)) begin
                    if(tb_cnt_out != simulation[i+1].input_cnt)
                        $display("\t\t-> CNT doesn't match with what was expected. Got %d, expecting %d\n", tb_cnt_out, simulation[i+1].input_cnt);
                end
                $display("=================\n");
                #6ns;
            end
        end
endmodule
