// The stage 4 : Carry Propagation

/*
  Stage 4 blocks:
    - Final Bits: uses the las LOW and S to generate the final bitstreams
    - Carry Propagation: runs the carry propagation process

    For more information about the carry propagation, see 'carry_propagation.v'
  header.

    The application of the Parallelized Boolean blocks upon S4 is defined by the
  sequentially allocate Carry Propagation blocks.
*/

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
    input s4_final_flag, s4_final_flag_2_3,     // This flag will be sent in 1
                        //exactly in the next clock cycle after the last input
    input [(S4_RANGE_WIDTH-1):0] in_arith_bitstream_1_1, in_arith_bitstream_1_2,
    input [(S4_RANGE_WIDTH-1):0] in_arith_bitstream_2_1, in_arith_bitstream_2_2,
    input [(S4_RANGE_WIDTH-1):0] in_arith_bitstream_3_1, in_arith_bitstream_3_2,
    input [1:0] in_arith_flag_1, in_arith_flag_2, in_arith_flag_3,
    input [(S4_RANGE_WIDTH-1):0] in_arith_range,
    input [(S4_D_SIZE-1):0] in_arith_cnt,
    input [(S4_LOW_WIDTH-1):0] in_arith_low,
    // Outputs
    output wire [(S4_BITSTREAM_WIDTH-1):0] out_carry_bit_1_1, out_carry_bit_1_2,
    output wire [(S4_BITSTREAM_WIDTH-1):0] out_carry_bit_1_3, out_carry_bit_1_4,
    output wire [(S4_BITSTREAM_WIDTH-1):0] out_carry_bit_1_5,
    output wire [2:0] out_carry_flag_bitstream_1,
    output wire output_flag_last
  );
  reg [1:0] reg_flag_final;
  reg [(S4_RANGE_WIDTH-1):0] reg_final_bit_1, reg_final_bit_2;
  /*
  ARITHMETIC ENCODER OUTPUT CONNECTIONS
  All arithmetic encoder outputs (low, range, etc) come from registers.
  Therefore, it isn't necessary to create more registers here.

  Mux bitstream to carry
  The MUX is necessary to define if it is being generated the final bitstream or
  a normal one
  The mux controller is the s4_reset[1]
    Mux input 0: the output from ARITH ENCODER
    Mux input 1: the output from FINAL_BITS_GENERATOR
    Mux output: the input to CARRY PROPAGATION
  */
  wire [(S4_RANGE_WIDTH-1):0] mux_bitstream_1, mux_bitstream_2;
  wire [1:0] mux_flag_final;
  // -------------------------

  // FINAL_BITS_GENERATOR OUTPUT CONNECTIONS
  wire [(S4_RANGE_WIDTH-1):0] out_final_bits_1, out_final_bits_2;
  wire [1:0] out_final_bits_flag; // follows the same patterns as the other flag

  /*
  The only control required to the TOP ENTITY is the output reg controller.
  It is required because some trash coming from the Arith_Encoder while the
  reset is still propagating can cause problems with the bitstream output.
  */
  wire ctrl_carry_reg;
  // -------------------------
  // INPUT MAPPING
  wire [1:0] cp_input_flag_1, cp_input_flag_2, cp_input_flag_3;
  wire [(S4_RANGE_WIDTH-1):0] cp_input_bit_1_1, cp_input_bit_1_2;
  // -------------------------
  // CARRY PROPAGATION OUTPUT CONNECTIONS
  wire out_carry_flag_last, out_flag_1st_bitstream;
  wire out_flag_1st_bitstream_cp2, out_flag_1st_bitstream_cp3;  // Useless
  wire out_carry_flag_last_cp2, out_carry_flag_last_cp3;        // Useless
  wire [(S4_BITSTREAM_WIDTH-1):0] out_previous_1, out_previous_2;
  wire [(S4_BITSTREAM_WIDTH-1):0] out_previous_3, out_counter_1, out_counter_2;
  wire [(S4_BITSTREAM_WIDTH-1):0] out_counter_3;
  wire [(S4_BITSTREAM_WIDTH-1):0] out_previous, out_counter;
  wire [2:0] out_carry_flag_1, out_carry_flag_2, out_carry_flag_3;
  wire [(S4_BITSTREAM_WIDTH-1):0] out_carry_bitstream_1_1;
  wire [(S4_BITSTREAM_WIDTH-1):0] out_carry_bitstream_1_2;
  wire [(S4_BITSTREAM_WIDTH-1):0] out_carry_bitstream_1_3;
  wire [(S4_BITSTREAM_WIDTH-1):0] out_carry_bitstream_1_4;
  wire [(S4_BITSTREAM_WIDTH-1):0] out_carry_bitstream_1_5;
  reg [(S4_BITSTREAM_WIDTH-1):0] reg_previous, reg_counter;
  reg reg_1st_bitstream, reg_flag_last_output;
  reg [2:0] reg_carry_flag_1;
  reg [(S4_BITSTREAM_WIDTH-1):0] reg_out_bitstream_1_1, reg_out_bitstream_1_2;
  reg [(S4_BITSTREAM_WIDTH-1):0] reg_out_bitstream_1_3, reg_out_bitstream_1_4;
  reg [(S4_BITSTREAM_WIDTH-1):0] reg_out_bitstream_1_5;
  // -------------------------

  // Auxiliar Control to use the last bit output differently
  wire ctrl_mux_use_last_bit;

  // Output assignments
  assign out_carry_bit_1_1 = reg_out_bitstream_1_1;
  assign out_carry_bit_1_2 = reg_out_bitstream_1_2;
  assign out_carry_bit_1_3 = reg_out_bitstream_1_3;
  assign out_carry_bit_1_4 = reg_out_bitstream_1_4;
  assign out_carry_bit_1_5 = reg_out_bitstream_1_5;
  assign out_carry_flag_bitstream_1 = reg_carry_flag_1;
  assign output_flag_last = reg_flag_last_output;
  // -------------------------

  top_control control_top (
    .clk (s4_clk),
    .reset_ctrl (s4_reset),
    .carry_ctrl (ctrl_carry_reg)
  );

  input_mapping #(
    .RANGE_WIDTH (S4_RANGE_WIDTH)
    ) input_mapper (
      .flag_1 (in_arith_flag_1), .flag_2 (in_arith_flag_2),
      .flag_3 (in_arith_flag_3),
      .bit_1_1 (in_arith_bitstream_1_1), .bit_1_2 (in_arith_bitstream_1_2),
      .bit_2_1 (in_arith_bitstream_2_1), .bit_2_2 (in_arith_bitstream_2_2),
      .bit_3_1 (in_arith_bitstream_3_1), .bit_3_2 (in_arith_bitstream_3_2),
      // Outputs
      .out_flag_1 (cp_input_flag_1),
      .out_bit_1_1 (cp_input_bit_1_1), .out_bit_1_2 (cp_input_bit_1_2)
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

  carry_propagation #(
    .OUTPUT_DATA_WIDTH (S4_BITSTREAM_WIDTH),
    .INPUT_DATA_WIDTH (S4_RANGE_WIDTH)
    ) carry_propag_1 (
      .flag_first (s4_flag_first),
      .flag_final (s4_final_flag),
      .in_counter (reg_counter),
      .in_previous (reg_previous),
      .flag_in (mux_flag_final),
      .in_bitstream_1 (mux_bitstream_1),
      .in_bitstream_2 (mux_bitstream_2),
      .reg_1st_bitstream (reg_1st_bitstream),
      // outputs
      .out_flag (out_carry_flag_1),
      .out_bitstream_1 (out_carry_bitstream_1_1),
      .out_bitstream_2 (out_carry_bitstream_1_2),
      .out_bitstream_3 (out_carry_bitstream_1_3),
      .out_bitstream_4 (out_carry_bitstream_1_4),
      .out_bitstream_5 (out_carry_bitstream_1_5),
      .counter (out_counter_1),
      .previous (out_previous_1),
      .out_flag_last (out_carry_flag_last),
      .flag_1st_bitstream (out_flag_1st_bitstream)
    );
  /* The 2nd and 3rd Carry Propagation blocks aren't required because a Boolean
  burst with up to 4 Booleans won't generate more than one bitstream.
    Perhaps, when adding 5 or more Boolean blocks it will be necessary add, at
  least, a 2nd carry propagation block. */

  assign mux_bitstream_1 =  (s4_final_flag) ? reg_final_bit_1 :
                            cp_input_bit_1_1;
  assign mux_bitstream_2 =  (s4_final_flag) ? reg_final_bit_2 :
                            cp_input_bit_1_2;
  assign mux_flag_final = (s4_final_flag) ? reg_flag_final :
                          cp_input_flag_1;

  // =============================================================
  assign out_previous = (cp_input_flag_1 != 1'd0) ? out_previous_1 :
                        reg_previous;
  assign out_counter =  (cp_input_flag_1 != 1'd0) ? out_counter_1 :
                        reg_counter;
  // =============================================================
  /*
      Internal variables
  The reg_1st_bitstream goes to 1 with reset and when the first bitstream
  finally reaches the Stage 4, the reg_1st_bitstream goes to 0.

  reg_1st_bitstream avoid the counter to start counting when the first bitstream
  is 255.

  All variables with suffix _c0 are used when counter == 0
  In the other hand, suffix _c1 is used with counter != 0

  When the variable has a suffix _final or _not_final, it means that it
  considers the flag_final.
  */
  always @ (posedge s4_clk) begin
    if(s4_reset || s4_flag_first)
      reg_1st_bitstream <= 1'b1;
    else
      reg_1st_bitstream <= out_flag_1st_bitstream;
  end

  always @ (posedge s4_clk) begin
    if(ctrl_carry_reg) begin
      reg_out_bitstream_1_1 <= out_carry_bitstream_1_1;
      reg_out_bitstream_1_2 <= out_carry_bitstream_1_2;
      reg_out_bitstream_1_3 <= out_carry_bitstream_1_3;
      reg_out_bitstream_1_4 <= out_carry_bitstream_1_4;
      reg_out_bitstream_1_5 <= out_carry_bitstream_1_5;
      reg_flag_last_output <= out_carry_flag_last;
    end
  end
  always @ (posedge s4_clk) begin
    if(s4_reset) begin
      reg_carry_flag_1 <= 3'b000;
    end else if(ctrl_carry_reg) begin
      reg_carry_flag_1 <= out_carry_flag_1;
    end
  end
  always @ (posedge s4_clk) begin
    if(s4_reset) begin
      reg_flag_final <= 1'b0;
      reg_final_bit_1 <= 1'b0;
      reg_final_bit_2 <= 1'b0;
    end else if(s4_final_flag_2_3) begin
      reg_flag_final <= out_final_bits_flag;
      reg_final_bit_1 <= out_final_bits_1;
      reg_final_bit_2 <= out_final_bits_2;
    end
  end
  always @ (posedge s4_clk) begin
    reg_previous <= out_previous;
    reg_counter <= out_counter;
  end
endmodule

module input_mapping #(
  parameter RANGE_WIDTH = 16
  )(
    input [1:0] flag_1, flag_2, flag_3,
    input [(RANGE_WIDTH-1):0] bit_1_1, bit_1_2,
    input [(RANGE_WIDTH-1):0] bit_2_1, bit_2_2,
    input [(RANGE_WIDTH-1):0] bit_3_1, bit_3_2,
    output wire [1:0] out_flag_1,
    output wire [(RANGE_WIDTH-1):0] out_bit_1_1, out_bit_1_2
  );
  wire [1:0] first_valid;
  assign first_valid =  (flag_1 != 2'd0) ? 2'd1 :
                        (flag_2 != 2'd0) ? 2'd2 :
                        (flag_3 != 2'd0) ? 2'd3 :
                        2'd0;
  //---------------------------------------------------------------------
  assign out_flag_1 = (first_valid == 2'd1) ? flag_1 :
                      (first_valid == 2'd2) ? flag_2 :
                      (first_valid == 2'd3) ? flag_3 :
                      2'd0;
  //---------------------------------------------------------------------
  assign out_bit_1_1 =  (first_valid == 2'd1) ? bit_1_1 :
                        (first_valid == 2'd2) ? bit_2_1 :
                        (first_valid == 2'd3) ? bit_3_1 :
                        16'd0;
  //---------------------------------------------------------------------
  assign out_bit_1_2 =  (first_valid == 2'd1) ? bit_1_2 :
                        (first_valid == 2'd2) ? bit_2_2 :
                        (first_valid == 2'd3) ? bit_3_2 :
                        16'd0;
endmodule
