module entropy_encoder #(
    parameter TOP_RANGE_WIDTH = 16,
    parameter TOP_LOW_WIDTH = 24,
    parameter TOP_SYMBOL_WIDTH = 4,
    parameter TOP_LUT_ADDR_WIDTH = 8,
    parameter TOP_LUT_DATA_WIDTH = 16,
    parameter TOP_BITSTREAM_WIDTH = 8,
    parameter TOP_D_SIZE = 5
    )(
        input top_clk,
        input top_reset,
        input top_final_flag,           // This flag will be sended in 1 exactly in the next clock cycle after the last input
        input [(TOP_RANGE_WIDTH-1):0] top_fl, top_fh,
        input [(TOP_SYMBOL_WIDTH-1):0] top_symbol,
        input [TOP_SYMBOL_WIDTH:0] top_nsyms,
        input top_bool,
        output wire [(TOP_BITSTREAM_WIDTH-1):0] OUT_BIT_1, OUT_BIT_2, OUT_BIT_3, OUT_LAST_BIT,
        output wire [2:0] OUT_FLAG_BITSTREAM,
        output wire OUT_FLAG_LAST, ERROR_INDICATION         // The error indication will only be activated when two bitstream 255 in a row followed by a >255 bitstream;
    );


    // The 3 following registers will be used to keep the final 1 flag
    reg reg_final_exec_1_2, reg_final_exec_2_3, reg_final_exec_3_4;
    always @ (posedge top_clk) begin
        reg_final_exec_1_2 <= top_final_flag;
        reg_final_exec_2_3 <= reg_final_exec_1_2;
        reg_final_exec_3_4 <= reg_final_exec_2_3;
    end

    reg [1:0] reg_flag_final;
    reg [(TOP_RANGE_WIDTH-1):0] reg_final_bit_1, reg_final_bit_2;
    // ARITHMETIC ENCODER OUTPUT CONNECTIONS
        // ALl arithmetic encoder outputs come from registers
        // Therefore, it isn't necessary to create more registers here
    wire [(TOP_RANGE_WIDTH-1):0] out_arith_bitstream_1, out_arith_bitstream_2, out_arith_range, out_arith_offs;
    wire [(TOP_D_SIZE-1):0] out_arith_cnt;
    wire [(TOP_LOW_WIDTH-1):0] out_arith_low;
    wire [1:0] out_arith_flag;

    // Mux bitstream to carry
    // The MUX is necessary to define if it is being generated the final bitstream or a normal one
    // The mux controller is the top_reset[1]
        // Mux input 0: the output from ARITH ENCODER
        // Mux input 1: the output from FINAL_BITS_GENERATOR
        // Mux output: the input to CARRY PROPAGATION
    wire [(TOP_RANGE_WIDTH-1):0] mux_bitstream_1, mux_bitstream_2;
    wire [1:0] mux_flag_final;

    // FINAL_BITS_GENERATOR OUTPUT CONNECTIONS
    wire [(TOP_RANGE_WIDTH-1):0] out_final_bits_1, out_final_bits_2;
    wire [1:0] out_final_bits_flag;           // follows the same patterns as the other flag

    // CARRY PROPAGATION OUTPUT CONNECTIONS
    wire [(TOP_BITSTREAM_WIDTH-1):0] out_carry_bitstream_1, out_carry_bitstream_2, out_carry_bitstream_3, out_carry_previous_bitstream, out_carry_standby_bitstream;
    wire [2:0] out_carry_flag;
    wire out_carry_flag_last, out_carry_flag_standby, out_carry_flag_possible_error, out_carry_confirmed_error;
    reg reg_flag_last_output, reg_flag_standby, reg_possible_error, reg_confirmed_error;
    reg [2:0] reg_carry_flag;
    reg [(TOP_BITSTREAM_WIDTH-1):0] reg_previous_bitstream, reg_out_bitstream_1, reg_out_bitstream_2, reg_out_bitstream_3, reg_standby_bitstream;

    // Output assignments
    assign OUT_BIT_1 = reg_out_bitstream_1;
    assign OUT_BIT_2 = reg_out_bitstream_2;
    assign OUT_BIT_3 = reg_out_bitstream_3;
    assign ERROR_INDICATION = reg_confirmed_error;
    assign OUT_LAST_BIT = reg_previous_bitstream;
    assign OUT_FLAG_BITSTREAM = reg_carry_flag;
    assign OUT_FLAG_LAST = reg_flag_last_output;

    arithmetic_encoder #(
        .GENERAL_RANGE_WIDTH (TOP_RANGE_WIDTH),
        .GENERAL_LOW_WIDTH (TOP_LOW_WIDTH),
        .GENERAL_SYMBOL_WIDTH (TOP_SYMBOL_WIDTH),
        .GENERAL_LUT_ADDR_WIDTH (TOP_LUT_ADDR_WIDTH),
        .GENERAL_LUT_DATA_WIDTH (TOP_LUT_DATA_WIDTH),
        .GENERAL_D_SIZE (TOP_D_SIZE)
        ) arith_encoder (
            .general_clk (top_clk),
            .reset (top_reset),          // send to the arith_encoder only the reset itself
            .general_fl (top_fl),
            .general_fh (top_fh),
            .general_symbol (top_symbol),
            .general_nsyms (top_nsyms),
            .general_bool (top_bool),
            // outputs
            .RANGE_OUTPUT (out_arith_range),
            .LOW_OUTPUT (out_arith_low),
            .CNT_OUTPUT (out_arith_cnt),
            .OUT_BIT_1 (out_arith_bitstream_1),
            .OUT_BIT_2 (out_arith_bitstream_2),
            .OUT_FLAG_BITSTREAM (out_arith_flag),
            .OUT_OFFS (out_arith_offs)
        );

    final_bits_generator #(
        .OUTPUT_BITSTREAM_WIDTH (TOP_RANGE_WIDTH),
        .D_SIZE (TOP_D_SIZE),
        .LOW_WIDTH (TOP_LOW_WIDTH)
        ) final_bits (
            .in_cnt (out_arith_cnt),
            .in_low (out_arith_low),
            .flag (out_final_bits_flag),
            .out_bit_1 (out_final_bits_1),
            .out_bit_2 (out_final_bits_2)
        );

    stage_4 #(
        .OUTPUT_DATA_WIDTH (TOP_BITSTREAM_WIDTH),
        .INPUT_DATA_WIDTH (TOP_RANGE_WIDTH)
        ) carry_propagation (
            .flag (mux_flag_final),
            .flag_final_bits (reg_final_exec_3_4),
            .flag_possible_error_in (reg_possible_error),
            .in_new_bitstream_1 (mux_bitstream_1),
            .in_new_bitstream_2 (mux_bitstream_2),
            .in_previous_bitstream (reg_previous_bitstream),
            .in_flag_standby (reg_flag_standby),
            .in_standby_bitstream (reg_standby_bitstream),
            // outputs
            .flag_possible_error_out (out_carry_flag_possible_error),
            .confirmed_error (out_carry_confirmed_error),
            .out_bitstream_1 (out_carry_bitstream_1),
            .out_bitstream_2 (out_carry_bitstream_2),
            .out_bitstream_3 (out_carry_bitstream_3),
            .bitstream_hold (out_carry_previous_bitstream),
            .out_standby_bitstream (out_carry_standby_bitstream),
            .out_flag (out_carry_flag),
            .out_flag_last (out_carry_flag_last)
        );

    assign mux_bitstream_1 = (reg_final_exec_3_4) ? reg_final_bit_1 :
                            out_arith_bitstream_1;
    assign mux_bitstream_2 = (reg_final_exec_3_4) ? reg_final_bit_2 :
                            out_arith_bitstream_2;
    assign mux_flag_final = (reg_final_exec_3_4) ? reg_flag_final :
                            out_arith_flag;

    always @ (posedge top_clk) begin
        reg_carry_flag <= out_carry_flag;
        reg_out_bitstream_1 <= out_carry_bitstream_1;
        reg_out_bitstream_2 <= out_carry_bitstream_2;
        reg_flag_last_output <= out_carry_flag_last;
        reg_standby_bitstream <= out_carry_standby_bitstream;
        reg_flag_standby <= out_carry_flag_standby;
        reg_possible_error <= out_carry_flag_possible_error;
        reg_confirmed_error <= out_carry_confirmed_error;
    end

    always @ (posedge top_clk) begin
        if(top_reset) begin
            reg_previous_bitstream <= 8'd0;
        end else begin
            reg_previous_bitstream <= out_carry_previous_bitstream;
        end
    end
    always @ (posedge top_clk) begin
        if(reg_final_exec_2_3) begin
            reg_flag_final <= out_final_bits_flag;
            reg_final_bit_1 <= out_final_bits_1;
            reg_final_bit_2 <= out_final_bits_2;
        end
    end

endmodule
