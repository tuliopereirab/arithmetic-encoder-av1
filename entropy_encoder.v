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
        input [1:0] top_reset,          // [1]: trigger to generate the last bits; [0]: reset itself
        input [(TOP_RANGE_WIDTH-1):0] top_fl, top_fh,
        input [(TOP_SYMBOL_WIDTH-1):0] top_symbol,
        input [TOP_SYMBOL_WIDTH:0] top_nsyms,
        input top_bool,
        output wire [(TOP_BITSTREAM_WIDTH-1):0] OUT_BIT_1, OUT_BIT_2,
        output wire [1:0] OUT_FLAG_BITSTREAM
    );


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
    wire [(TOP_BITSTREAM_WIDTH-1):0] out_carry_bitstream_1, out_carry_bitstream_2, out_carry_previous_bitstream;
    wire [1:0] out_carry_flag;
    reg [1:0] reg_carry_flag;
    reg [(TOP_BITSTREAM_WIDTH-1):0] reg_previous_bitstream, reg_out_bitstream_1, reg_out_bitstream_2;

    arithmetic_encoder #(
        .GENERAL_RANGE_WIDTH (TOP_RANGE_WIDTH),
        .GENERAL_LOW_WIDTH (TOP_LOW_WIDTH),
        .GENERAL_SYMBOL_WIDTH (TOP_SYMBOL_WIDTH),
        .GENERAL_LUT_ADDR_WIDTH (TOP_LUT_ADDR_WIDTH),
        .GENERAL_LUT_DATA_WIDTH (TOP_LUT_DATA_WIDTH),
        .GENERAL_D_SIZE (TOP_D_SIZE)
        ) arith_encoder (
            .general_clk (top_clk),
            .reset (top_reset[0]),          // send to the arith_encoder only the reset itself
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
            .OUT_FLAG_BITSTREAM (out_arith_flag)
        );

    stage_4 #(
        .OUTPUT_DATA_WIDTH (TOP_BITSTREAM_WIDTH),
        .INPUT_DATA_WIDTH (TOP_RANGE_WIDTH)
        ) carry_propagation (
            .flag (mux_flag_final),
            .in_new_bitstream_1 (mux_bitstream_1),
            .in_new_bitstream_2 (mux_bitstream_2),
            .in_previous_bitstream (reg_previous_bitstream),
            .out_bitstream_1 (out_carry_bitstream_1),
            .out_bitstream_2 (out_carry_bitstream_2),
            .bitstream_hold (out_carry_previous_bitstream),
            .out_flag (out_carry_flag)
        );

    assign mux_bitstream_1 = (top_reset[1]) ? out_final_bits_1 :
                            out_arith_bitstream_1;
    assign mux_bitstream_2 = (top_reset[1]) ? out_final_bits_2 :
                            out_arith_bitstream_2;
    assign mux_flag_final = (top_reset[1]) ? out_final_bits_flag :
                            out_arith_flag;

    always @ (posedge top_clk) begin
        if(top_reset) begin
            reg_previous_bitstream <= 8'd0;
        end else if(ctrl_stage_4) begin
            reg_previous_bitstream <= out_carry_previous_bitstream;
            reg_out_bitstream_1 <= out_carry_bitstream_1;
            reg_out_bitstream_2 <= out_carry_bitstream_2;
        end
    end

endmodule
