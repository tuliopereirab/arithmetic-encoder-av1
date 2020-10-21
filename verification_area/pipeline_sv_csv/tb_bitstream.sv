`timescale 1ns / 10ps

module tb_bitstream #(
    parameter TB_RANGE_WIDTH = 16,          // These parameters (lines 2 to 7) represent the architecture parameters
    parameter TB_LOW_WIDTH = 24,            // They must be changed ONLY IF THERE ARE CHANGES IN THE ARCHITECTURE
    parameter TB_SYMBOL_WIDTH = 4,          // Changing these parameters WILL NOT ensure a correct execution by the architecture
    parameter TB_LUT_ADDR_WIDTH = 8,        // All changes on these parameters must be analyzed before and change some internal defaults in the architecture
    parameter TB_LUT_DATA_WIDTH = 16,
    parameter TB_D_SIZE = 5,
    parameter SELECT_VIDEO = 2,         // This parameter selects the video to be simulated according with the following list:
                                        // 0- Miss America 150 frames 176x144
                                        // 1- Akiyo 300 frames 176x144
                                        // 2- Carphone 382 frames 176x144
    parameter RUN_UNTIL_FIRST_MISS = 1, // With this option in 1, the simulation will stop as soon as it gets the first miss
                                        // It doesn't matter if the miss is with Range or low
                                        // 0- Run until the end of the simulation and count misses and matches
                                        // 1- Stop when find the first miss
    parameter PIPELINE_STAGES = 3       // This variable defines the number of pipeline stages
                                        // If the pipeline changes, many things will need to change in the testbench
                                        // This variable will make it easier to change things here
    )();

    // File read variables
    int main_file, bitstream_file, done_file;
    int temp_low_done, temp_cnt_done, temp_offs_done;       // variable filled with the data from the Done file
    int temp_bit_1, temp_bit_2;                             // variables filled with the data from the bitstream file
    int temp_fl, temp_fh, temp_symbol, temp_nsyms, temp_bool;   // inputs
    int temp_range, temp_low;               // verification variables (final numbers for low and range)
    int temp_init_range, temp_init_low;     // reset variables (verify is these variables are 32768 and 0, respectively)
    int status_main_file, status_bitstream_file, status_done_file;     // check if the file was correctly read
    // Extra variables that comes from the file
    int temp_norm_in_rng, temp_norm_in_low; // these variables are contained in the file as the input for the normalization function
    // ---------------------------------
    // Verification variables
    int number_increase_offs, temp_s_done;      // used to set the correct number to check the OFFS value
    int offs_previous, num_offs_greater;     // this variable will count the number of OFFS that are greater that the previous one
    int i, reset_sign_return, video;   // variable use for control
    int frame_counter, general_counter, reset_counter;       // the General counter will be responsible to keep track of the architecture in general while the counter frame will count only the execution while in a frame
    int verify_range[PIPELINE_STAGES+1], verify_low[PIPELINE_STAGES+1];    // general counter and low/range arrays to verify the value PIPELINE_STAGES later
                                                                                    // As this TB doesn't save all the numbers from the input file and the current input won't result in an imidiate result
                                                                                    // It is necessary to keep the output value saved to be compare PIPELINE_STAGES later, when the input will be finally ready.
    int verify_bit_1[PIPELINE_STAGES+1], verify_bit_2[PIPELINE_STAGES+1];
    int verify_read, verify_save;
    int match_counter_range, miss_counter_range;        // variables to keep track of how many matches and misses were detected regarding the range value
    int match_counter_low, miss_counter_low;            // variables to keep track of how many matches and misses were detected regading the low value
    int match_bit_1, miss_bit_1;
    int match_bit_2, miss_bit_2;
    int match_offs_done, miss_offs_done;
    int match_cnt_done, miss_cnt_done;
    int match_low_done, miss_low_done;
    int flag_zero;
    int previous_range_out, previous_low_out;   // these variable are part of the reset detection
                                                // It is defined a reset when:
                                                    // 1- Low_input = 0 AND Range_input = 32768
                                                    // 2- Low_input != Previous_low_output AND Range_input != Previous_range_output
    // ---------------------------------
    // Architecture "conversation" variables
    // Here are declared all variables representing the inputs and outputs of the architecture.
    // Setting the REG variables here will automatically set the architecture's input pins
    reg tb_clk, tb_reset;
    reg [(TB_RANGE_WIDTH-1):0] tb_fl, tb_fh;
    reg [(TB_SYMBOL_WIDTH-1):0] tb_symbol;
    reg [TB_SYMBOL_WIDTH:0] tb_nsyms;
    reg tb_bool;
    wire [(TB_RANGE_WIDTH-1):0] tb_range, tb_offs;
    wire [(TB_LOW_WIDTH-1):0] tb_low;
    wire [(TB_RANGE_WIDTH-1):0] tb_bit_1, tb_bit_2;
    wire [(TB_D_SIZE-1):0] tb_cnt;
    wire [1:0] tb_flag_bitstream;
    // ---------------------------------
    // Architecture declaration
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
            // bitstream
            .OUT_FLAG_BITSTREAM (tb_flag_bitstream),
            .OUT_OFFS (tb_offs),
            .OUT_BIT_1 (tb_bit_1),
            .OUT_BIT_2 (tb_bit_2),
            // outputs
            .RANGE_OUTPUT (tb_range),
            .LOW_OUTPUT (tb_low),
            .CNT_OUTPUT (tb_cnt)
        );
    // ---------------------------------

    always #6ns tb_clk <= ~tb_clk;      // Here is the Clock (clk) generator
                                        // It is set to execute in a 12ns period
    function void open_file;
        case(SELECT_VIDEO)
            0 : begin
                $display("\t-> Video selected: Miss America 150 frames 176x144 (Bitstream testbench)\n");
                main_file = $fopen("C:/Users/Tulio/Desktop/arithmetic_encoder_av1/verification_area/simulation_data/Bitstream_TB_Data/miss_video_main_data.csv", "r");
                bitstream_file = $fopen("C:/Users/Tulio/Desktop/arithmetic_encoder_av1/verification_area/simulation_data/Bitstream_TB_Data/miss_video_bitstream.csv", "r");
                done_file = $fopen("C:/Users/Tulio/Desktop/arithmetic_encoder_av1/verification_area/simulation_data/Bitstream_TB_Data/miss_video_done.csv", "r");
            end
            1 : begin
                $display("\t-> Video selected: Akiyo 300 frames 176x144 (Bitstream testbench)\n");
                main_file = $fopen("C:/Users/Tulio/Desktop/arithmetic_encoder_av1/verification_area/simulation_data/Bitstream_TB_Data/akiyo_video_main_data.csv", "r");
                bitstream_file = $fopen("C:/Users/Tulio/Desktop/arithmetic_encoder_av1/verification_area/simulation_data/Bitstream_TB_Data/akiyo_video_bitstream.csv", "r");
                done_file = $fopen("C:/Users/Tulio/Desktop/arithmetic_encoder_av1/verification_area/simulation_data/Bitstream_TB_Data/akiyo_video_done.csv", "r");
            end
            2 : begin
                $display("\t-> Video selected: Carphone 382 frames 176x144 (Bitstream testbench)\n");
                main_file = $fopen("C:/Users/Tulio/Desktop/arithmetic_encoder_av1/verification_area/simulation_data/Bitstream_TB_Data/carphone_video_main_data.csv", "r");
                bitstream_file = $fopen("C:/Users/Tulio/Desktop/arithmetic_encoder_av1/verification_area/simulation_data/Bitstream_TB_Data/carphone_video_bitstream.csv", "r");
                done_file = $fopen("C:/Users/Tulio/Desktop/arithmetic_encoder_av1/verification_area/simulation_data/Bitstream_TB_Data/carphone_video_done.csv", "r");
            end
        endcase
    endfunction
    function void reset_function;
        input int start_flag;     // start flag will define if the testbench variable will or won't be resetted
                                // in the case of a reset between frames, it is necessary to keep the counter and miss/matches variables
        // This function is responsible for the reset procedure
        // Always when the testbench starts, the reset procedure will be called with the start flag 1 and important verification variables will be resetted as necessary
        // However, sometimes this function will be called only as a reset between frames, where some of the variable will be resetted
        if(start_flag) begin
            $display("\t-> Resetting testbench variables\n");
            reset_counter = 0;
            general_counter = 0;
            miss_counter_low = 0;
            match_counter_low = 0;
            miss_counter_range = 0;
            match_counter_range = 0;
            match_bit_1 = 0;
            match_bit_2 = 0;
            miss_bit_1 = 0;
            miss_bit_2 = 0;
            flag_zero = 0;
            num_offs_greater = 0;
            offs_previous = 99999999;
            match_offs_done = 0;
            match_cnt_done = 0;
            match_low_done = 0;
            miss_offs_done = 0;
            miss_cnt_done = 0;
            miss_low_done = 0;
        end
        //$display("\t\t-> Resetting verification arrays\n");
        frame_counter = 0;
        verify_read = 1;
        verify_save = 0;
        if(start_flag) begin
            $display("\t-> Reading first line of the file\n");
            status_main_file = $fscanf (main_file, "%d;%d;%d;%d;%d;%d;%d;%d;%d;%d;%d;\n", temp_bool, temp_init_range, temp_init_low, temp_fl, temp_fh, temp_symbol, temp_nsyms, temp_norm_in_rng, temp_norm_in_low, temp_range, temp_low);
            status_bitstream_file = $fscanf (bitstream_file, "%d;%d;\n", temp_bit_2, temp_bit_1);
            if(status_bitstream_file != 2) begin
                $display("\t-> Problem reading the bitstream file\n-> Closing testbench\n");
                $stop;
            end
            if(status_main_file != 11) begin
                $display("\t-> Problem reading the file\n-> Closing testbench\n");
                $stop;
            end else begin
                $display("\t\t-> Setting architecture inputs\n");
                tb_bool = temp_bool;
                tb_fl = temp_fl;
                tb_fh = temp_fh;
                tb_symbol = temp_symbol;
                tb_nsyms = temp_nsyms;
                verify_low[verify_save] = temp_low;
                verify_range[verify_save] = temp_range;
                verify_bit_1[verify_save] = temp_bit_1;
                verify_bit_2[verify_save] = temp_bit_2;
                tb_reset <= 1'b1;
                $display("\t\t-> Saving verification arrays\n");
                $display("\t\t-> Updating pointers' values\n");
                verify_save = verify_save + 1;
                verify_read = verify_read + 1;
                general_counter = general_counter + 1;
                frame_counter = general_counter;
            end
        end else begin
            tb_bool = temp_bool;
            tb_fl = temp_fl;
            tb_fh = temp_fh;
            tb_symbol = temp_symbol;
            tb_nsyms = temp_nsyms;
            verify_bit_1[verify_save] = temp_bit_1;
            verify_bit_2[verify_save] = temp_bit_2;
            verify_low[verify_save] = temp_low;
            verify_range[verify_save] = temp_range;
            tb_reset <= 1'b1;
            update_array_pointers();
        end
    endfunction
    function void update_array_pointers;
        frame_counter = frame_counter + 1;
        if(verify_save >= PIPELINE_STAGES)
            verify_save = 0;
        else
            verify_save = verify_save + 1;

        if(verify_read >= PIPELINE_STAGES)
            verify_read = 0;
        else
            verify_read = verify_read + 1;
    endfunction
    function void check_with_done_file;
        status_done_file = $fscanf(done_file, "%d;%d;%d;\n", temp_low_done, temp_cnt_done, temp_offs_done);
        number_increase_offs = 1;
        temp_s_done = temp_cnt_done+2;      // (cnt + 10) - 8
        while(temp_s_done > 0) begin
            number_increase_offs = number_increase_offs + 1;
            temp_s_done = temp_s_done - 8;
        end
        if(status_done_file != 3) begin
            $display("\t-> Problem reading the done file\n-> Closing testbench\n");
            $stop;
        end
        if(tb_low != temp_low_done) begin
            miss_low_done = miss_low_done + 1;
            if(RUN_UNTIL_FIRST_MISS) begin
                $display("%d-> Low Done doesn't match with expected. \t%d, got %d\n", general_counter, temp_low_done, tb_low);
                statistic(1);
            end
        end else begin
            match_low_done = match_low_done + 1;
        end

        if(tb_cnt != (temp_cnt_done+9)) begin
            miss_cnt_done = miss_cnt_done + 1;
            if(RUN_UNTIL_FIRST_MISS) begin
                $display("%d-> CNT Done doesn't match with expected. \t%d, got %d\n", general_counter, (temp_cnt_done+9), tb_cnt);
                statistic(1);
            end
        end else begin
            match_cnt_done = match_cnt_done + 1;
        end

        if(tb_offs != (temp_offs_done-number_increase_offs)) begin
            miss_offs_done = miss_offs_done + 1;
            if(RUN_UNTIL_FIRST_MISS) begin
                $display("%d-> OFFS Done doesn't match with expected. \t%d, got %d\n", general_counter, (temp_offs_done-number_increase_offs), tb_offs);
                statistic(1);
            end
        end else begin
            match_offs_done = match_offs_done + 1;
        end
    endfunction
    function void check_bitstream;
        case(tb_flag_bitstream)
            1 : begin       // It's gonna test only the bit_1 with bit_1
                if(tb_bit_1 != verify_bit_1[verify_read]) begin
                    miss_bit_1 = miss_bit_1 + 1;
                    if(RUN_UNTIL_FIRST_MISS) begin
                        $display("%d-> Bit 1 doesn't match with expected. \t%d, got %d\n", general_counter, verify_bit_1[verify_read], tb_bit_1);
                        statistic(1);
                    end
                end else begin
                    match_bit_1 = match_bit_1 + 1;
                end
            end
            3 : begin           // For this case, the values in the bitstream file are inverted
                if(tb_bit_1 != verify_bit_2[verify_read]) begin
                    miss_bit_1 = miss_bit_1 + 1;
                    if(RUN_UNTIL_FIRST_MISS) begin
                        $display("%d-> Bit 1 doesn't match with expected. \t%d, got %d\n", general_counter, verify_bit_2[verify_read], tb_bit_1);
                        statistic(1);
                    end
                end else begin
                    match_bit_1 = match_bit_1 + 1;
                end
                if(tb_bit_2 != verify_bit_1[verify_read]) begin
                    miss_bit_2 = miss_bit_2 + 1;
                    if(RUN_UNTIL_FIRST_MISS) begin
                        $display("%d-> Bit 2 doesn't match with expected. \t%d, got %d\n", general_counter, verify_bit_1[verify_read], tb_bit_2);
                        statistic(1);
                    end
                end else begin
                    match_bit_2 = match_bit_2 + 1;
                end
            end
            default : begin
                flag_zero = flag_zero + 1;
            end
        endcase
    endfunction
    function void finish_execution;
        check_bitstream();
        if(tb_range != verify_range[verify_read]) begin
            miss_counter_range = miss_counter_range + 1;
            if(RUN_UNTIL_FIRST_MISS) begin
                $display("%d-> Range doesn't match with expected. \t%d, got %d\n", general_counter, verify_range[verify_read], tb_range);
                statistic(2);
            end
        end else begin
            match_counter_range = match_counter_range + 1;
        end
        if(tb_low != verify_low[verify_read]) begin
            miss_counter_low = miss_counter_low + 1;
            if(RUN_UNTIL_FIRST_MISS) begin
                $display("%d-> Low doesn't match with expected. \t%d, got %d\n", general_counter, verify_low[verify_read], tb_low);
                statistic(2);
            end
        end else begin
            match_counter_low = match_counter_low + 1;
        end
        update_array_pointers();
    endfunction
    function void statistic;
        input int info_flag;        // This flag will define how the simulation was stopped
                                    // 0- normal stop
                                    // 1- forced stop by mismatch with data in the main simulation
                                    // 2- forced stop called by finish_execution function
                                    // 3- forced stop -> problem reading file
        case(info_flag)
            0 : $display("==============\nDone with simulation\n=============\n");
            1 : $display("==============\nSimulation Stopped: mismatch in the main execution\n=============\n");
            2 : $display("==============\nSimulation stopped: problem with finish_execution function\n=============\n");
            3 : $display("==============\nSimulation stopped: problem reading the file\n=============\n");
        endcase
        $display("Statistics:\n");
        $display("Total simulations: %d\nTotal matches: %d\nTotal misses: %d\nTotal resets: %d\n", general_counter, match_counter_low+match_counter_range, miss_counter_low+miss_counter_range, reset_counter);
        $display("-------------------\n");
        $display("Range: \n\tMatches: %d\n\tMisses: %d\n", match_counter_range, miss_counter_range);
        $display("-------------------\n");
        $display("Low: \n\tMatches: %d\n\tMisses: %d\n", match_counter_low, miss_counter_low);
        $display("-------------------\n");
        $display("Bitstream Statistics\n");
        $display("\t-> Flags zero: %d\n\t\t-> Bit 1 matches: %d\n\t\t-> Bit 2 matches: %d\n", flag_zero, match_bit_1, match_bit_2);
        $display("\t\t-> Bit 1 misses: %d\n\t\t-> Bit 2 misses: %d\n", miss_bit_1, miss_bit_2);
        $display("\t-> Number of offs bigger than the previous: %d\n", num_offs_greater);
        $display("\tDone inputs:\n\t\t-> Offs matches: %d\n\t\t-> Offs misses: %d\n", match_offs_done, miss_offs_done);
        $display("\t\t\t-> CNT matches: %d\n\t\t\t-> CNT Misses: %d\n", match_cnt_done, miss_cnt_done);
        $display("\t\t-> Low matches: %d\n\t\t-> Low misses: %d\n", match_low_done, miss_low_done);
        $display("-------------------\n");
        $timeformat(-9, 7, " s", 32);
        $display("Execution time: %t\n", $time);
        $display("==============\nStatistics completed\n=============\n");
        $fclose(main_file);
        $stop;
    endfunction
    function int run_simulation;
        status_main_file = $fscanf (main_file, "%d;%d;%d;%d;%d;%d;%d;%d;%d;%d;%d;\n", temp_bool, temp_init_range, temp_init_low, temp_fl, temp_fh, temp_symbol, temp_nsyms, temp_norm_in_rng, temp_norm_in_low, temp_range, temp_low);
        status_bitstream_file = $fscanf (bitstream_file, "%d;%d;\n", temp_bit_2, temp_bit_1);
        general_counter = general_counter + 1;
        if(status_bitstream_file != 2) begin
            $display("\t-> Problem reading the bitstream file\n-> Closing testbench\n");
            $stop;
        end
        if(status_main_file != 11) begin
            $display("\t-> Problem reading file: %d\n", general_counter);
            statistic(3);
        end
        else begin
            if((temp_init_low == 0) && (temp_init_range == 32768) && (temp_init_low != previous_low_out) && (temp_init_range != previous_range_out)) begin
                reset_counter = reset_counter + 1;
                $display("\t-> %d: Reset detected -> %d\n", general_counter, reset_counter);
                return 1;       // found a reset
            end else begin
                // reset detection: set the previous low and range to be used in the next execution
                previous_range_out = temp_range;
                previous_low_out = temp_low;
                // -----------------------------
                tb_bool = temp_bool;
                tb_fl = temp_fl;
                tb_fh = temp_fh;
                tb_symbol = temp_symbol;
                tb_nsyms = temp_nsyms;
                verify_bit_1[verify_save] = temp_bit_1;
                verify_bit_2[verify_save] = temp_bit_2;
                verify_range[verify_save] = temp_range;
                verify_low[verify_save] = temp_low;
                if(frame_counter > 2) begin
                    check_bitstream();
                    if(verify_range[verify_read] != tb_range) begin
                        miss_counter_range = miss_counter_range + 1;
                        if(RUN_UNTIL_FIRST_MISS) begin
                            $display("%d-> Range doesn't match with expected. \t%d, got %d\n", general_counter, verify_range[verify_read], tb_range);
                            statistic(1);
                        end
                    end else begin
                        match_counter_range = match_counter_range + 1;
                    end
                    if(verify_low[verify_read] != tb_low) begin
                        miss_counter_low = miss_counter_low + 1;
                        if(RUN_UNTIL_FIRST_MISS) begin
                            $display("%d-> Low doesn't match with expected. \t%d, got %d\n", general_counter, verify_low[verify_read], tb_low);
                            statistic(1);
                        end else begin
                            match_counter_low = match_counter_low + 1;
                        end
                    end
                end
                update_array_pointers();
            end
        end
        return 0;       // not reset
    endfunction



    initial begin
        $display("-> Starting testbench...\n");
        tb_clk <= 1'b0;
        $display("\t-> Clock set\n");
        open_file();
        if(main_file)  $display("\t-> File opened successfully\n");
        else begin
            $display("\t-> Unable to open the file\n");
            $stop;
        end
        $display("-> Configuration completed.\n");
        $display("-> Starting simulation...\n");
        reset_function(1);      // This function is called with 1 because it is the first execution (start_flag)
        #12ns;
        tb_reset <= 1'b0;
        #12ns;
        $display("\t-> Reset procedure completed\n");
        $display("\t-> Starting simulation loop\n");
        while(!$feof(main_file)) begin
            reset_sign_return = run_simulation();
            if(reset_sign_return) begin
                //$display("\t\t-> Finish previous simulation\n");
                for(i=0; i<2; i = i+1) begin
                    finish_execution();
                    #12ns;
                end
                //$display("\t\t-> Architecture empty\n");
                if(offs_previous < tb_offs)
                    num_offs_greater = num_offs_greater + 1;
                offs_previous = tb_offs;
                check_with_done_file();
                $display("\t\t-> Low: %d\n\t\t-> Offs: %d\n", tb_low, tb_offs);
                reset_function(0);      // set the flag to zero avoiding an entire reset
                #12ns;
                //$display("\t\t-> Setting the reset sign to 0\n");
                tb_reset <= 1'b0;
            end
            #12ns;
        end
        statistic(0);
    end
endmodule
