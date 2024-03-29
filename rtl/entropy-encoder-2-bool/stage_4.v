// The stage 4 : Carry Propagation

/*
  Stage 4 blocks:
    - Final Bits: uses the las LOW and S to generate the final bitstreams
    - Carry Propagation: runs the carry propagation process
    -
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
    input [(S4_RANGE_WIDTH-1):0] in_arith_range,
    input [(S4_D_SIZE-1):0] in_arith_cnt,
    input [(S4_LOW_WIDTH-1):0] in_arith_low,
    input [1:0] in_arith_flag_1, in_arith_flag_2,
    // Outputs
    output wire [(S4_BITSTREAM_WIDTH-1):0] out_carry_bit_1, out_carry_bit_2,
    output wire [(S4_BITSTREAM_WIDTH-1):0] out_carry_bit_3, out_carry_bit_4,
    output wire [(S4_BITSTREAM_WIDTH-1):0] out_carry_bit_5,
    output wire [2:0] out_carry_flag_bitstream,
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
  wire [(S4_RANGE_WIDTH-1):0] mux_bitstream_1, mux_bitstream_2, pb_1, pb_2;
  wire [1:0] mux_flag_final, pb_flag;
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

  // CARRY PROPAGATION OUTPUT CONNECTIONS
  wire [(S4_BITSTREAM_WIDTH-1):0] out_previous, out_counter;
  reg [(S4_BITSTREAM_WIDTH-1):0] reg_previous, reg_counter;
  wire [(S4_BITSTREAM_WIDTH-1):0] out_carry_bitstream_1, out_carry_bitstream_2;
  wire [(S4_BITSTREAM_WIDTH-1):0] out_carry_bitstream_3, out_carry_bitstream_4;
  wire [(S4_BITSTREAM_WIDTH-1):0] out_carry_bitstream_5;
  wire [2:0] out_carry_flag;
  wire out_carry_flag_last;
  reg reg_flag_last_output;
  reg [2:0] reg_carry_flag;
  reg [(S4_BITSTREAM_WIDTH-1):0] reg_previous_bitstream, reg_out_bitstream_1;
  reg [(S4_BITSTREAM_WIDTH-1):0] reg_out_bitstream_2, reg_out_bitstream_3;
  reg [(S4_BITSTREAM_WIDTH-1):0] reg_out_bitstream_4, reg_out_bitstream_5;
  // -------------------------

  // Auxiliar Control to use the last bit output differently
  wire ctrl_mux_use_last_bit;

  // Output assignments
  assign out_carry_bit_1 = reg_out_bitstream_1;
  assign out_carry_bit_2 = reg_out_bitstream_2;
  assign out_carry_bit_3 = reg_out_bitstream_3;
  assign out_carry_bit_4 = reg_out_bitstream_4;
  assign out_carry_bit_5 = reg_out_bitstream_5;
  assign out_carry_flag_bitstream = reg_carry_flag;
  assign output_flag_last = reg_flag_last_output;
  // -------------------------


  top_control control_top (
    .clk (s4_clk),
    .reset_ctrl (s4_reset),
    .carry_ctrl (ctrl_carry_reg)
  );

  s4_pb_mapper #(
    .PB_WIDTH (S4_RANGE_WIDTH)
    ) pb_mapper (
      .in_pb_1_1 (in_arith_bitstream_1_1),
      .in_pb_1_2 (in_arith_bitstream_1_2),
      .in_pb_2_1 (in_arith_bitstream_2_1),
      .in_pb_2_2 (in_arith_bitstream_2_2),
      .in_pb_flag_1 (in_arith_flag_1),
      .in_pb_flag_2 (in_arith_flag_2),
      // Outputs
      .pb_1 (pb_1),
      .pb_2 (pb_2),
      .pb_flag (pb_flag)
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
    ) carry_propag (
      .clk (s4_clk),
      .reset (s4_reset),
      .flag_in (mux_flag_final),
      .flag_first (s4_flag_first),
      .flag_final (s4_final_flag),
      .in_counter (reg_counter),
      .in_previous (reg_previous),
      .in_bitstream_1 (mux_bitstream_1),
      .in_bitstream_2 (mux_bitstream_2),
      // outputs
      .out_bitstream_1 (out_carry_bitstream_1),
      .out_bitstream_2 (out_carry_bitstream_2),
      .out_bitstream_3 (out_carry_bitstream_3),
      .out_bitstream_4 (out_carry_bitstream_4),
      .out_bitstream_5 (out_carry_bitstream_5),
      .previous (out_previous),
      .counter (out_counter),
      .out_flag (out_carry_flag),
      .out_flag_last (out_carry_flag_last)
    );


  assign mux_bitstream_1 =  (s4_final_flag) ? reg_final_bit_1 :
                            pb_1;
  assign mux_bitstream_2 =  (s4_final_flag) ? reg_final_bit_2 :
                            pb_2;
  assign mux_flag_final = (s4_final_flag) ? reg_flag_final :
                          pb_flag;

  // =============================================================

  always @ (posedge s4_clk) begin
    if(ctrl_carry_reg) begin
      reg_out_bitstream_1 <= out_carry_bitstream_1;
      reg_out_bitstream_2 <= out_carry_bitstream_2;
      reg_out_bitstream_3 <= out_carry_bitstream_3;
      reg_out_bitstream_4 <= out_carry_bitstream_4;
      reg_out_bitstream_5 <= out_carry_bitstream_5;
      reg_flag_last_output <= out_carry_flag_last;
    end
  end
  always @ (posedge s4_clk) begin
    if(s4_reset) begin
      reg_carry_flag <= 3'b000;
    end else if(ctrl_carry_reg) begin
      reg_carry_flag <= out_carry_flag;
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

module s4_pb_mapper #(
  // This module finds the valid pre-bitstream set
  parameter PB_WIDTH = 9
  ) (
    input [(PB_WIDTH-1):0] in_pb_1_1, in_pb_1_2, in_pb_2_1, in_pb_2_2,
    input [1:0] in_pb_flag_1, in_pb_flag_2,
    output wire [(PB_WIDTH-1):0] pb_1, pb_2,
    output wire [1:0] pb_flag
  );
  assign pb_flag =  (in_pb_flag_1 != 2'd0) ? in_pb_flag_1 :
                    (in_pb_flag_2 != 2'd0) ? in_pb_flag_2 :
                    2'd0;
  assign pb_1 = (in_pb_flag_1 != 2'd0) ? in_pb_1_1 :
                in_pb_2_1;
  assign pb_2 = (in_pb_flag_1 != 2'd0) ? in_pb_1_2 :
                in_pb_2_2;
endmodule
