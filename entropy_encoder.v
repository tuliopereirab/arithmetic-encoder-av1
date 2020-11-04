module entropy_encoder #(
    parameter TOP_RANGE_WIDTH = 16,
    parameter TOP_LOW_WIDTH = 24,
    parameter TOP_SYMBOL_WIDTH = 4,
    parameter TOP_LUT_ADDR_WIDTH = 8,
    parameter TOP_LUT_DATA_WIDTH = 16,
    parameter TOP_BITSTREAM_WIDTH = 8,
    parameter TOP_D_SIZE = 5,
    parameter TOP_ADDR_CARRY_WIDTH = 4
    )(
        input top_clk,
        input top_reset,
        input top_flag_first,
        input top_final_flag,           // This flag will be sended in 1 exactly in the next clock cycle after the last input
        input [(TOP_RANGE_WIDTH-1):0] top_fl, top_fh,
        input [(TOP_SYMBOL_WIDTH-1):0] top_symbol,
        input [TOP_SYMBOL_WIDTH:0] top_nsyms,
        input top_bool,
        output wire [(TOP_BITSTREAM_WIDTH-1):0] OUT_BIT_1, OUT_BIT_2, OUT_BIT_3, OUT_LAST_BIT,
        output wire [2:0] OUT_FLAG_BITSTREAM,
        output wire OUT_FLAG_LAST, ERROR_INDICATION         // The error indication will only be activated when two bitstream 255 in a row followed by a >255 bitstream;
    );

    // In order to ensure that all the necessary flags in the Carry propagation block will be correctly initiated,
    // I will propagate a flag called flag_first able to set all flags to zero without requiring any other flag
    // This is a temporary way to ensure that all flags are correctly defined when the first bitstream comes through
        // The following lines will just propagate this signal between the blocks
    reg reg_first_1_2, reg_first_2_3, reg_first_3_4;
    always @ (posedge top_clk) begin
        reg_first_1_2 <= top_flag_first;
        reg_first_2_3 <= reg_first_1_2;
        reg_first_3_4 <= reg_first_2_3;     // This last register is also the input for the Stage_4
    end

    // The 3 following registers will be used to keep the final 1 flag
    reg reg_final_exec_1_2, reg_final_exec_2_3, reg_final_exec_3_4;
    always @ (posedge top_clk) begin
        if(top_reset) begin
            reg_final_exec_1_2 <= 1'b0;
            reg_final_exec_2_3 <= 1'b0;
            reg_final_exec_3_4 <= 1'b0;
        end else begin
            reg_final_exec_1_2 <= top_final_flag;
            reg_final_exec_2_3 <= reg_final_exec_1_2;
            reg_final_exec_3_4 <= reg_final_exec_2_3;
        end
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

    // The only control required to the TOP ENTITY is the output reg controller
    // It is required because some trash coming from the Arith_Encoder while the reset is still propagating can cause problems with the bitstream output
    wire ctrl_carry_reg;

    // CARRY PROPAGATION OUTPUT CONNECTIONS
    wire [(TOP_BITSTREAM_WIDTH-1):0] out_carry_bitstream_1, out_carry_bitstream_2, out_carry_bitstream_3, out_carry_previous_bitstream, out_carry_standby_bitstream;
    wire [2:0] out_carry_flag;
    wire out_carry_flag_last, out_carry_flag_standby, out_carry_flag_possible_error, out_carry_confirmed_error;
    reg reg_flag_last_output, reg_flag_standby, reg_possible_error, reg_confirmed_error;
    reg [2:0] reg_carry_flag;
    reg [(TOP_BITSTREAM_WIDTH-1):0] reg_previous_bitstream, reg_out_bitstream_1, reg_out_bitstream_2, reg_out_bitstream_3, reg_standby_bitstream, alternative_last_bit;

    // Auxiliar Control to use the last bit output differently
    wire ctrl_mux_use_last_bit;

    // Output assignments
    assign OUT_BIT_1 = reg_out_bitstream_1;
    assign OUT_BIT_2 = reg_out_bitstream_2;
    assign OUT_BIT_3 = reg_out_bitstream_3;
    assign ERROR_INDICATION = reg_confirmed_error;
    assign OUT_LAST_BIT =   (ctrl_mux_use_last_bit) ? alternative_last_bit :
                            reg_previous_bitstream;
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

    top_control control_top (
        .clk (top_clk),
        .reset_ctrl (top_reset),
        .carry_ctrl (ctrl_carry_reg)
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
            .flag_first (reg_first_3_4),
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
            .out_flag_last (out_carry_flag_last),
            .out_flag_standby (out_carry_flag_standby)
        );

    // auxiliar carry propagation
    wire mux_output_ctrl;
    wire [(TOP_BITSTREAM_WIDTH-1):0] out_bit_1_aux, out_bit_2_aux, out_bit_3_aux;
    wire [(TOP_BITSTREAM_WIDTH-1):0] mux_output_bit_1, mux_output_bit_2, mux_output_bit_3;
    wire [2:0] out_flag_aux, mux_output_flag;

    auxiliar_carry_propagation #(
        .INPUT_WIDTH (TOP_RANGE_WIDTH),
        .OUTPUT_WIDTH (TOP_BITSTREAM_WIDTH),
        .ADDR_WIDTH (TOP_ADDR_CARRY_WIDTH)
        ) aux_carry_propagation (
            .clk (top_clk),
            .reset (top_reset),
            .flag_first (reg_first_3_4),
            .in_standby_flag (reg_flag_standby),
            .ctrl_mux_final (mux_output_ctrl),
            .in_flag (out_arith_flag),
            .in_bitstream_1 (out_arith_bitstream_1),
            .in_bitstream_2 (out_arith_bitstream_2),
            .in_previous_bitstream (reg_previous_bitstream),
            .in_standby_bitstream (reg_standby_bitstream),
            // out
            .out_bit_1 (out_bit_1_aux),
            .out_bit_2 (out_bit_2_aux),
            .out_bit_3 (out_bit_3_aux),
            .out_flag (out_flag_aux),
            .ctrl_mux_last_bit (ctrl_mux_use_last_bit)
        );


    // =============================================================

    assign mux_output_bit_1 =   (mux_output_ctrl) ? out_bit_1_aux :
                                out_carry_bitstream_1;
    assign mux_output_bit_2 =   (mux_output_ctrl) ? out_bit_2_aux :
                                out_carry_bitstream_2;
    assign mux_output_bit_3 =   (mux_output_ctrl) ? out_bit_3_aux :
                                out_carry_bitstream_3;
    assign mux_output_flag =    (mux_output_ctrl) ? out_flag_aux :
                                out_carry_flag;


    assign mux_bitstream_1 = (reg_final_exec_3_4) ? reg_final_bit_1 :
                            out_arith_bitstream_1;
    assign mux_bitstream_2 = (reg_final_exec_3_4) ? reg_final_bit_2 :
                            out_arith_bitstream_2;
    assign mux_flag_final = (reg_final_exec_3_4) ? reg_flag_final :
                            out_arith_flag;

    always @ (posedge top_clk) begin
        if(ctrl_carry_reg) begin
            alternative_last_bit <= out_carry_bitstream_1;
            reg_out_bitstream_1 <= mux_output_bit_1;
            reg_out_bitstream_2 <= mux_output_bit_2;
            reg_out_bitstream_3 <= mux_output_bit_3;
            reg_flag_last_output <= out_carry_flag_last;
            reg_standby_bitstream <= out_carry_standby_bitstream;
            reg_possible_error <= out_carry_flag_possible_error;
            reg_confirmed_error <= out_carry_confirmed_error;
        end
    end

    always @ (posedge top_clk) begin
        if(top_reset) begin
            reg_previous_bitstream <= 8'd0;
            reg_flag_standby <= 1'b0;
            reg_carry_flag <= 3'b000;
        end else if(ctrl_carry_reg) begin
            reg_previous_bitstream <= out_carry_previous_bitstream;
            reg_flag_standby <= out_carry_flag_standby;
            reg_carry_flag <= mux_output_flag;
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
