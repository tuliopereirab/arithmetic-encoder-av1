module stage_4 #(
    parameter S4_RANGE_WIDTH = 16,
    parameter S4_LOW_WIDTH = 24,
    parameter S4_SYMBOL_WIDTH = 4,
    parameter S4_LUT_ADDR_WIDTH = 8,
    parameter S4_LUT_DATA_WIDTH = 16,
    parameter S4_BITSTREAM_WIDTH = 8,
    parameter S4_D_SIZE = 5,
    parameter S4_ADDR_CARRY_WIDTH = 4
    )(
        input s4_clk,
        input s4_reset,
        input s4_flag_first,
        input s4_final_flag, s4_final_flag_2_3,           // This flag will be sended in 1 exactly in the next clock cycle after the last input
        input [(S4_RANGE_WIDTH-1):0] in_arith_bitstream_1, in_arith_bitstream_2, in_arith_range, in_arith_offs,
        input [(S4_D_SIZE-1):0] in_arith_cnt,
        input [(S4_LOW_WIDTH-1):0] in_arith_low,
        input [1:0] in_arith_flag,

        output wire [(S4_BITSTREAM_WIDTH-1):0] out_carry_bit_1, out_carry_bit_2, out_carry_bit_3, out_carry_last_bit,
        output wire [2:0] out_carry_flag_bitstream,
        output wire output_flag_last, out_carry_error         // The error indication will only be activated when two bitstream 255 in a row followed by a >255 bitstream;
    );


    reg [1:0] reg_flag_final;
    reg [(S4_RANGE_WIDTH-1):0] reg_final_bit_1, reg_final_bit_2;
    // ARITHMETIC ENCODER OUTPUT CONNECTIONS
        // ALl arithmetic encoder outputs come from registers
        // Therefore, it isn't necessary to create more registers here

    // Mux bitstream to carry
    // The MUX is necessary to define if it is being generated the final bitstream or a normal one
    // The mux controller is the s4_reset[1]
        // Mux input 0: the output from ARITH ENCODER
        // Mux input 1: the output from FINAL_BITS_GENERATOR
        // Mux output: the input to CARRY PROPAGATION
    wire [(S4_RANGE_WIDTH-1):0] mux_bitstream_1, mux_bitstream_2;
    wire [1:0] mux_flag_final;

    // FINAL_BITS_GENERATOR OUTPUT CONNECTIONS
    wire [(S4_RANGE_WIDTH-1):0] out_final_bits_1, out_final_bits_2;
    wire [1:0] out_final_bits_flag;           // follows the same patterns as the other flag

    // The only control required to the TOP ENTITY is the output reg controller
    // It is required because some trash coming from the Arith_Encoder while the reset is still propagating can cause problems with the bitstream output
    wire ctrl_carry_reg;

    // CARRY PROPAGATION OUTPUT CONNECTIONS
    wire [(S4_BITSTREAM_WIDTH-1):0] out_carry_bitstream_1, out_carry_bitstream_2, out_carry_bitstream_3, out_carry_previous_bitstream, out_carry_standby_bitstream;
    wire [2:0] out_carry_flag;
    wire out_carry_flag_last, out_carry_flag_standby, out_carry_flag_possible_error, out_carry_confirmed_error;
    reg reg_flag_last_output, reg_flag_standby, reg_possible_error, reg_confirmed_error;
    reg [2:0] reg_carry_flag;
    reg [(S4_BITSTREAM_WIDTH-1):0] reg_previous_bitstream, reg_out_bitstream_1, reg_out_bitstream_2, reg_out_bitstream_3, reg_standby_bitstream, alternative_last_bit;

    // Auxiliar Control to use the last bit output differently
    wire ctrl_mux_use_last_bit;

    // Output assignments
    assign out_carry_bit_1 = reg_out_bitstream_1;
    assign out_carry_bit_2 = reg_out_bitstream_2;
    assign out_carry_bit_3 = reg_out_bitstream_3;
    assign out_carry_error = reg_confirmed_error;
    assign out_carry_last_bit =     (ctrl_mux_use_last_bit) ? alternative_last_bit :
                                    reg_previous_bitstream;
    assign out_carry_flag_bitstream = reg_carry_flag;
    assign output_flag_last = reg_flag_last_output;


    top_control control_top (
        .clk (s4_clk),
        .reset_ctrl (s4_reset),
        .carry_ctrl (ctrl_carry_reg)
        );

    final_bits_generator #(
        .OUTPUT_BITSTREAM_WIDTH (S4_RANGE_WIDTH),
        .D_SIZE (S4_D_SIZE),
        .LOW_WIDTH (S4_LOW_WIDTH)
        ) final_bits (
            .in_cnt (in_arith_cnt),
            .in_low (in_arith_low),
            .flag (out_final_bits_flag),
            .out_bit_1 (out_final_bits_1),
            .out_bit_2 (out_final_bits_2)
        );

    carry_propagation_module #(
        .OUTPUT_DATA_WIDTH (S4_BITSTREAM_WIDTH),
        .INPUT_DATA_WIDTH (S4_RANGE_WIDTH)
        ) carry_propagation (
            .flag (mux_flag_final),
            .flag_first (s4_flag_first),
            .flag_final_bits (s4_final_flag),
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
    wire [(S4_BITSTREAM_WIDTH-1):0] out_bit_1_aux, out_bit_2_aux, out_bit_3_aux;
    wire [(S4_BITSTREAM_WIDTH-1):0] mux_output_bit_1, mux_output_bit_2, mux_output_bit_3;
    wire [2:0] out_flag_aux, mux_output_flag;

    auxiliar_carry_propagation #(
        .INPUT_WIDTH (S4_RANGE_WIDTH),
        .OUTPUT_WIDTH (S4_BITSTREAM_WIDTH),
        .ADDR_WIDTH (S4_ADDR_CARRY_WIDTH)
        ) aux_carry_propagation (
            .clk (s4_clk),
            .reset (s4_reset),
            .flag_first (s4_flag_first),
            .in_standby_flag (reg_flag_standby),
            .ctrl_mux_final (mux_output_ctrl),
            .in_flag (in_arith_flag),
            .in_bitstream_1 (in_arith_bitstream_1),
            .in_bitstream_2 (in_arith_bitstream_2),
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


    assign mux_bitstream_1 = (s4_final_flag) ? reg_final_bit_1 :
                            in_arith_bitstream_1;
    assign mux_bitstream_2 = (s4_final_flag) ? reg_final_bit_2 :
                            in_arith_bitstream_2;
    assign mux_flag_final = (s4_final_flag) ? reg_flag_final :
                            in_arith_flag;

    always @ (posedge s4_clk) begin
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

    always @ (posedge s4_clk) begin
        if(s4_reset) begin
            reg_previous_bitstream <= 8'd0;
            reg_flag_standby <= 1'b0;
            reg_carry_flag <= 3'b000;
        end else if(ctrl_carry_reg) begin
            reg_previous_bitstream <= out_carry_previous_bitstream;
            reg_flag_standby <= out_carry_flag_standby;
            reg_carry_flag <= mux_output_flag;
        end
    end
    always @ (posedge s4_clk) begin
        if(s4_final_flag_2_3) begin
            reg_flag_final <= out_final_bits_flag;
            reg_final_bit_1 <= out_final_bits_1;
            reg_final_bit_2 <= out_final_bits_2;
        end
    end

endmodule
