module tb_carry_propagation #(
    parameter TB_RANGE_WIDTH = 16,
    parameter TB_LOW_WIDTH = 24,
    parameter TB_SYMBOL_WIDTH = 4,
    parameter TB_LUT_ADDR_WIDTH = 8,
    parameter TB_LUT_DATA_WIDTH = 16,
    parameter TB_BITSTREAM_WIDTH = 8,
    parameter TB_D_SIZE = 5,
    parameter TB_ADDR_CARRY_WIDTH = 4
    ) ();
    // architecture's connections
    // inputs
    reg tb_clk, tb_reset;
    reg tb_flag_first, tb_flag_final, tb_flag_final_2_3;
    reg [(TB_RANGE_WIDTH-1):0] tb_range, tb_arith_bitstream_1, tb_arith_bitstream_2, tb_arith_offs;
    reg [1:0] tb_arith_flag;
    reg [(TB_D_SIZE-1):0] tb_cnt;
    reg [(TB_LOW_WIDTH-1):0] tb_low;
    // outputs
    wire tb_out_flag_last, tb_error;
    wire [(TB_BITSTREAM_WIDTH-1):0] tb_out_bitstream_1, tb_out_bitstream_2, tb_out_bitstream_3, tb_out_bitstream_4, tb_out_bitstream_5;
    wire [2:0] tb_out_flag;

    // Interval variables Testbench
    int first_output, i, first_input;
    int expected_result[16];
    int read_pointer, write_pointer;    // both pointers will point to a position in the array expected_result

    // monitor variables
    int check_counter;


    stage_4 #(
        .S4_RANGE_WIDTH (TB_RANGE_WIDTH),
        .S4_LOW_WIDTH (TB_LOW_WIDTH),
        .S4_SYMBOL_WIDTH (TB_SYMBOL_WIDTH),
        .S4_LUT_ADDR_WIDTH (TB_LUT_ADDR_WIDTH),
        .S4_LUT_DATA_WIDTH (TB_LUT_DATA_WIDTH),
        .S4_BITSTREAM_WIDTH (TB_BITSTREAM_WIDTH),
        .S4_D_SIZE (TB_D_SIZE),
        .S4_ADDR_CARRY_WIDTH (TB_ADDR_CARRY_WIDTH)
        ) state_pipeline_4 (
            .s4_clk (tb_clk),
            .s4_reset (tb_reset),
            .s4_flag_first (tb_flag_first),
            .s4_final_flag (tb_flag_final),
            .s4_final_flag_2_3 (tb_flag_final_2_3),
            .in_arith_bitstream_1 (tb_arith_bitstream_1),
            .in_arith_bitstream_2 (tb_arith_bitstream_2),
            .in_arith_range (tb_range),
            .in_arith_cnt (tb_cnt),
            .in_arith_low (tb_low),
            .in_arith_flag (tb_arith_flag),
            // outputs
            .out_carry_bit_1 (tb_out_bitstream_1),
            .out_carry_bit_2 (tb_out_bitstream_2),
            .out_carry_bit_3 (tb_out_bitstream_3),
            .out_carry_bit_4 (tb_out_bitstream_4),
            .out_carry_bit_5 (tb_out_bitstream_5),
            .out_carry_flag_bitstream (tb_out_flag),
            .output_flag_last (tb_out_flag_last)
        );

    function int generate_value;
        input int max;      // 511 for bitstream and 3 for flag
        return $urandom_range(0, max);
    endfunction

    function int update_pointer;
        input int pointer;
        if((pointer+1) >= 16)
            return 0;
        else
            return pointer+1;
    endfunction
    function int previous_pointer;
        input int pointer;
        if(pointer == 0)
            return 15;
        else
            return pointer-1;
    endfunction

    function void stop_execution;
        input int bitstream, flag, expected, got;
        $display("Error: Bitstream %0d, Flag %0d\t expected %0d, got %0d\n", bitstream, flag, expected, got);
        $stop;
    endfunction

    function void check;
        case(tb_out_flag)
            1 : begin       // check bitstream 1
                if(expected_result[read_pointer] != tb_out_bitstream_1) begin
                    stop_execution(1, 1, expected_result[read_pointer], tb_out_bitstream_1);
                end else begin
                    read_pointer = update_pointer(read_pointer);
                end
            end
            2 : begin       // check_bitstream 1 and 2
                if(expected_result[read_pointer] != tb_out_bitstream_1) begin
                    stop_execution(1, 3, expected_result[read_pointer], tb_out_bitstream_1);
                end else begin
                    read_pointer = update_pointer(read_pointer);
                end

                if(expected_result[read_pointer] != tb_out_bitstream_2)
                    stop_execution(2, 3, expected_result[read_pointer], tb_out_bitstream_2);
                else
                    read_pointer = update_pointer(read_pointer);
            end
            3 : begin       // check bitstream 1, 2 and 3
                if(expected_result[read_pointer] != tb_out_bitstream_1) begin
                    stop_execution(1, 2, expected_result[read_pointer], tb_out_bitstream_1);
                end else begin
                    read_pointer = update_pointer(read_pointer);
                end

                if(expected_result[read_pointer] != tb_out_bitstream_2)
                    stop_execution(2, 2, expected_result[read_pointer], tb_out_bitstream_2);
                else
                    read_pointer = update_pointer(read_pointer);

                if(expected_result[read_pointer] != tb_out_bitstream_3)
                    stop_execution(3, 2, expected_result[read_pointer], tb_out_bitstream_3);
                else
                    read_pointer = update_pointer(read_pointer);
            end
            4 : begin       // check bitstream 1, 2, 3 and last
                if(expected_result[read_pointer] != tb_out_bitstream_1) begin
                    stop_execution(1, 4, expected_result[read_pointer], tb_out_bitstream_1);
                end else begin
                    read_pointer = update_pointer(read_pointer);
                end

                if(expected_result[read_pointer] != tb_out_bitstream_2)
                    stop_execution(2, 4, expected_result[read_pointer], tb_out_bitstream_2);
                else
                    read_pointer = update_pointer(read_pointer);

                if(expected_result[read_pointer] != tb_out_bitstream_3)
                    stop_execution(3, 4, expected_result[read_pointer], tb_out_bitstream_3);
                else
                    read_pointer = update_pointer(read_pointer);

                if(expected_result[read_pointer] != tb_out_bitstream_4)
                    stop_execution(4, 4, expected_result[read_pointer], tb_out_bitstream_4);
                else
                    read_pointer = update_pointer(read_pointer);
            end
            5 : begin
                if(expected_result[read_pointer] != tb_out_bitstream_1) begin
                    stop_execution(1, 5, expected_result[read_pointer], tb_out_bitstream_1);
                end else begin
                    read_pointer = update_pointer(read_pointer);
                end
                for(i = 0; i < tb_out_bitstream_3; i = i + 1) begin
                    if(expected_result[read_pointer] != tb_out_bitstream_2) begin
                        stop_execution(2, 5, expected_result[read_pointer], tb_out_bitstream_2);
                    end else begin
                        read_pointer = update_pointer(read_pointer);
                    end
                end
            end
            6 : begin
                if(expected_result[read_pointer] != tb_out_bitstream_1) begin
                    stop_execution(1, 6, expected_result[read_pointer], tb_out_bitstream_1);
                end else begin
                    read_pointer = update_pointer(read_pointer);
                end
                for(i = 0; i < tb_out_bitstream_3; i = i + 1) begin
                    if(expected_result[read_pointer] != tb_out_bitstream_2) begin
                        stop_execution(2, 6, expected_result[read_pointer], tb_out_bitstream_2);
                    end else begin
                        read_pointer = update_pointer(read_pointer);
                    end
                end
                if(expected_result[read_pointer] != tb_out_bitstream_4) begin
                    stop_execution(4, 6, expected_result[read_pointer], tb_out_bitstream_4);
                end else begin
                    read_pointer = update_pointer(read_pointer);
                end
            end
            7 : begin
                if(expected_result[read_pointer] != tb_out_bitstream_1) begin
                    stop_execution(1, 7, expected_result[read_pointer], tb_out_bitstream_1);
                end else begin
                    read_pointer = update_pointer(read_pointer);
                end
                for(i = 0; i < tb_out_bitstream_3; i = i + 1) begin
                    if(expected_result[read_pointer] != tb_out_bitstream_2) begin
                        stop_execution(2, 7, expected_result[read_pointer], tb_out_bitstream_2);
                    end else begin
                        read_pointer = update_pointer(read_pointer);
                    end
                end
                if(expected_result[read_pointer] != tb_out_bitstream_4) begin
                    stop_execution(4, 7, expected_result[read_pointer], tb_out_bitstream_4);
                end else begin
                    read_pointer = update_pointer(read_pointer);
                end
                if(expected_result[read_pointer] != tb_out_bitstream_5) begin
                    stop_execution(5, 7, expected_result[read_pointer], tb_out_bitstream_5);
                end else begin
                    read_pointer = update_pointer(read_pointer);
                end
            end
            default : begin
                $display("Wrong flag coming from DUT!\n");
                $stop;
            end
        endcase
    endfunction

    function void propagate_carry;
        input int aux_pointer;
        aux_pointer = previous_pointer(aux_pointer);
        expected_result[aux_pointer] = expected_result[aux_pointer] + 1;
        while(expected_result[aux_pointer] > 255) begin
            expected_result[aux_pointer] = expected_result[aux_pointer] - 256;
            aux_pointer = previous_pointer(aux_pointer);
            expected_result[aux_pointer] = expected_result[aux_pointer] + 1;
        end
    endfunction

    function void add_value;
        int aux_pointer;
        case(tb_arith_flag)
            1 : begin
                aux_pointer = write_pointer;
                expected_result[write_pointer] = tb_arith_bitstream_1[(TB_BITSTREAM_WIDTH-1):0];    // save only the 8:0
                write_pointer = update_pointer(write_pointer);
                if(tb_arith_bitstream_1 > 255) begin
                    propagate_carry(aux_pointer);
                end
            end
            2 : begin
                aux_pointer = write_pointer;
                expected_result[write_pointer] = tb_arith_bitstream_1[(TB_BITSTREAM_WIDTH-1):0];    // save only the 8:0
                write_pointer = update_pointer(write_pointer);
                if(tb_arith_bitstream_1 > 255)
                    propagate_carry(aux_pointer);

                aux_pointer = write_pointer;
                expected_result[write_pointer] = tb_arith_bitstream_2[(TB_BITSTREAM_WIDTH-1):0];    // save only the 8:0
                write_pointer = update_pointer(write_pointer);
                if(tb_arith_bitstream_2 > 255)
                    propagate_carry(aux_pointer);
            end
            default : begin
                $display("Wrong flag generated.\n");
                $stop;
            end
        endcase
    endfunction

    always #2ns tb_clk <= ~tb_clk;

    initial begin
    // This initial begin will generate stuff and set the inputs
        tb_clk = 0;
        write_pointer = 0;
        first_input = 1;
        // first input
        tb_arith_bitstream_1 = 0;
        tb_arith_bitstream_2 = 0;
        tb_arith_flag = 0;
        tb_reset = 1;
        tb_flag_final = 0;
        tb_flag_final_2_3 = 0;
        tb_range = 0;
        tb_low = 0;
        tb_arith_offs = 0;
        tb_cnt = 0;
        #4ns;
        tb_reset = 0;
        tb_flag_first = 1;
        tb_arith_flag = 0;
        #4ns;
        tb_flag_first = 0;
        #4ns;
        while(1) begin
            tb_arith_bitstream_1 = generate_value(511);         // set 511 as max number to be expressed with a 9-bit array
            tb_arith_bitstream_2 = generate_value(511);
            tb_arith_flag = generate_value(2);
            if(tb_arith_flag != 0) begin
                if(first_input == 1)
                    first_input = 0;
                else
                    add_value();
            end
            #4ns;
        end
    end

    initial begin
        // This initial begin will check the output pins and compare when flag != 0
        check_counter = 0;
        read_pointer = 0;
        first_output = 1;
        #1ns;       // The output checker will be executed exactly 1ns after the input
        while(1) begin
            if(tb_out_flag != 0) begin
                if(first_output == 1)
                    first_output = 0;
                else
                    check();
                    check_counter = check_counter + 1;
                    if((check_counter % 10000) == 0)
                        $display("Counter: %d\tBit_1: %d\tBit_2: %d\tFlag: %d\n", check_counter, tb_arith_bitstream_1, tb_arith_bitstream_2, tb_arith_flag);
            end
            #4ns;
        end
    end


endmodule
