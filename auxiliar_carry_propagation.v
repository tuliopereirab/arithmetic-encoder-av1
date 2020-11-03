// There is a glitch in the original carry propagation function when it receives two 255 in a row followed by a bitstream > 255
// This module will be started when it detects all the parameters that will cause a problem
// When that happen, this block will assume the architecture's outputs && will work based on a buffer.

module auxiliar_carry_propagation #(
    parameter INPUT_WIDTH = 16,
    parameter OUTPUT_WIDTH = 8,
    parameter ADDR_WIDTH = 4
    ) (
        input clk, reset, in_standby_flag, flag_first,
        input [1:0] in_flag,
        input [(INPUT_WIDTH-1):0] in_bitstream_1, in_bitstream_2,
        input [(OUTPUT_WIDTH-1):0] in_previous_bitstream, in_standby_bitstream,
        output wire [(OUTPUT_WIDTH-1):0] out_bit_1, out_bit_2, out_bit_3,
        output wire [2:0] out_flag,
        output wire ctrl_mux_final
    );
    // Buffer
    reg [OUTPUT_WIDTH-1:0] buffer[2**ADDR_WIDTH-1:0];
    // registers
    reg [(ADDR_WIDTH-1):0] reg_addr_write, reg_addr_read;
    reg [1:0] reg_flag_final;
    wire flag_second_time;
    reg reg_flag_second_time_reading;           // The architecture will always hold the last value to go in
                                            // That must happen in order to synchronize with the other carry propagation block
                                            // The last value saved here is supposed to be the same saved in the register "Previous"
    // auxiliar wires
    wire [(OUTPUT_WIDTH-1):0] buffer_in_1, buffer_in_2, buffer_in_3, buffer_in_4;
    wire [2:0] ctrl_buffer, buffer_ctrl_start, buffer_ctrl_middle, buffer_ctrl_final;
    wire [(ADDR_WIDTH-1):0] addr_write, addr_read;
    wire [(ADDR_WIDTH-1):0] addr_write_start, addr_write_middle, addr_write_final;
    wire [1:0] flag_final;
    wire flag_start;

    always @ (posedge clk) begin

    end

    always @ (posedge clk) begin
        if(reset) begin
            reg_addr_write <= 4'd0;
            reg_addr_read <= 4'd0;
            reg_flag_final <= 2'd0;
            reg_flag_second_time_reading <= 1'b0;
        end else begin
            reg_flag_second_time_reading <= flag_second_time;
            reg_addr_write <= addr_write;
            reg_addr_read <= addr_read;
            reg_flag_final <= flag_final;
        end
    end

    always @ (posedge clk) begin
        case(ctrl_buffer)
            3'b100 : begin
                buffer[reg_addr_write] <= buffer_in_1;
                buffer[reg_addr_write+1] <= buffer_in_2;
                buffer[reg_addr_write+2] <= buffer_in_3;
                buffer[reg_addr_write+3] <= buffer_in_4;
            end
            3'b011 : begin
                buffer[reg_addr_write] <= buffer_in_1;
                buffer[reg_addr_write+1] <= buffer_in_2;
                buffer[reg_addr_write+2] <= buffer_in_3;
            end
            3'b010 : begin
                buffer[reg_addr_write] <= buffer_in_1;
                buffer[reg_addr_write+1] <= buffer_in_2;
            end
            3'b001 : begin
                buffer[reg_addr_write] <= buffer_in_1;
            end
        endcase
    end
    // ===========================================================================
    // Buffer control
    assign ctrl_buffer =    ((flag_final != 2'b00) && (flag_final != 2'b11)) ? buffer_ctrl_final :
                            (flag_start) ? buffer_ctrl_start :
                            (flag_final == 2'b00) ? buffer_ctrl_middle :
                            3'b000;

    assign buffer_ctrl_start =  ((flag_start) && (in_standby_flag) && (in_flag == 2'b11)) ? 3'b100 :
                                ((flag_start) && (!in_standby_flag) && (in_flag == 2'b11)) ? 3'b011 :
                                ((flag_start) && (in_standby_flag) && (in_flag == 2'b01)) ? 3'b011 :
                                (flag_start) ? 3'b010 :
                                3'd0;

    assign buffer_ctrl_middle = ((reg_addr_write != 0) && (in_flag == 2'b11) && (in_bitstream_1 == 8'd255) && (in_bitstream_2 == 255)) ? 3'b010 :
                                ((reg_addr_write != 0) && (in_flag == 2'b01) && (in_bitstream_1 == 8'd255)) ? 3'b001 :
                                3'd0;

    assign buffer_ctrl_final =  ((flag_final != 2'b00) && (flag_final != 2'b11) && (in_flag == 2'b11)) ? 3'b010 :
                                ((flag_final != 2'b00) && (flag_final != 2'b11) && (in_flag == 2'b01)) ? 3'b001 :
                                3'd0;
    // ===========================================================================
        // General definitions
    assign addr_write = (flag_first) ? 4'd0 :
                        ((flag_final != 2'b00) && (flag_final != 2'b11) && (in_flag == 2'b01)) ? addr_write_final :
                        ((flag_final != 2'b00) && (flag_final != 2'b11) && (in_flag == 2'b11)) ? addr_write_final :
                        ((reg_addr_write != 0) && (reg_addr_read >= (reg_addr_write-1))) ? addr_write_final :
                        ((flag_start) && (in_standby_flag) && (in_flag == 2'b11)) ? addr_write_start :
                        ((flag_start) && (!in_standby_flag) && (in_flag == 2'b11)) ? addr_write_start :
                        ((flag_start) && (in_standby_flag) && (in_flag == 2'b01)) ? addr_write_start :
                        ((reg_addr_write != 0) && (in_flag == 2'b01) && (in_bitstream_1 == 8'd255)) ? addr_write_middle :
                        ((reg_addr_write != 0) && (in_flag == 2'b11) && (in_bitstream_1 == 8'd255) && (in_bitstream_2 == 8'd255)) ? addr_write_middle :
                        reg_addr_write;

    assign ctrl_mux_final = ((reg_addr_write == 0) && (in_standby_flag) && (in_flag == 2'b01) && (in_bitstream_1 == 8'd255)) ? 1'b1 :
                            ((reg_addr_write == 0) && (in_flag == 2'b11) && (in_bitstream_1 == 8'd255) && (in_bitstream_2 == 8'd255)) ? 1'b1 :
                            ((reg_addr_write != 0) && (reg_addr_read < (reg_addr_write-1))) ? 1'b1 :  // This block will dominate the architecture's output
                            1'b0;           // Let the carry_propagation block's output to be the output for the architecture

    assign flag_second_time =   ((reg_addr_read != 4'd0) || ((flag_final != 2'b00) && (flag_final != 2'b11))) ? 1'b1 :
                                1'b0;
    // ===========================================================================
    // Flags
    assign flag_start = ((reg_addr_write == 0) && (in_standby_flag) && (in_flag == 2'b01) && (in_bitstream_1 == 8'd255)) ? 1'b1 :
                        ((reg_addr_write == 0) && (in_flag == 2'b11) && (in_bitstream_1 == 8'd255) && (in_bitstream_2 == 8'd255)) ? 1'b1 :
                        1'b0;

    assign flag_final =     (flag_first) ? 4'd0 :
                            //(reg_flag_final == 2'b10) ? 2'b01 :       // This will avoid bit+1 more than once
                            ((reg_flag_final == 2'b00) && (reg_addr_write != 0) && (in_flag == 2'b01) && (in_bitstream_1 < 8'd255)) ? 2'b01 :
                            ((reg_flag_final == 2'b00) && (reg_addr_write != 0) && (in_flag == 2'b11) && (in_bitstream_1 < 8'd255)) ? 2'b01 :
                            ((reg_flag_final == 2'b00) && (reg_addr_write != 0) && (in_flag == 2'b11) && (in_bitstream_1 == 8'd255) && (in_bitstream_2 < 8'd255)) ? 2'b01 :
                            ((reg_flag_final == 2'b00) && (reg_addr_write != 0) && (in_flag == 2'b01) && (in_bitstream_1 > 8'd255)) ? 2'b10 :
                            ((reg_flag_final == 2'b00) && (reg_addr_write != 0) && (in_flag == 2'b11) && (in_bitstream_1 > 8'd255)) ? 2'b10 :
                            ((reg_flag_final == 2'b00) && (reg_addr_write != 0) && (in_flag == 2'b11) && (in_bitstream_1 == 8'd255) && (in_bitstream_2 > 8'd255)) ? 2'b10 :
                            (reg_addr_write == 0) ? 2'b11 :
                            ((reg_flag_final == 2'b10) || (reg_flag_final == 2'b01)) ? reg_flag_final :
                            2'b00;
    // ===========================================================================
    // Buffer
    assign buffer_in_1 =    ((flag_start) && (in_standby_flag)) ? in_standby_bitstream :
                            (flag_start) ? in_previous_bitstream :
                            ((reg_addr_write != 0) && (in_flag == 2'b01) && (in_bitstream_1 == 8'd255)) ? in_bitstream_1[(OUTPUT_WIDTH-1):0] :
                            ((reg_addr_write != 0) && (in_flag == 2'b11) && (in_bitstream_1 == 8'd255) && (in_bitstream_2 == 8'd255)) ? in_bitstream_1[(OUTPUT_WIDTH-1):0] :
                            ((flag_final != 00) && (flag_final != 2'b11) && (in_flag != 2'b0)) ? in_bitstream_1[(OUTPUT_WIDTH-1):0] :
                            8'd0;

    assign buffer_in_2 =    ((flag_start) && (in_standby_flag)) ? in_previous_bitstream :
                            (flag_start) ? in_bitstream_1[(OUTPUT_WIDTH-1):0] :
                            ((reg_addr_write != 0) && (in_flag == 2'b11) && (in_bitstream_1 == 8'd255) && (in_bitstream_2 == 8'd255)) ? in_bitstream_2[(OUTPUT_WIDTH-1):0] :
                            ((flag_final != 2'b00) && (flag_final != 2'b11) && (in_flag == 2'b11)) ? in_bitstream_2[(OUTPUT_WIDTH-1):0] :
                            8'd0;

    assign buffer_in_3 =    ((flag_start) && (!in_standby_flag) && (in_flag == 2'b11)) ? in_bitstream_2[(OUTPUT_WIDTH-1):0] :
                            ((flag_start) && (in_standby_flag) && (in_flag == 2'b01)) ? in_bitstream_1[(OUTPUT_WIDTH-1):0] :
                            8'd0;

    assign buffer_in_4 =    ((flag_start) && (in_standby_flag) && (in_flag == 2'b11)) ? in_bitstream_2[(OUTPUT_WIDTH-1):0] :
                            8'd0;
    // ===========================================================================
    // Addresses definitions
    assign addr_write_start =   ((flag_start) && (in_standby_flag) && (in_flag == 2'b11)) ? reg_addr_write + 4'd4 :
                                ((flag_start) && (!in_standby_flag) && (in_flag == 2'b11)) ? reg_addr_write + 4'd3 :
                                ((flag_start) && (in_standby_flag) && (in_flag == 2'b01)) ? reg_addr_write + 4'd3 :
                                4'd0;

    assign addr_write_middle =  ((reg_addr_write != 0) && (in_flag == 2'b01) && (in_bitstream_1 == 8'd255)) ? reg_addr_write + 4'd1 :
                                ((reg_addr_write != 0) && (in_flag == 2'b11) && (in_bitstream_1 == 8'd255) && (in_bitstream_2 == 8'd255)) ? reg_addr_write + 4'd2 :
                                4'd0;

    assign addr_write_final =   ((flag_final != 2'b00) && (flag_final != 2'b11) && (in_flag == 2'b01)) ? reg_addr_write + 4'd1 :
                                ((flag_final != 2'b00) && (flag_final != 2'b11) && (in_flag == 2'b11)) ? reg_addr_write + 4'd2 :
                                ((reg_addr_write != 0) && (reg_addr_read >= (reg_addr_write-1))) ? 4'd0 :
                                reg_addr_write;

    assign addr_read =  (flag_first) ? 4'd0 :
                        ((flag_final != 2'b11) && (flag_final != 2'b00) && ((reg_addr_read+2) < reg_addr_write)) ? reg_addr_read + 4'd3 :
                        ((flag_final != 2'b11) && (flag_final != 2'b00) && ((reg_addr_read+1) < reg_addr_write)) ? reg_addr_read + 4'd2 :
                        ((flag_final != 2'b11) && (flag_final != 2'b00) && (reg_addr_read < reg_addr_write)) ? reg_addr_read + 4'd1 :
                        ((reg_addr_read >= (reg_addr_write-1)) || (flag_final == 2'b11) || (flag_final == 2'b00)) ? 4'd0 :
                        reg_addr_read;

    // ===========================================================================
    // Outputs
    assign out_bit_1 =  ((flag_final == 2'b10) && (reg_addr_read < reg_addr_write) && (!reg_flag_second_time_reading)) ? buffer[reg_addr_read] + 8'd1 :
                        ((flag_final == 2'b01) && (reg_addr_read < reg_addr_write) && (!reg_flag_second_time_reading)) ? buffer[reg_addr_read] :
                        ((flag_final == 2'b10) && ((reg_addr_read+1) < reg_addr_write) && (reg_flag_second_time_reading)) ? buffer[reg_addr_read] + 8'd1 :
                        ((flag_final == 2'b01) && ((reg_addr_read+1) < reg_addr_write) && (reg_flag_second_time_reading)) ? buffer[reg_addr_read] :
                        8'd0;

    assign out_bit_2 =  ((flag_final == 2'b10) && ((reg_addr_read+1) < reg_addr_write) && (!reg_flag_second_time_reading)) ? 8'd0 :
                        ((flag_final != 2'b11) && (flag_final != 2'b00) && ((reg_addr_read+1) < reg_addr_write) && (!reg_flag_second_time_reading)) ? buffer[reg_addr_read+1] :
                        ((flag_final == 2'b10) && ((reg_addr_read+2) < reg_addr_write) && (reg_flag_second_time_reading)) ? 8'd0 :
                        ((flag_final != 2'b11) && (flag_final != 2'b00) && ((reg_addr_read+2) < reg_addr_write) && (reg_flag_second_time_reading)) ? buffer[reg_addr_read+1] :
                        8'd0;

    assign out_bit_3 =  ((flag_final == 2'b10) && ((reg_addr_read+2) < reg_addr_write) && (!reg_flag_second_time_reading)) ? 8'd0 :
                        ((flag_final != 2'b11) && (flag_final != 2'b00) && ((reg_addr_read+2) < reg_addr_write) && (!reg_flag_second_time_reading)) ? buffer[reg_addr_read+2] :
                        ((flag_final == 2'b10) && ((reg_addr_read+3) < reg_addr_write) && (reg_flag_second_time_reading)) ? 8'd0 :
                        ((flag_final != 2'b11) && (flag_final != 2'b00) && ((reg_addr_read+3) < reg_addr_write) && (reg_flag_second_time_reading)) ? buffer[reg_addr_read+2] :
                        8'd0;

    assign out_flag =   ((flag_final != 2'b11) && (flag_final != 2'b00) && ((reg_addr_read+2) < reg_addr_write) && (!reg_flag_second_time_reading)) ? 3'b010 :
                        ((flag_final != 2'b11) && (flag_final != 2'b00) && ((reg_addr_read+1) < reg_addr_write) && (!reg_flag_second_time_reading)) ? 3'b011 :
                        ((flag_final != 2'b11) && (flag_final != 2'b00) && (reg_addr_read < reg_addr_write) && (!reg_flag_second_time_reading)) ? 3'b001 :
                        ((flag_final != 2'b11) && (flag_final != 2'b00) && ((reg_addr_read+3) < reg_addr_write) && (reg_flag_second_time_reading)) ? 3'b010 :
                        ((flag_final != 2'b11) && (flag_final != 2'b00) && ((reg_addr_read+2) < reg_addr_write) && (reg_flag_second_time_reading)) ? 3'b011 :
                        ((flag_final != 2'b11) && (flag_final != 2'b00) && ((reg_addr_read+1) < reg_addr_write) && (reg_flag_second_time_reading)) ? 3'b001 :
                        ((flag_final != 2'b11) && (flag_final != 2'b00) && (reg_addr_read < reg_addr_write) && (reg_flag_second_time_reading)) ? 3'b000 :
                        3'b000;
endmodule
