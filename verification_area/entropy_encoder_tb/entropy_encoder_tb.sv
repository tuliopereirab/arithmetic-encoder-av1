module entropy_encoder_tb #(
    parameter TB_BITSTREAM_WIDTH = 8,
    parameter TB_RANGE_WIDTH = 16,          // These parameters (lines 2 to 7) represent the architecture parameters
    parameter TB_LOW_WIDTH = 24,            // They must be changed ONLY IF THERE ARE CHANGES IN THE ARCHITECTURE
    parameter TB_SYMBOL_WIDTH = 4,          // Changing these parameters WILL NOT ensure a correct execution by the architecture
    parameter TB_LUT_ADDR_WIDTH = 8,        // All changes on these parameters must be analyzed before and change some internal defaults in the architecture
    parameter TB_LUT_DATA_WIDTH = 16,
    parameter TB_D_SIZE = 5,
    parameter SELECT_VIDEO = 0,         // 0- Miss America 150frames 176x144 (Entire Video)
                                        // 1- Akiyo 300frames 176x144 (Entire Video)
                                        // 2- Bowing 300frames (Entire Video)                   - Not available
                                        // 3- Carphone 382frames 176x144 (Entire Video)         - Not available
                                        // 4- Bus 150frames 352x288 (Entire Video)
    parameter RUN_UNTIL_FIRST_MISS = 1, // With this option in 1, the simulation will stop as soon as it gets the first miss
                                        // It doesn't matter if the miss is with Range or low
                                        // 0- Run until the end of the simulation and count misses and matches
                                        // 1- Stop when find the first miss
    parameter PIPELINE_STAGES = 4       // This variable defines the number of pipeline stages
                                        // If the pipeline changes, many things will need to change in the testbench
                                        // This variable will make it easier to change things here
    )();

    // File read variables
    int file_inputs, file_bitstream;
    int temp_fl, temp_fh, temp_symbol, temp_nsyms, temp_bool;   // inputs
    int temp_range, temp_low;               // verification variables (final numbers for low and range)
    int temp_init_range, temp_init_low;     // reset variables (verify is these variables are 32768 and 0, respectively)
    int temp_bitstream_1, temp_bitstream_2, temp_bitstream_3;
    int temp_norm_in_rng, temp_norm_in_low;
    int status;     // check if the file was correctly read
    // ---------------------------------
    int match_bitstream, miss_bitstream;
    int general_counter, reset_counter;
    int tb_flag_first_bitstream;
    // ---------------------------------
    // reset detection
    int previous_range_out, previous_low_out;
    int reset_sign_return;
    // ---------------------------------
    // Architecture "conversation" variables
    // Here are declared all variables representing the inputs and outputs of the architecture.
    // Setting the REG variables here will automatically set the architecture's input pins
    reg tb_clk, tb_reset, tb_input_flag_last, tb_out_flag_last;
    reg tb_bool;
    reg [(TB_RANGE_WIDTH-1):0] tb_fl, tb_fh;
    reg [(TB_SYMBOL_WIDTH-1):0] tb_symbol;
    reg [TB_SYMBOL_WIDTH:0] tb_nsyms;
    wire [(TB_BITSTREAM_WIDTH-1):0] tb_out_bit_1, tb_out_bit_2, tb_out_last_bit;
    wire [1:0] tb_out_flag_bitstream;

    // Architecture declaration
    entropy_encoder #(
        .TOP_RANGE_WIDTH (TB_RANGE_WIDTH),
        .TOP_LOW_WIDTH (TB_LOW_WIDTH),
        .TOP_SYMBOL_WIDTH (TB_SYMBOL_WIDTH),
        .TOP_LUT_ADDR_WIDTH (TB_LUT_ADDR_WIDTH),
        .TOP_LUT_DATA_WIDTH (TB_LUT_DATA_WIDTH),
        .TOP_BITSTREAM_WIDTH (TB_BITSTREAM_WIDTH),
        .TOP_D_SIZE (TB_D_SIZE)
        ) ent_enc (
            .top_clk (tb_clk),
            .top_reset (tb_reset),
            .top_final_flag (tb_input_flag_last),
            .top_fl (tb_fl),
            .top_fh (tb_fh),
            .top_symbol (tb_symbol),
            .top_nsyms (tb_nsyms),
            .top_bool (tb_bool),
            // outputs
            .OUT_BIT_1 (tb_out_bit_1),
            .OUT_BIT_2 (tb_out_bit_2),
            .OUT_LAST_BIT (tb_out_last_bit),
            .OUT_FLAG_BITSTREAM (tb_out_flag_bitstream),
            .OUT_FLAG_LAST (tb_out_flag_last)
        );

    always #6ns tb_clk <= ~tb_clk;      // Here is the Clock (clk) generator
                                        // It is set to execute in a 12ns period

    function void open_file;
        case(SELECT_VIDEO)
            0 : begin
                $display("\t-> Video selected: Miss America 150 frames 176x144 (Entire Video)\n");
                file_inputs = $fopen("C:/Users/Tulio/Desktop/arithmetic_encoder_av1/verification_area/simulation_data/entropy_encoder/miss-america_150frames_176x144_main_data.csv", "r");
                file_bitstream = $fopen("C:/Users/Tulio/Desktop/arithmetic_encoder_av1/verification_area/simulation_data/entropy_encoder/miss-america_150frames_176x144_final_bitstream.csv", "r");
            end
            1 : begin
                $display("\t-> Video selected: Akiyo 300 frames 176x144 (Entire Video)\n");
                file_inputs = $fopen("C:/Users/Tulio/Desktop/arithmetic_encoder_av1/verification_area/simulation_data/entropy_encoder/akiyo_300frames_176x144_main_data.csv", "r");
                file_bitstream = $fopen("C:/Users/Tulio/Desktop/arithmetic_encoder_av1/verification_area/simulation_data/entropy_encoder/akiyo_300frames_176x144_final_bitstream.csv", "r");
            end
            2 : begin
                $display("\t-> Video selected: Bowing 300frames (Entire Video)\n");
                $display("\t\t-> Video is currently not available.");
                $stop;
                // file_inputs = $fopen("C:/Users/Tulio/Desktop/arithmetic_encoder_av1/verification_area/simulation_data/entropy_encoder/.csv", "r");
                // file_bitstream = $fopen("C:/Users/Tulio/Desktop/arithmetic_encoder_av1/verification_area/simulation_data/entropy_encoder/.csv", "r");
            end
            3 : begin
                $display("\t-> Video selected: Carphone 382frames 176x144 (Entire Video)\n");
                $display("\t\t-> Video is currently not available.");
                $stop;
                //file_inputs = $fopen("C:/Users/Tulio/Desktop/arithmetic_encoder_av1/verification_area/simulation_data/entropy_encoder/.csv", "r");
                //file_bitstream = $fopen("C:/Users/Tulio/Desktop/arithmetic_encoder_av1/verification_area/simulation_data/entropy_encoder/.csv", "r");
            end
            4 : begin
                $display("\t-> Video selected: Bus 150frames 352x288 (Entire Video)\n");
                file_inputs = $fopen("C:/Users/Tulio/Desktop/arithmetic_encoder_av1/verification_area/simulation_data/entropy_encoder/bus_150frames_352x288_main_data.csv", "r");
                file_bitstream = $fopen("C:/Users/Tulio/Desktop/arithmetic_encoder_av1/verification_area/simulation_data/entropy_encoder/bus_150frames_352x288_final_bitstream.csv", "r");
            end
        endcase
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
        $display("Total simulations: %d\n\t-> Bitstream matches: %d\n\t-> Bitstream misses: %d\n\t-> Total resets: %d\n", general_counter, match_bitstream, miss_bitstream, reset_counter);
        $display("-------------------\n");
        $timeformat(-9, 7, " s", 32);
        $display("Execution time: %t\n", $time);
        $display("==============\nStatistics completed\n=============\n");
        $fclose(file_inputs);
        $fclose(file_bitstream);
        $stop;
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
            tb_flag_first_bitstream = 1;
            match_bitstream = 0;
            miss_bitstream = 0;
        end
        //$display("\t\t-> Resetting verification arrays\n");
        if(start_flag) begin
            $display("\t-> Reading first line of the file\n");
            status = $fscanf (file_inputs, "%d;%d;%d;%d;%d;%d;%d;%d;%d;%d;%d;\n", temp_bool, temp_init_range, temp_init_low, temp_fl, temp_fh, temp_symbol, temp_nsyms, temp_norm_in_rng, temp_norm_in_low, temp_range, temp_low);
            if(status != 11) begin
                $display("\t-> Problem reading the file\n-> Closing testbench\n");
                $stop;
            end else begin
                $display("\t\t-> Setting architecture inputs\n");
                tb_bool = temp_bool;
                tb_fl = temp_fl;
                tb_fh = temp_fh;
                tb_symbol = temp_symbol;
                tb_nsyms = temp_nsyms;
                tb_input_flag_last = 0;
                tb_reset <= 1'b1;
                $display("\t\t-> Saving verification arrays\n");
                $display("\t\t-> Updating pointers' values\n");
                general_counter = general_counter + 1;
            end
        end else begin
            tb_bool = temp_bool;
            tb_fl = temp_fl;
            tb_fh = temp_fh;
            tb_symbol = temp_symbol;
            tb_nsyms = temp_nsyms;
            tb_reset <= 1'b1;
        end
    endfunction

    function void check_bitstream;
        if(tb_flag_first_bitstream) begin
            tb_flag_first_bitstream = 0;        // The first bitstream will not be checked because it's gonna be ZERO
        end else begin
            case(tb_out_flag_bitstream)
                1 : begin        // 1 bitstream is going to be tested
                    status = $fscanf (file_bitstream, "%d;\n", temp_bitstream_1);
                    if(temp_bitstream_1 != tb_out_bit_1) begin
                        miss_bitstream = miss_bitstream + 1;
                        if(RUN_UNTIL_FIRST_MISS) begin
                            $display("%d -> Bitstream doesn't match with expected. \t%d, got %d\n", general_counter, temp_bitstream_1, tb_out_bit_1);
                            statistic(2);
                        end
                    end else begin
                        match_bitstream = match_bitstream + 1;
                    end
                end
                3 : begin           // 2 bitstream is going to be tested
                    status = $fscanf (file_bitstream, "%d;\n%d;\n", temp_bitstream_1, temp_bitstream_2);
                    if(temp_bitstream_1 != tb_out_bit_1) begin
                        miss_bitstream = miss_bitstream + 1;
                        if(RUN_UNTIL_FIRST_MISS) begin
                            $display("%d -> Bitstream doesn't match with expected. \t%d, got %d\n", general_counter, temp_bitstream_1, tb_out_bit_1);
                            statistic(2);
                        end
                    end else begin
                        match_bitstream = match_bitstream + 1;
                    end

                    if(temp_bitstream_2 != tb_out_bit_2) begin
                        miss_bitstream = miss_bitstream + 1;
                        if(RUN_UNTIL_FIRST_MISS) begin
                            $display("%d - 2 -> Bitstream doesn't match with expected. \t%d, got %d\n", general_counter, temp_bitstream_2, tb_out_bit_2);
                            statistic(2);
                        end
                    end else begin
                        match_bitstream = match_bitstream + 1;
                    end
                end
                2 : begin           // 3 bitstreams are going to be tested
                    status = $fscanf (file_bitstream, "%d;\n%d;\n%d;\n", temp_bitstream_1, temp_bitstream_2, temp_bitstream_3);
                    if(temp_bitstream_1 != tb_out_bit_1) begin
                        miss_bitstream = miss_bitstream + 1;
                        if(RUN_UNTIL_FIRST_MISS) begin
                            $display("%d -> Bitstream doesn't match with expected. \t%d, got %d\n", general_counter, temp_bitstream_1, tb_out_bit_1);
                            statistic(2);
                        end
                    end else begin
                        match_bitstream = match_bitstream + 1;
                    end

                    if(temp_bitstream_2 != tb_out_bit_2) begin
                        miss_bitstream = miss_bitstream + 1;
                        if(RUN_UNTIL_FIRST_MISS) begin
                            $display("%d - 2 -> Bitstream doesn't match with expected. \t%d, got %d\n", general_counter, temp_bitstream_2, tb_out_bit_2);
                            statistic(2);
                        end
                    end else begin
                        match_bitstream = match_bitstream + 1;
                    end

                    if(temp_bitstream_3 != tb_out_last_bit) begin
                        miss_bitstream = miss_bitstream + 1;
                        if(RUN_UNTIL_FIRST_MISS) begin
                            $display("%d - 3 -> Bitstream doesn't match with expected. \t%d, got %d\n", general_counter, temp_bitstream_3, tb_out_last_bit);
                            statistic(2);
                        end
                    end else begin
                        match_bitstream = match_bitstream + 1;
                    end
                end
            endcase
        end
    endfunction

    function int run_simulation;
        status = $fscanf (file_inputs, "%d;%d;%d;%d;%d;%d;%d;%d;%d;%d;%d;\n", temp_bool, temp_init_range, temp_init_low, temp_fl, temp_fh, temp_symbol, temp_nsyms, temp_norm_in_rng, temp_norm_in_low, temp_range, temp_low);
        general_counter = general_counter + 1;
        if(status != 11) begin
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
                tb_input_flag_last = 0;
                tb_bool = temp_bool;
                tb_fl = temp_fl;
                tb_fh = temp_fh;
                tb_symbol = temp_symbol;
                tb_nsyms = temp_nsyms;
            end
        end
        return 0;       // not reset
    endfunction

    initial begin
        $display("-> Starting testbench...\n");
        tb_clk <= 1'b0;
        $display("\t-> Clock set\n");
        open_file();
        if((file_inputs) && (file_bitstream))  $display("\t-> Files opened successfully\n");
        else begin
            $display("\t-> Unable to open at least one of the files\n");
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
        while(!$feof(file_inputs)) begin
            reset_sign_return = run_simulation();
            if(reset_sign_return) begin
                //$display("\t\t-> Finish previous simulation\n");
                tb_input_flag_last = 1;
                while(!tb_out_flag_last) begin
                    if(tb_out_flag_bitstream != 0) begin
                        check_bitstream();
                    end
                    #12ns;
                end
                //$display("\t\t-> Architecture empty\n");
                reset_function(0);      // set the flag to zero avoiding an entire reset
                #12ns;
                //$display("\t\t-> Setting the reset sign to 0\n");
                tb_reset <= 1'b0;
            end
            if(tb_out_flag_bitstream != 0) begin
                check_bitstream();
            end
            #12ns;
        end
        statistic(0);
    end
endmodule