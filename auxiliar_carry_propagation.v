// There is a glitch in the original carry propagation function when it receives two 255 in a row followed by a bitstream > 255
// This module will be started when it detects all the parameters that will cause a problem
// When that happen, this block will assume the architecture's outputs && will work based on a buffer.


// The main idea behind this block is to keep it monitoring the entire stage 4 and, when it detects that the aux is required, it pulls the output pins authority from the main carry propagation

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
        output wire ctrl_mux_final,
        output reg ctrl_mux_last_bit
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
    wire flag_start, mux_use_last_bit;
    reg [(OUTPUT_WIDTH-1):0] previous_input_bit_1;

    always @ (posedge clk) begin
        previous_input_bit_1 <= in_bitstream_1[(OUTPUT_WIDTH-1):0];
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
            ctrl_mux_last_bit <= mux_use_last_bit;
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
        // Buffer controls basically tells the buffer exactly what to do in each cycle
        // For that, it was necessary to divide this control in 3 different definitions (start, middle, final)
        // The different definitions of buffer_ctrl help to keep the code more organized
            // Start: used when the buffer is still empty
            // Middle: used when there is something already saved in the buffer
            // Final: used to keep saving data on the end of line while reading data from the first positions
        // Although the buffer control is setted by 3 different variables, its goal is pretty simple:
            // Define the exact number of bitstreams to be saved into the buffer per cycle
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
            // Addr write is basically the variable that saves how many bitstreams are already saved inside the buffer
            // This is a pointer that controls the next position in the buffer that will be written when necessary
                // There is also a register for addr_write
            // As the buffer_ctrl, the addr_write is also setted by 3 variables (start, middle, final)
                // Again, this functionality helps to keep the code a little bit simpler
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

    // When the carry propagation is working, it is usually using the main carry propagation block.
        // The mux final is the component that controls which carry propagation block is being used
    // However, when two 255 are received, the mux_final pulls the responsability for the output bitstreams to the Aux Carry Propagation
    // The idea behind this ctrl is to identify when the responsability for the output pins should be with the aux carry or main carry
    assign ctrl_mux_final = ((reg_addr_write == 0) && (in_standby_flag) && (in_flag == 2'b01) && (in_bitstream_1 == 8'd255)) ? 1'b1 :
                            ((reg_addr_write == 0) && (in_flag == 2'b11) && (in_bitstream_1 == 8'd255) && (in_bitstream_2 == 8'd255)) ? 1'b1 :
                            ((reg_addr_write != 0) && (reg_addr_read < (reg_addr_write-1))) ? 1'b1 :  // This block will dominate the architecture's output
                            1'b0;           // Let the carry_propagation block's output to be the output for the architecture

    // When it's time to start removing data from the buffer, it is necessary to not release the last value saved
        // That happens because the main carry propagation block will save this value inside the 'previous_bitstream' register
    // So, as the max number of bitstreams going out per cycle under normal conditions is 3, the first cycle realeasing data should release X, 255, 255
        // The next cycles, however, must to release [all_data]-1.
    // The flag second time checks when it's time to release everything (first cycle releasing) and when it's time to hold data inside
    assign flag_second_time =   ((reg_addr_read != 4'd0) || ((flag_final != 2'b00) && (flag_final != 2'b11))) ? 1'b1 :
                                1'b0;

    // Under normal conditions, aux carry propagation will release only 3 bitstreams per cycle.
    // However, when the previous input is already saved into the previous_bitstream register, it means that this value will be wasted when the control goes back to the main block
        // That also means that the aux carry must to release this value
        // So this mux sets the fourth pin for bitstream output to release the current output coming from the main carry propagation block
    // It's a little bit complex to understand this, but this is basically a way to do not waste a bitstream, which would create an state of error
    assign mux_use_last_bit =   ((flag_final != 2'b11) && (flag_final != 2'b00) && (!reg_flag_second_time_reading) && (in_previous_bitstream == previous_input_bit_1)) ? 1'b1 :
                                1'b0;
    // ===========================================================================
    // Flags
    // This flag basically detects when the aux carry propagation block is required and tells all other components to start working
    assign flag_start = ((reg_addr_write == 0) && (in_standby_flag) && (in_flag == 2'b01) && (in_bitstream_1 == 8'd255)) ? 1'b1 :
                        ((reg_addr_write == 0) && (in_flag == 2'b11) && (in_bitstream_1 == 8'd255) && (in_bitstream_2 == 8'd255)) ? 1'b1 :
                        1'b0;

    // The flag_final is exactly the opposite of the start: it identifies when the aux carry propag isn't required anymore
    // This main goal is to give back the output control to the main carry propag block
    // So this flag identifies the circunstances in which the AUX stopped being required and tells all other components how to procede in order to return the power to the MAIN block
    // Flag_final map
        // 00- not empty and during the execution of the auxiliar carry propagation
        // 01- done with execution and it isn't necessary to propagate the carry
        // 10- done with execution and [bitstream + 1] on the first
        // 11- memory empty
    assign flag_final =     (flag_first) ? 4'd0 :                                   // 11 - indicates that the aux memory is empty; 00 - not empty and during the execution
                            //(reg_flag_final == 2'b10) ? 2'b01 :       // This will avoid bit+1 more than once
                            ((reg_flag_final == 2'b11) && (reg_addr_write > 0) && (in_flag == 2'b01) && (in_bitstream_1 < 8'd255)) ? 2'b01 :    // when I get 2 bitstreams in a row and the reg_flag_final doesn't have time to be updated
                            ((reg_flag_final == 2'b00) && (reg_addr_write != 0) && (in_flag == 2'b01) && (in_bitstream_1 < 8'd255)) ? 2'b01 :
                            ((reg_flag_final == 2'b00) && (reg_addr_write != 0) && (in_flag == 2'b11) && (in_bitstream_1 < 8'd255)) ? 2'b01 :
                            ((reg_flag_final == 2'b00) && (reg_addr_write != 0) && (in_flag == 2'b11) && (in_bitstream_1 == 8'd255) && (in_bitstream_2 < 8'd255)) ? 2'b01 :
                            ((reg_flag_final == 2'b11) && (reg_addr_write != 0) && (in_flag == 2'b11) && (in_bitstream_1 == 8'd255) && (in_bitstream_2 < 8'd255)) ? 2'b01 :      // when I get 2 bitstreams in a row and the reg_flag_final doesn't have time to be updated
                            ((reg_flag_final == 2'b11) && (reg_addr_write > 0) && (in_flag == 2'b01) && (in_bitstream_1 > 8'd255)) ? 2'b10 :    // when I get 2 bitstreams in a row and the reg_flag_final doesn't have time to be updated
                            ((reg_flag_final == 2'b00) && (reg_addr_write != 0) && (in_flag == 2'b01) && (in_bitstream_1 > 8'd255)) ? 2'b10 :
                            ((reg_flag_final == 2'b00) && (reg_addr_write != 0) && (in_flag == 2'b11) && (in_bitstream_1 > 8'd255)) ? 2'b10 :
                            ((reg_flag_final == 2'b11) && (reg_addr_write != 0) && (in_flag == 2'b11) && (in_bitstream_1 == 8'd255) && (in_bitstream_2 > 8'd255)) ? 2'b10 :      // when I get 2 bitstreams in a row and the reg_flag_final doesn't have time to be updated
                            ((reg_flag_final == 2'b00) && (reg_addr_write != 0) && (in_flag == 2'b11) && (in_bitstream_1 == 8'd255) && (in_bitstream_2 > 8'd255)) ? 2'b10 :
                            (reg_addr_write == 0) ? 2'b11 :
                            ((reg_flag_final == 2'b10) || (reg_flag_final == 2'b01)) ? reg_flag_final :
                            2'b00;
    // ===========================================================================
    // Buffer
    // These 3 variables here are used as input for the buffer and basically decide, with the buffer_ctrl, which bitstreams should be saved into the buffer and what is the right order to do it

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
    // All these variables identify different scenarios in the execution and, by checking flag_final and flag_start, they decide what to do with their addresses

    // The addr_read basically tells the buffer which bitstreams must be released in the current clock cycle
    // All 3 addr_write here analyze different part of the execution and define, based on the analysis, what is the best way to update the addr

    assign addr_write_start =   ((flag_start) && (in_standby_flag) && (in_flag == 2'b11)) ? reg_addr_write + 4'd4 :
                                ((flag_start) && (!in_standby_flag) && (in_flag == 2'b11)) ? reg_addr_write + 4'd3 :
                                ((flag_start) && (in_standby_flag) && (in_flag == 2'b01)) ? reg_addr_write + 4'd3 :
                                4'd0;

    assign addr_write_middle =  ((reg_addr_write != 0) && (in_flag == 2'b01) && (in_bitstream_1 == 8'd255)) ? reg_addr_write + 4'd1 :
                                ((reg_addr_write != 0) && (in_flag == 2'b11) && (in_bitstream_1 == 8'd255) && (in_bitstream_2 == 8'd255)) ? reg_addr_write + 4'd2 :
                                4'd0;

    assign addr_write_final =   ((reg_addr_read >= (reg_addr_write-1)) || (flag_final == 2'b11) || (flag_final == 2'b00)) ? 4'd0 :
                                ((flag_final != 2'b00) && (flag_final != 2'b11) && (in_flag == 2'b01)) ? reg_addr_write + 4'd1 :
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
    // The output variables basically set the output pins for this block
    // However, it's necessary to identify the circunstances in which the AUX block isn't required anymore and deliver the stored data correctly
    // It is also necessary to do not release too many bitstreams
    // So here it will be kept the bitstream that is currently saved on the main block's previous_bitstream register.

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

    assign out_flag =   ((flag_final != 2'b11) && (flag_final != 2'b00) && (!reg_flag_second_time_reading) && (in_previous_bitstream == previous_input_bit_1) && (in_previous_bitstream != 255)) ? 3'b100 :       // It must not choose this line when line 142
                        ((flag_final != 2'b11) && (flag_final != 2'b00) && ((reg_addr_read+2) < reg_addr_write) && (!reg_flag_second_time_reading)) ? 3'b010 :
                        ((flag_final != 2'b11) && (flag_final != 2'b00) && ((reg_addr_read+1) < reg_addr_write) && (!reg_flag_second_time_reading)) ? 3'b011 :
                        ((flag_final != 2'b11) && (flag_final != 2'b00) && (reg_addr_read < reg_addr_write) && (!reg_flag_second_time_reading)) ? 3'b001 :
                        ((flag_final != 2'b11) && (flag_final != 2'b00) && ((reg_addr_read+3) < reg_addr_write) && (reg_flag_second_time_reading)) ? 3'b010 :
                        ((flag_final != 2'b11) && (flag_final != 2'b00) && ((reg_addr_read+2) < reg_addr_write) && (reg_flag_second_time_reading)) ? 3'b011 :
                        ((flag_final != 2'b11) && (flag_final != 2'b00) && ((reg_addr_read+1) < reg_addr_write) && (reg_flag_second_time_reading)) ? 3'b001 :
                        ((flag_final != 2'b11) && (flag_final != 2'b00) && (reg_addr_read < reg_addr_write) && (reg_flag_second_time_reading)) ? 3'b000 :
                        3'b000;
endmodule
