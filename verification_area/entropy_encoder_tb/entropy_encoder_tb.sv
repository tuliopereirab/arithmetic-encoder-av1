module entropy_encoder_tb #(
    parameter TB_BITSTREAM_WIDTH = 8,
    parameter TB_RANGE_WIDTH = 16,          // These parameters (lines 2 to 7) represent the architecture parameters
    parameter TB_LOW_WIDTH = 24,            // They must be changed ONLY IF THERE ARE CHANGES IN THE ARCHITECTURE
    parameter TB_SYMBOL_WIDTH = 4,          // Changing these parameters WILL NOT ensure a correct execution by the architecture
    parameter TB_LUT_ADDR_WIDTH = 8,        // All changes on these parameters must be analyzed before and change some internal defaults in the architecture
    parameter TB_LUT_DATA_WIDTH = 16,
    parameter TB_D_SIZE = 5,
    parameter SELECT_CQ = 0,            // This config defines the CQ of the video to be executed
                                        // The SELECT_CQ is only valid when SELECT_VIDEO != -1
                                        // 0- cq55, 1- cq20
    parameter SELECT_VIDEO = -1,         // -1 - Run all videos
                                        // 0 - Beauty 1920x1080 120fps 420 8bit YUV
                                        // 1 - Bosphorus 1920x1080 120fps 420 8bit YUV
                                        // 2 - HoneyBee 1920x1080 120fps 420 8bit YUV
                                        // 3 - Jockey 1920x1080 120fps 420 8bit YUV
                                        // 4 - ReadySetGo 3840x2160 120fps 420 10bit YUV
                                        // 5 - YachtRide 3840x2160 120fps 420 10bit YUV
    parameter RUN_UNTIL_FIRST_MISS = 1, // With this option in 1, the simulation will stop as soon as it gets the first miss
                                        // It doesn't matter if the miss is with Range or low
                                        // 0- Run until the end of the simulation and count misses and matches
                                        // 1- Stop when find the first miss
    parameter PIPELINE_STAGES = 4,      // This variable defines the number of pipeline stages
                                        // If the pipeline changes, many things will need to change in the testbench
                                        // This variable will make it easier to change things here
    parameter GENERATE_OUTPUT_FILE = 0  // By setting this parameter to 1, an output file will be generated
                                        // The file will be composed only by the output bitstreams
                                        // 0- do not generate the file; 1- generate the file
    )();

    // File read variables
    int file_inputs, file_bitstream, file_output;
    int temp_fl, temp_fh, temp_symbol, temp_nsyms, temp_bool;   // inputs
    int temp_range, temp_low;               // verification variables (final numbers for low and range)
    int temp_init_range, temp_init_low;     // reset variables (verify is these variables are 32768 and 0, respectively)
    int temp_bitstream_1, temp_bitstream_2, temp_bitstream_3, temp_bitstream_4;
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
    reg tb_clk, tb_reset, tb_input_flag_last, tb_out_flag_last, tb_flag_first;
    reg tb_bool;
    reg [(TB_RANGE_WIDTH-1):0] tb_fl, tb_fh;
    reg [(TB_SYMBOL_WIDTH-1):0] tb_symbol;
    reg [TB_SYMBOL_WIDTH:0] tb_nsyms;
    wire [(TB_BITSTREAM_WIDTH-1):0] tb_out_bit_1, tb_out_bit_2, tb_out_last_bit, tb_out_bit_3;
    wire [2:0] tb_out_flag_bitstream;
    wire tb_error_detection;

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
            .top_flag_first (tb_flag_first),
            .top_final_flag (tb_input_flag_last),
            .top_fl (tb_fl),
            .top_fh (tb_fh),
            .top_symbol (tb_symbol),
            .top_nsyms (tb_nsyms),
            .top_bool (tb_bool),
            // outputs
            .OUT_BIT_1 (tb_out_bit_1),
            .OUT_BIT_2 (tb_out_bit_2),
            .OUT_BIT_3 (tb_out_bit_3),
            .OUT_LAST_BIT (tb_out_last_bit),
            .OUT_FLAG_BITSTREAM (tb_out_flag_bitstream),
            .OUT_FLAG_LAST (tb_out_flag_last),
            .ERROR_INDICATION (tb_error_detection)
        );

    always #1ns tb_clk <= ~tb_clk;      // Here is the Clock (clk) generator
                                        // It is set to execute in a 12ns period

    function string get_video_name;
        input video_id;
        case(video_id)
            0 : return "Beauty 1920x1080 120fps 420 8bit YUV";
            1 : return "Bosphorus 1920x1080 120fps 420 8bit YUV";
            2 : return "HoneyBee_1920x1080_120fps_420_8bit_YUV";
            3 : return "Jockey 1920x1080 120fps 420 8bit YUV";
            4 : return "ReadySetGo 3840x2160 120fps 420 10bit YUV";
            5 : return "YachtRide 3840x2160 120fps 420 10bit YUV";
            default : return "invalid id";
        endcase
    endfunction


    function void open_file;
        input int cq_id, video_id;
        string path, output_path, cq;
        string bitstream_sufix, main_sufix, output_sufix;
        string inputs_path, bitstream_path, video_file_name;
        path = "F:/y4m_files/generated_files/";
        output_path = "C:/Users/Tulio/Desktop/arithmetic_encoder_av1/verification_area/entropy_encoder_tb/Output_Files/";
        if(cq_id)   // with cq_id in 1, uses cq = 20
            cq = "20";
        else
            cq = "55";
        bitstream_sufix = "_final_bitstream.csv";
        main_sufix = "_main_data.csv";
        output_sufix = "_output.csv";
        $display("\t-> Video selected: %s\n", get_video_name(video_id));
        case(video_id)
            0 : begin
                $display("\t-> Video selected: Beauty 1920x1080 120fps 420 8bit YUV\n");
                video_file_name = "Beauty_1920x1080_120fps_420_8bit_YUV";
                inputs_path = {path, "cq_", cq, "/", video_file_name, "_cq", cq, main_sufix};
                bitstream_path = {path, "cq_", cq, "/", video_file_name, "_cq", cq, bitstream_sufix};
                output_path = {output_path, video_file_name, ".csv"};
            end
            1 : begin
                video_file_name = "Bosphorus_1920x1080_120fps_420_8bit_YUV";
                inputs_path = {path, "cq_", cq, "/", video_file_name, "_cq", cq, main_sufix};
                bitstream_path = {path, "cq_", cq, "/", video_file_name, "_cq", cq, bitstream_sufix};
                output_path = {output_path, video_file_name, ".csv"};
            end
            2 : begin
                video_file_name = "HoneyBee_1920x1080_120fps_420_8bit_YUV";
                inputs_path = {path, "cq_", cq, "/", video_file_name, "_cq", cq, main_sufix};
                bitstream_path = {path, "cq_", cq, "/", video_file_name, "_cq", cq, bitstream_sufix};
                output_path = {output_path, video_file_name, ".csv"};
            end
            3 : begin
                video_file_name = "Jockey_1920x1080_120fps_420_8bit_YUV";
                inputs_path = {path, "cq_", cq, "/", video_file_name, "_cq", cq, main_sufix};
                bitstream_path = {path, "cq_", cq, "/", video_file_name, "_cq", cq, bitstream_sufix};
                output_path = {output_path, video_file_name, ".csv"};
            end
            4 : begin
                video_file_name = "ReadySetGo_3840x2160_120fps_420_10bit_YUV";
                inputs_path = {path, "cq_", cq, "/", video_file_name, "_cq", cq, main_sufix};
                bitstream_path = {path, "cq_", cq, "/", video_file_name, "_cq", cq, bitstream_sufix};
                output_path = {output_path, video_file_name, ".csv"};
            end
            5 : begin
                video_file_name = "YachtRide_3840x2160_120fps_420_10bit_YUV";
                inputs_path = {path, "cq_", cq, "/", video_file_name, "_cq", cq, main_sufix};
                bitstream_path = {path, "cq_", cq, "/", video_file_name, "_cq", cq, bitstream_sufix};
                output_path = {output_path, video_file_name, ".csv"};
            end
            6 : begin
                $display("\t-> Video selected: Invalid Video ID\n");
                $stop;
                video_file_name = "";
                inputs_path = {path, "cq_", cq, "/", video_file_name, "_cq", cq, main_sufix};
                bitstream_path = {path, "cq_", cq, "/", video_file_name, "_cq", cq, bitstream_sufix};
                output_path = {output_path, video_file_name, ".csv"};
            end
            7 : begin
                $stop;
                video_file_name = "";
                inputs_path = {path, "cq_", cq, "/", video_file_name, "_cq", cq, main_sufix};
                bitstream_path = {path, "cq_", cq, "/", video_file_name, "_cq", cq, bitstream_sufix};
                output_path = {output_path, video_file_name, ".csv"};
            end
            8 : begin
                $stop;
                video_file_name = "";
                inputs_path = {path, "cq_", cq, "/", video_file_name, "_cq", cq, main_sufix};
                bitstream_path = {path, "cq_", cq, "/", video_file_name, "_cq", cq, bitstream_sufix};
                output_path = {output_path, video_file_name, ".csv"};
            end
            9 : begin
                $stop;
                video_file_name = "";
                inputs_path = {path, "cq_", cq, "/", video_file_name, "_cq", cq, main_sufix};
                bitstream_path = {path, "cq_", cq, "/", video_file_name, "_cq", cq, bitstream_sufix};
                output_path = {output_path, video_file_name, ".csv"};
            end
            10 : begin
                $stop;
                video_file_name = "";
                inputs_path = {path, "cq_", cq, "/", video_file_name, "_cq", cq, main_sufix};
                bitstream_path = {path, "cq_", cq, "/", video_file_name, "_cq", cq, bitstream_sufix};
                output_path = {output_path, video_file_name, ".csv"};
            end
            11 : begin
                $stop;
                video_file_name = "";
                inputs_path = {path, "cq_", cq, "/", video_file_name, "_cq", cq, main_sufix};
                bitstream_path = {path, "cq_", cq, "/", video_file_name, "_cq", cq, bitstream_sufix};
                output_path = {output_path, video_file_name, ".csv"};
            end
            12 : begin
                $stop;
                video_file_name = "";
                inputs_path = {path, "cq_", cq, "/", video_file_name, "_cq", cq, main_sufix};
                bitstream_path = {path, "cq_", cq, "/", video_file_name, "_cq", cq, bitstream_sufix};
                output_path = {output_path, video_file_name, ".csv"};
            end
            13 : begin
                $stop;
                video_file_name = "";
                inputs_path = {path, "cq_", cq, "/", video_file_name, "_cq", cq, main_sufix};
                bitstream_path = {path, "cq_", cq, "/", video_file_name, "_cq", cq, bitstream_sufix};
                output_path = {output_path, video_file_name, ".csv"};
            end
            default : begin
                $stop;
            end
        endcase
        file_inputs = $fopen(inputs_path, "r");
        file_bitstream = $fopen(bitstream_path, "r");
        if(GENERATE_OUTPUT_FILE) begin
            file_output = $fopen(output_path, "w+");
            $display("\t-> Config: generating output file.\n");
        end
    endfunction

    function void add_line_output_file;
        case(tb_out_flag_bitstream)
            1 : begin           // 1 bitstream will be added to the file
                if(!tb_flag_first_bitstream)
                    $fdisplay(file_output, "%0d;", tb_out_bit_1);
            end
            3 : begin           // 2 bitstream will be added to the file
                if(!tb_flag_first_bitstream)
                    $fdisplay(file_output, "%0d;", tb_out_bit_1);
                $fdisplay(file_output, "%0d;", tb_out_bit_2);
            end
            2 : begin           // 3 bitstreams will be added to the file
                if(!tb_flag_first_bitstream)
                    $fdisplay(file_output, "%0d;", tb_out_bit_1);
                $fdisplay(file_output, "%0d;", tb_out_bit_2);
                $fdisplay(file_output, "%0d;", tb_out_bit_3);
            end
            4 : begin           // 4 bitstreams will be added to the file
                if(!tb_flag_first_bitstream)
                    $fdisplay(file_output, "%0d;", tb_out_bit_1);
                $fdisplay(file_output, "%0d;", tb_out_bit_2);
                $fdisplay(file_output, "%0d;", tb_out_bit_3);
                $fdisplay(file_output, "%0d;", tb_out_last_bit);
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
            4 : $display("==============\nSimulation stopped: Error detected by the Architecture\n=============");
        endcase
        $display("Statistics:\n");
        $display("Total simulations: %d\n\t-> Bitstream matches: %d\n\t-> Bitstream misses: %d\n\t-> Total resets: %d\n", general_counter, match_bitstream, miss_bitstream, reset_counter);
        $display("-------------------\n");
        $timeformat(-3, 2, " ms", 32);
        $display("Execution time: %t\n", $time);
        $display("==============\nStatistics completed\n=============\n");
        $fclose(file_inputs);
        $fclose(file_bitstream);
        if(GENERATE_OUTPUT_FILE)
            $fclose(file_output);
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
                tb_flag_first = 1;
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
            tb_flag_first = 1;
            tb_reset <= 1'b1;
        end
    endfunction

    function void print_problem;
        input int count, flag_num, special, bitstream_num, expected, got;
        string special_str;
        if(special)
            special_str = "Special";
        else
            special_str = "";
        $display("Video: %s\n", get_video_name(current_video_id));
        $display("%d - Flag %d %s - Bitstream %d -> Bitstream doesn't match with expected. \t%d, got %d\n", count, flag_num, special_str, bitstream_num, expected, got);
        statistic(2);
    endfunction

    function void check_bitstream;
        if(tb_flag_first_bitstream) begin
            tb_flag_first_bitstream = 0;        // The first bitstream will not be checked because it's gonna be ZERO
            case(tb_out_flag_bitstream)     // In case the first bitstream comes followed by more bitstreams at the same time, this part of the code will be executed
                3 : begin                   // It will ignore the first bitstream and test the following bitstreams
                    status = $fscanf (file_bitstream, "%d;\n", temp_bitstream_2);
                    if(temp_bitstream_2 != tb_out_bit_2) begin
                        miss_bitstream = miss_bitstream + 1;
                        if(RUN_UNTIL_FIRST_MISS) begin
                            print_problem(general_counter, tb_out_flag_bitstream, 1, 4, temp_bitstream_2, tb_out_bit_2);
                            statistic(2);
                        end
                    end else begin
                        match_bitstream = match_bitstream + 1;
                    end
                end
                2 : begin
                    status = $fscanf (file_bitstream, "%d;\n%d;\n", temp_bitstream_2, temp_bitstream_3);
                    if(temp_bitstream_2 != tb_out_bit_2) begin
                        miss_bitstream = miss_bitstream + 1;
                        if(RUN_UNTIL_FIRST_MISS) begin
                            print_problem(general_counter, tb_out_flag_bitstream, 1, 4, temp_bitstream_2, tb_out_bit_2);
                            statistic(2);
                        end
                    end else begin
                        match_bitstream = match_bitstream + 1;
                    end

                    if(temp_bitstream_3 != tb_out_bit_3) begin
                        miss_bitstream = miss_bitstream + 1;
                        if(RUN_UNTIL_FIRST_MISS) begin
                            print_problem(general_counter, tb_out_flag_bitstream, 1, 4, temp_bitstream_3, tb_out_bit_3);
                            statistic(2);
                        end
                    end else begin
                        match_bitstream = match_bitstream + 1;
                    end
                end
                4 : begin
                    status = $fscanf (file_bitstream, "%d;\n%d;\n%d;\n", temp_bitstream_2, temp_bitstream_3, temp_bitstream_4);
                    if(temp_bitstream_2 != tb_out_bit_2) begin
                        miss_bitstream = miss_bitstream + 1;
                        if(RUN_UNTIL_FIRST_MISS) begin
                            print_problem(general_counter, tb_out_flag_bitstream, 1, 4, temp_bitstream_2, tb_out_bit_2);
                            statistic(2);
                        end
                    end else begin
                        match_bitstream = match_bitstream + 1;
                    end

                    if(temp_bitstream_3 != tb_out_bit_3) begin
                        miss_bitstream = miss_bitstream + 1;
                        if(RUN_UNTIL_FIRST_MISS) begin
                            print_problem(general_counter, tb_out_flag_bitstream, 1, 4, temp_bitstream_3, tb_out_bit_3);
                            statistic(2);
                        end
                    end else begin
                        match_bitstream = match_bitstream + 1;
                    end

                    if(temp_bitstream_4 != tb_out_last_bit) begin
                        miss_bitstream = miss_bitstream + 1;
                        if(RUN_UNTIL_FIRST_MISS) begin
                            print_problem(general_counter, tb_out_flag_bitstream, 1, 4, temp_bitstream_4, tb_out_last_bit);
                            statistic(2);
                        end
                    end else begin
                        match_bitstream = match_bitstream + 1;
                    end
                end
            endcase
        end else begin
            case(tb_out_flag_bitstream)
                1 : begin        // 1 bitstream is going to be tested
                    status = $fscanf (file_bitstream, "%d;\n", temp_bitstream_1);
                    if(temp_bitstream_1 != tb_out_bit_1) begin
                        miss_bitstream = miss_bitstream + 1;
                        if(RUN_UNTIL_FIRST_MISS) begin
                            print_problem(general_counter, tb_out_flag_bitstream, 0, 1, temp_bitstream_1, tb_out_bit_1);
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
                            print_problem(general_counter, tb_out_flag_bitstream, 0, 1, temp_bitstream_1, tb_out_bit_1);
                            statistic(2);
                        end
                    end else begin
                        match_bitstream = match_bitstream + 1;
                    end

                    if(temp_bitstream_2 != tb_out_bit_2) begin
                        miss_bitstream = miss_bitstream + 1;
                        if(RUN_UNTIL_FIRST_MISS) begin
                            print_problem(general_counter, tb_out_flag_bitstream, 0, 2, temp_bitstream_2, tb_out_bit_2);
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
                            print_problem(general_counter, tb_out_flag_bitstream, 0, 1, temp_bitstream_1, tb_out_bit_1);
                            statistic(2);
                        end
                    end else begin
                        match_bitstream = match_bitstream + 1;
                    end

                    if(temp_bitstream_2 != tb_out_bit_2) begin
                        miss_bitstream = miss_bitstream + 1;
                        if(RUN_UNTIL_FIRST_MISS) begin
                            print_problem(general_counter, tb_out_flag_bitstream, 0, 2, temp_bitstream_2, tb_out_bit_2);
                            statistic(2);
                        end
                    end else begin
                        match_bitstream = match_bitstream + 1;
                    end

                    if(temp_bitstream_3 != tb_out_bit_3) begin
                        miss_bitstream = miss_bitstream + 1;
                        if(RUN_UNTIL_FIRST_MISS) begin
                            print_problem(general_counter, tb_out_flag_bitstream, 0, 3, temp_bitstream_3, tb_out_bit_3);
                            statistic(2);
                        end
                    end else begin
                        match_bitstream = match_bitstream + 1;
                    end
                end
                4 : begin           // 3 bitstreams are going to be tested
                    status = $fscanf (file_bitstream, "%d;\n%d;\n%d;\n%d;\n", temp_bitstream_1, temp_bitstream_2, temp_bitstream_3, temp_bitstream_4);
                    if(temp_bitstream_1 != tb_out_bit_1) begin
                        miss_bitstream = miss_bitstream + 1;
                        if(RUN_UNTIL_FIRST_MISS) begin
                            print_problem(general_counter, tb_out_flag_bitstream, 0, 1, temp_bitstream_1, tb_out_bit_1);
                            statistic(2);
                        end
                    end else begin
                        match_bitstream = match_bitstream + 1;
                    end

                    if(temp_bitstream_2 != tb_out_bit_2) begin
                        miss_bitstream = miss_bitstream + 1;
                        if(RUN_UNTIL_FIRST_MISS) begin
                            print_problem(general_counter, tb_out_flag_bitstream, 0, 2, temp_bitstream_2, tb_out_bit_2);
                            statistic(2);
                        end
                    end else begin
                        match_bitstream = match_bitstream + 1;
                    end

                    if(temp_bitstream_3 != tb_out_bit_3) begin
                        miss_bitstream = miss_bitstream + 1;
                        if(RUN_UNTIL_FIRST_MISS) begin
                            print_problem(general_counter, tb_out_flag_bitstream, 0, 3, temp_bitstream_3, tb_out_bit_3);
                            statistic(2);
                        end
                    end else begin
                        match_bitstream = match_bitstream + 1;
                    end

                    if(temp_bitstream_4 != tb_out_last_bit) begin
                        miss_bitstream = miss_bitstream + 1;
                        if(RUN_UNTIL_FIRST_MISS) begin
                            print_problem(general_counter, tb_out_flag_bitstream, 0, 4, temp_bitstream_4, tb_out_last_bit);
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
            if((temp_init_low == 0) && (temp_init_range == 32768) && ((temp_init_low != previous_low_out) || (temp_init_range != previous_range_out))) begin
                reset_counter = reset_counter + 1;
                $display("\t%d: %s \t-> %d: Reset detected -> %d\n", current_video_id, get_video_name(current_video_id), general_counter, reset_counter);
                return 1;       // found a reset
            end else begin
                // reset detection: set the previous low and range to be used in the next execution
                previous_range_out = temp_range;
                previous_low_out = temp_low;
                // -----------------------------
                tb_input_flag_last = 0;
                tb_flag_first = 0;
                tb_bool = temp_bool;
                tb_fl = temp_fl;
                tb_fh = temp_fh;
                tb_symbol = temp_symbol;
                tb_nsyms = temp_nsyms;
            end
        end
        return 0;       // not reset
    endfunction

    int current_video_id, current_video_cq;

    initial begin
        $display("-> Starting testbench...\n");
        tb_clk <= 1'b0;
        $display("\t-> Clock set\n");
        if(SELECT_VIDEO == -1) begin
            $display("\t->\tRunning all videos!\t<-\n");
            current_video_id = 0;
            current_video_cq = 0;
        end else begin
            $display("\t->\tRunning only video %d!\t<-\n", SELECT_VIDEO);
            current_video_id = SELECT_VIDEO;
            current_video_cq = SELECT_CQ;
        end
        while(current_video_cq <= 1) begin
            while(current_video_id <= 5) begin
                open_file(current_video_cq, current_video_id);    // cq (1 for 20 and 0 for 55), video id
                if((file_inputs) && (file_bitstream))  $display("\t-> Files opened successfully\n");
                else begin
                    $display("\t-> Unable to open at least one of the files\n");
                    $stop;
                end
                $display("-> Configuration completed.\n");
                $display("-> Starting simulation...\n");
                reset_function(1);      // This function is called with 1 because it is the first execution (start_flag)
                #2ns;
                tb_reset <= 1'b0;
                #2ns;
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
                                if(tb_error_detection) begin
                                    statistic(4);
                                end
                            end
                            #2ns;
                        end
                        if(tb_out_flag_bitstream != 0) begin            // When it finds the LAST FLAG, there's still one set of bitstream to come out
                            if(GENERATE_OUTPUT_FILE)
                                add_line_output_file();
                            check_bitstream();                          // This if is able to get this last set of bitstream
                            // if(tb_error_detection) begin                // Analyze it, as always, and more forward to the reset
                            //     statistic(4);
                            // end
                        end
                        #2ns;      // It is necessary to give time for the check_bitstream function to properly verify the output
                        //$display("\t\t-> Architecture empty\n");
                        reset_function(0);      // set the flag to zero avoiding an entire reset
                        tb_flag_first_bitstream = 1;        // Tells the TB to don't consider the first bitstream after the reset.
                        #2ns;
                        //$display("\t\t-> Setting the reset sign to 0\n");
                        tb_reset <= 1'b0;
                    end
                    if(tb_out_flag_bitstream != 0) begin
                        if(GENERATE_OUTPUT_FILE)
                            add_line_output_file();
                        check_bitstream();
                    end
                    // if(tb_error_detection) begin
                    //     statistic(4);
                    // end
                    #2ns;
                end
                if(SELECT_VIDEO == -1)
                    current_video_id = current_video_id + 1;
                else
                    statistic(0);
            end
            current_video_cq = current_video_cq + 1;
        end
        statistic(0);
    end
endmodule
