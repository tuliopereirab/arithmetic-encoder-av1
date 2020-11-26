// There is a glitch in the original carry propagation function when it receives two 255 in a row followed by a bitstream > 255
// This module will be started when it detects all the parameters that will cause a problem
// When that happen, this block will assume the architecture's outputs && will work based on a buffer.


// This entire block is based on the following map:
        // https://docs.google.com/spreadsheets/d/1TxM0V8Arepv4CVbWq-B_VGT77I1iNx7inVRwQACSpPo/edit?usp=sharing
        // Page Aux Carry


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
        output wire [(OUTPUT_WIDTH-1):0] out_bit_1, out_bit_2, out_bit_3, out_bit_4,
        output wire [2:0] out_flag,
        output wire ctrl_mux_final,
        output reg ctrl_mux_last_bit
    );
    // Buffer
    reg [OUTPUT_WIDTH-1:0] buffer[2**ADDR_WIDTH-1:0];

    // auxiliar wires

    // addr_write
    wire [(ADDR_WIDTH-1):0] addr_write;
    wire [(ADDR_WIDTH-1):0] addr_write_start, addr_write_final;
    wire [(ADDR_WIDTH-1):0] addr_write_final_first, addr_write_final_c0, addr_write_final_c1;
    wire [(ADDR_WIDTH-1):0] addr_write_final_c2, addr_write_final_c3, addr_write_final_c4;
    reg [(ADDR_WIDTH-1):0] reg_addr_write;

    // addr_read
    wire [(ADDR_WIDTH-1):0] addr_read;
    wire [(ADDR_WIDTH-1):0] addr_read_first, addr_read_c0, addr_read_c1;
    wire [(ADDR_WIDTH-1):0] addr_read_c2, addr_read_c3, addr_read_c4;
    reg [(ADDR_WIDTH-1):0] reg_addr_read;

    // connections for the 4 out_bit output pins
    // out 1
    wire [(OUTPUT_WIDTH-1):0] out_1_first, out_1_c0, out_1_c1, out_1_c2, out_1_c3, out_1_c4;

    // out 2
    wire [(OUTPUT_WIDTH-1):0] out_2_first, out_2_c0, out_2_c1, out_2_c2, out_2_c3, out_2_c4;

    // out 3
    wire [(OUTPUT_WIDTH-1):0] out_3_first, out_3_c0, out_3_c1, out_3_c2, out_3_c3, out_3_c4;

    // out 4
    wire [(OUTPUT_WIDTH-1):0] out_4_first, out_4_c0, out_4_c1, out_4_c2, out_4_c3, out_4_c4;

    // out flag
    wire [2:0] out_flag_first, out_flag_c0, out_flag_c1, out_flag_c2;
    wire [2:0] out_flag_c3, out_flag_c4;

    // all wires related to the buffer operations
    wire [(OUTPUT_WIDTH-1):0] buffer_1, buffer_2, buffer_3;
    // buffer 1
    wire [(OUTPUT_WIDTH-1):0] buffer_1_final, buffer_1_start;
    wire [(OUTPUT_WIDTH-1):0] buffer_1_final_first, buffer_1_final_c0, buffer_1_final_c1;
    wire [(OUTPUT_WIDTH-1):0] buffer_1_final_c2, buffer_1_final_c3, buffer_1_final_c4;
    // buffer 2
    wire [(OUTPUT_WIDTH-1):0] buffer_2_final;
    wire [(OUTPUT_WIDTH-1):0] buffer_2_final_first, buffer_2_final_c0, buffer_2_final_c1;
    wire [(OUTPUT_WIDTH-1):0] buffer_2_final_c2, buffer_2_final_c3, buffer_2_final_c4;
    //buffer 3
    wire [(OUTPUT_WIDTH-1):0] buffer_3_final;
    wire [(OUTPUT_WIDTH-1):0] buffer_3_final_c0, buffer_3_final_c1, buffer_3_final_c2;
    wire [(OUTPUT_WIDTH-1):0] buffer_3_final_c3, buffer_3_final_c4;
    // Buffer 4 doesn't have any connections because it is only used during the START phase
    // Buffer control
    wire [2:0] buffer_ctrl;
    wire [2:0] buffer_ctrl_start, buffer_ctrl_final;
    wire [2:0] buffer_ctrl_final_first, buffer_ctrl_final_c0, buffer_ctrl_final_c1;
    wire [2:0] buffer_ctrl_final_c2, buffer_ctrl_final_c3, buffer_ctrl_final_c4;

    // Counter 255: these register and wire will count the number of 255 received
    // The width will be set as 32 bits for now and can be changed in the future
    reg [31:0] reg_counter_255;
    wire [31:0] counter_255;
    wire [31:0] counter_255_start, counter_255_middle, counter_255_final;
    wire [31:0] counter_255_final_first, counter_255_final_c4;

    // Other control variables
    reg reg_carry;
    wire carry;    // if FINAL phase and carry required to propagate inside the buffer
                                            // this variable will save the last position of the buffer that must be zero (255 + 1)
    reg [3:0] reg_status;                       // this variables here (reg and wire) save the status
    wire [3:0] status_flag;                     // The comparison between reg_status and status_flag will define if FINAL_first or FINAL_second

    wire [1:0] phase_flag;      // This flag will basically define what to do each cycle and it won't be saved
    wire mux_use_last_bit;      // This wire will be 1 when the OUT_4 is being used.

    // ============================================
    // Set the registers

    always @ (posedge clk) begin
        if(reset) begin
            reg_addr_write <= 4'd0;
            reg_addr_read <= 4'd0;
            reg_status <= 3'd0;
            reg_carry <= 1'd0;
            reg_counter_255 <= 0;
        end else begin
            reg_carry <= carry;
            reg_status <= status_flag;
            reg_addr_write <= addr_write;
            reg_addr_read <= addr_read;
            ctrl_mux_last_bit <= mux_use_last_bit;
            reg_counter_255 <= counter_255;
        end
    end


    // The following always basically defines what to do with the buffer each cycle
    always @ (posedge clk) begin
        case(buffer_ctrl)
            3'b011 : begin
                buffer[reg_addr_write] <= buffer_1;
                buffer[reg_addr_write+1] <= buffer_2;
                buffer[reg_addr_write+2] <= buffer_3;
            end
            3'b010 : begin
                buffer[reg_addr_write] <= buffer_1;
                buffer[reg_addr_write+1] <= buffer_2;
            end
            3'b001 : begin
                buffer[reg_addr_write] <= buffer_1;
            end
            3'b101 : begin
                buffer[reg_addr_write-1] <= buffer_1;
                buffer[reg_addr_write] <= buffer_2;
            end
            3'b110 : begin
                buffer[reg_addr_write-1] <= buffer_1;
                buffer[reg_addr_write] <= buffer_2;
                buffer[reg_addr_write] <= buffer_3;
            end
        endcase
    end
    // ===========================================================================
    // Main variables definition
    // Here are defined the main control variables
        // Status Flag: this flag defines when the buffer is:
            // 000 - empty
            // 111 - not empty (during execution)
            // 001 - Release (1 input and no carry propagation)
            // 010 - Release (1 input and carry propagation)
            // 100 - Release (2 inputs and carry propagation from in_bitstream_2)
            // 101 - Release (2 inputs and carry propagation between in_bitstream_1 and in_bitstream_2)
            // 110 - Release (2 inputs and carry propagation from in_bitstream_1)
            // 011 - Release (2 inputs greater that 255, so carry propagation through the buffer and both in_bitstreams)
    assign status_flag =    (flag_first) ? 4'b0000 :
                            ((reg_addr_write == 0) && (reg_addr_read == 0)) ? 4'b0000 :
                            ((reg_addr_write > 0) && (reg_addr_read == 0) && (in_flag == 2'b00)) ? 4'b0111 :
                            ((reg_addr_write > 0) && (reg_addr_read == 0) && (in_flag == 2'b01) && (in_bitstream_1 == 255)) ? 4'b0111 :
                            ((reg_addr_write > 0) && (reg_addr_read == 0) && (in_flag == 2'b11) && (in_bitstream_1 == 255) && (in_bitstream_2 == 255)) ? 4'b0111 :
                            ((reg_addr_write > 0) && (reg_addr_read == 0) && (in_flag == 2'b01) && (in_bitstream_1 < 255)) ? 4'b0001 :
                            ((reg_addr_write > 0) && (reg_addr_read == 0) && (in_flag == 2'b01) && (in_bitstream_1 > 255)) ? 4'b0010 :
                            ((reg_addr_write > 0) && (reg_addr_read == 0) && (in_flag == 2'b11) && (in_bitstream_1 == 255) && (in_bitstream_2 > 255)) ? 4'b0100 :
                            ((reg_addr_write > 0) && (reg_addr_read == 0) && (in_flag == 2'b11) && (in_bitstream_1 < 255) && (in_bitstream_2 > 255)) ? 4'b0101 :
                            ((reg_addr_write > 0) && (reg_addr_read == 0) && (in_flag == 2'b11) && (in_bitstream_1 > 255) && (in_bitstream_2 < 255)) ? 4'b0110 :
                            ((reg_addr_write > 0) && (reg_addr_read == 0) && (in_flag == 2'b11) && (in_bitstream_1 > 255) && (in_bitstream_2 > 255)) ? 4'b0011 :
                            ((reg_addr_write > 0) && (reg_addr_read == 0) && (in_flag == 2'b11) && (in_bitstream_1 < 255) && (in_bitstream_2 < 255)) ? 4'b1000 :
                            ((reg_status != 4'b0111) && (reg_status != 4'b0000) && (reg_addr_write > 0) && (reg_addr_read > 0)) ? reg_status :
                            4'b0000;

    // The variable Propag_zero will basically save the reg_write when the FINAL phase is defined
    assign carry =  ((status_flag == 4'b0010) || (status_flag == 4'b0110) || (status_flag == 4'b0011) && ((reg_status == 4'b0000) || (reg_status == 4'b0111))) ? 1'b1 :
                    ((status_flag == 4'b0100) && ((reg_status == 4'b0000) || (reg_status == 4'b0111))) ? 1'b1 :
                    ((reg_status != 4'b0111) && (reg_status != 4'b0000)) ? reg_carry :
                    1'd0;

    // The Phase Flag basically tells the higher variables of the hierarchy which sub-variable to use
    assign phase_flag = (flag_first) ? 2'd0 :
                        ((status_flag == 4'b0000) && (reg_addr_write == 0) && (reg_addr_read == 0)) ? 2'b01 :
                        ((status_flag == 4'b0111) && (reg_addr_write != 0) && (reg_addr_read == 0) && (in_flag == 2'b01) && (in_bitstream_1 != 255)) ? 2'b11 :
                        ((status_flag == 4'b0111) && (reg_addr_write != 0) && (reg_addr_read == 0) && (in_flag == 2'b11) && ((in_bitstream_1 != 255) || (in_bitstream_2 != 255))) ? 2'b11 :
                        ((status_flag == 4'b0111) && (reg_addr_write != 0) && (reg_addr_read == 0)) ? 2'b10 :
                        2'b11;

    // This control will set the 4th output pin reserved for bitstream
    assign mux_use_last_bit =   (out_flag == 3'b100) ? 1'b1 :
                                1'b0;

    // When the carry propagation is working, it is usually using the main carry propagation block.
        // The mux final is the component that controls which carry propagation block is being used
    // However, when two 255 are received, the mux_final pulls the responsability for the output bitstreams to the Aux Carry Propagation
    // The idea behind this ctrl is to identify when the responsability for the output pins should be with the aux carry or main carry
    assign ctrl_mux_final = ((!in_standby_flag) && (in_flag == 2'b11) && (in_bitstream_1 == 255) && (in_bitstream_2 == 255)) ? 1'b1 :
                            ((in_standby_flag) && (in_flag == 2'b01) && (in_bitstream_1 == 255)) ? 1'b1 :
                            ((in_standby_flag) && (in_flag == 2'b11) && (in_bitstream_1 == 255) && (in_bitstream_2 == 255)) ? 1'b1 :
                            (status_flag != 4'b0000) ? 1'b1 :
                            1'b0;


    // ===========================================================================
    // Buffer control
        // These variables here define the number of inputs into the buffer
        // As all other complex variables, this variable is separated in several sub-variables

    assign buffer_ctrl =    (phase_flag == 2'b00) ? 3'b000 :
                            (phase_flag == 2'b01) ? buffer_ctrl_start :
                            (phase_flag == 2'b11) ? buffer_ctrl_final :
                            3'b000;

    assign buffer_ctrl_start =  ((!in_standby_flag) && (in_flag == 2'b11) && (in_bitstream_1 == 255) && (in_bitstream_2 == 255)) ? 3'b001 :
                                ((in_standby_flag) && (in_flag == 2'b01) && (in_bitstream_1 == 255)) ? 3'b001 :
                                ((in_standby_flag) && (in_flag == 2'b11) && (in_bitstream_1 == 255) && (in_bitstream_2 == 255)) ? 3'b001 :
                                3'b000;

    assign buffer_ctrl_final =  (((reg_status == 4'b0111) || (reg_status == 4'b0000)) && (status_flag != 4'b0111) && (status_flag != 4'b0000)) ? buffer_ctrl_final_first :
                                ((status_flag != 4'b0000) && (reg_status == status_flag) && (reg_counter_255 == 0)) ? buffer_ctrl_final_c0 :
                                ((status_flag != 4'b0000) && (reg_status == status_flag) && (reg_counter_255 == 1)) ? buffer_ctrl_final_c1 :
                                ((status_flag != 4'b0000) && (reg_status == status_flag) && (reg_counter_255 == 2)) ? buffer_ctrl_final_c2 :
                                ((status_flag != 4'b0000) && (reg_status == status_flag) && (reg_counter_255 == 3)) ? buffer_ctrl_final_c3 :
                                ((status_flag != 4'b0000) && (reg_status == status_flag) && (reg_counter_255 >= 4)) ? buffer_ctrl_final_c4 :
                                3'b000;


    // This buffer_ctrl_final_first doesn't consider the in_flag or any bitstreams in the comparisons
        // because these values were already defined by Status_Flag
    assign buffer_ctrl_final_first =    ((reg_counter_255 >= 3) && ((status_flag == 4'b0001) || (status_flag == 4'b0010) || (status_flag == 4'b0100))) ? 3'b001 :
                                        ((reg_counter_255 >= 3) && ((status_flag == 4'b0101) || (status_flag == 4'b0110) || (status_flag == 4'b0011) || (status_flag == 4'b1000))) ? 3'b010 :
                                        3'b000;
    assign buffer_ctrl_final_c0 =
    assign buffer_ctrl_final_c1 =
    assign buffer_ctrl_final_c2 =
    assign buffer_ctrl_final_c3 =
    assign buffer_ctrl_final_c4 =

    // set the three main buffer variables
    assign buffer_1 =   (phase_flag == 2'b01) ? buffer_1_start :
                        (phase_flag == 2'b11) ? buffer_1_final :
                        8'd0;

    assign buffer_2 =   (phase_flag == 2'b11) ? buffer_2_final :
                        8'd0;

    assign buffer_3 =   (phase_flag == 2'b11) ? buffer_3_final :
                        8'd0;


    // First set of sub-variables for buffer
    // Buffer 1
    assign buffer_1_start = ((!in_standby_flag) && (in_flag == 2'b11) && (in_bitstream_1 == 255) && (in_bitstream_2 == 255)) ? in_previous_bitstream :
                            ((in_standby_flag) && (in_flag == 2'b01) && (in_bitstream_1 == 255)) ? in_standby_bitstream :
                            ((in_standby_flag) && (in_flag == 2'b11) && (in_bitstream_1 == 255) && (in_bitstream_2 == 255)) ? in_standby_bitstream :
                            8'd0;
    assign buffer_1_final =     (((reg_status == 4'b0111) || (reg_status == 4'b0000)) && (status_flag != 4'b0111) && (status_flag != 4'b0000)) ? buffer_1_final_first :
                                ((status_flag != 4'b0000) && (reg_status == status_flag) && (reg_counter_255 == 0)) ? buffer_1_final_c0 :
                                ((status_flag != 4'b0000) && (reg_status == status_flag) && (reg_counter_255 == 1)) ? buffer_1_final_c1 :
                                ((status_flag != 4'b0000) && (reg_status == status_flag) && (reg_counter_255 == 2)) ? buffer_1_final_c2 :
                                ((status_flag != 4'b0000) && (reg_status == status_flag) && (reg_counter_255 == 3)) ? buffer_1_final_c3 :
                                ((status_flag != 4'b0000) && (reg_status == status_flag) && (reg_counter_255 >= 4)) ? buffer_1_final_c4 :
                                3'b000;
    // Buffer 2
    assign buffer_2_final =     (((reg_status == 4'b0111) || (reg_status == 4'b0000)) && (status_flag != 4'b0111) && (status_flag != 4'b0000)) ? buffer_2_final_first :
                                ((status_flag != 4'b0000) && (reg_status == status_flag) && (reg_counter_255 == 0)) ? buffer_2_final_c0 :
                                ((status_flag != 4'b0000) && (reg_status == status_flag) && (reg_counter_255 == 1)) ? buffer_2_final_c1 :
                                ((status_flag != 4'b0000) && (reg_status == status_flag) && (reg_counter_255 == 2)) ? buffer_2_final_c2 :
                                ((status_flag != 4'b0000) && (reg_status == status_flag) && (reg_counter_255 == 3)) ? buffer_2_final_c3 :
                                ((status_flag != 4'b0000) && (reg_status == status_flag) && (reg_counter_255 >= 4)) ? buffer_2_final_c4 :
                                3'b000;
    // Buffer 3
    assign buffer_3_final =     (((reg_status == 4'b0111) || (reg_status == 4'b0000)) && (status_flag != 4'b0111) && (status_flag != 4'b0000)) ? buffer_3_final_first :
                                ((status_flag != 4'b0000) && (reg_status == status_flag) && (reg_counter_255 == 0)) ? buffer_3_final_c0 :
                                ((status_flag != 4'b0000) && (reg_status == status_flag) && (reg_counter_255 == 1)) ? buffer_3_final_c1 :
                                ((status_flag != 4'b0000) && (reg_status == status_flag) && (reg_counter_255 == 2)) ? buffer_3_final_c2 :
                                ((status_flag != 4'b0000) && (reg_status == status_flag) && (reg_counter_255 == 3)) ? buffer_3_final_c3 :
                                ((status_flag != 4'b0000) && (reg_status == status_flag) && (reg_counter_255 >= 4)) ? buffer_3_final_c4 :
                                3'b000;
    // --------
    // Sub sub-variables
    // Buffer 1 Final
    assign buffer_1_final_first =   ((reg_counter_255 >= 3) && ((status_flag == 4'b0001) || (status_flag == 4'b0010) || (status_flag == 4'b0100))) ? in_bitstream_1[(OUTPUT_WIDTH-1):0] :
                                    ((reg_counter_255 >= 3) && ((status_flag == 4'b0101) || (status_flag == 4'b0110) || (status_flag == 4'b0011) || (status_flag == 4'b1000))) ? in_bitstream_1[(OUTPUT_WIDTH-1):0] + in_bitstream_2[(INPUT_WIDTH-1):OUTPUT_WIDTH] :
                                    8'd0;
    assign buffer_1_final_c0 =
    assign buffer_1_final_c1 =
    assign buffer_1_final_c2 =
    assign buffer_1_final_c3 =
    assign buffer_1_final_c4 =

    // Buffer 2 Final
    assign buffer_2_final_first =  ((reg_counter_255 >= 3) && ((status_flag == 4'b0101) || (status_flag == 4'b0110) || (status_flag == 4'b0011) || (status_flag == 4'b1000))) ? in_bitstream_2[(OUTPUT_WIDTH-1):0] :
                                    8'd0;
    assign buffer_2_final_c0 =
    assign buffer_2_final_c1 =
    assign buffer_2_final_c2 =
    assign buffer_2_final_c3 =
    assign buffer_2_final_c4 =

    // Buffer 3 Final
    assign buffer_3_final_c0 =
    assign buffer_3_final_c1 =
    assign buffer_3_final_c2 =
    assign buffer_3_final_c3 =
    assign buffer_3_final_c4 =

    // ===========================================================================
    // Addresses definitions
    // All these variables identify different scenarios in the execution and, by checking flag_final and flag_start, they decide what to do with their addresses

    assign addr_write = (flag_first) ? 4'd0 :
                        (phase_flag == 2'b01) ? addr_write_start :
                        (phase_flag == 2'b10) ? reg_addr_write :
                        (phase_flag == 2'b11) ? addr_write_final :
                        4'd0;
    // Sub-variables for Addr Write
    assign addr_write_start =   ((!in_standby_flag) && (in_flag == 2'b11) && (in_bitstream_1 == 255) && (in_bitstream_2 == 255)) ? 4'd1 :
                                ((in_standby_flag) && (in_flag == 2'b01) && (in_bitstream_1 == 255)) ? 4'd1 :
                                ((in_standby_flag) && (in_flag == 2'b11) && (in_bitstream_1 == 255) && (in_bitstream_2 == 255)) ? 4'd1 :
                                4'd0;
    assign addr_write_final =   (((reg_status == 4'b0111) || (reg_status == 4'b0000)) && (status_flag != 4'b0111) && (status_flag != 4'b0000)) ? addr_write_final_first :
                                ((status_flag != 4'b0000) && (reg_status == status_flag) && (reg_counter_255 == 0)) ? addr_write_final_c0 :
                                ((status_flag != 4'b0000) && (reg_status == status_flag) && (reg_counter_255 == 1)) ? addr_write_final_c1 :
                                ((status_flag != 4'b0000) && (reg_status == status_flag) && (reg_counter_255 == 2)) ? addr_write_final_c2 :
                                ((status_flag != 4'b0000) && (reg_status == status_flag) && (reg_counter_255 == 3)) ? addr_write_final_c3 :
                                ((status_flag != 4'b0000) && (reg_status == status_flag) && (reg_counter_255 >= 4)) ? addr_write_final_c4 :
                                4'd0;

    // Sub sub-variables
    assign addr_write_final_first = ((reg_counter_255 >= 3) && ((status_flag == 4'b0001) || (status_flag == 4'b0010) || (status_flag == 4'b0100))) ? 4'd2 :
                                    ((reg_counter_255 >= 3) && ((status_flag == 4'b0101) || (status_flag == 4'b0110) || (status_flag == 4'b0011) || (status_flag == 4'b1000))) ? 4'd3 :
                                    4'd0;
    assign addr_write_final_c0 =
    assign addr_write_final_c1 =
    assign addr_write_final_c2 =
    assign addr_write_final_c3 =
    assign addr_write_final_c4 =


    // The addr_read basically tells the buffer which bitstreams must be released in the current clock cycle
    // All addr_read sub-variables here analyze different part of the execution and define, based on the analysis, what is the best way to update the addr
    assign addr_read =  (flag_first) ? 4'd0 :
                        (((reg_status == 4'b0111) || (reg_status == 4'b0000)) && (status_flag != 4'b0111) && (status_flag != 4'b0000)) ? addr_read_first :
                        ((status_flag != 4'b0000) && (reg_status == status_flag) && (reg_counter_255 == 0)) ? addr_read_c0 :
                        ((status_flag != 4'b0000) && (reg_status == status_flag) && (reg_counter_255 == 1)) ? addr_read_c1 :
                        ((status_flag != 4'b0000) && (reg_status == status_flag) && (reg_counter_255 == 2)) ? addr_read_c2 :
                        ((status_flag != 4'b0000) && (reg_status == status_flag) && (reg_counter_255 == 3)) ? addr_read_c3 :
                        ((status_flag != 4'b0000) && (reg_status == status_flag) && (reg_counter_255 >= 4)) ? addr_read_c4 :
                        4'd0;

    // Addr_read's sub-variables
    assign addr_read_first =    ((reg_counter_255 >= 3) && ((status_flag == 4'b0001) || (status_flag == 4'b0010) || (status_flag == 4'b0100))) ? 4'd1 :
                                ((reg_counter_255 >= 3) && ((status_flag == 4'b0101) || (status_flag == 4'b0110) || (status_flag == 4'b0011) || (status_flag == 4'b1000))) ? 4'd1 :
                                4'd0;
    assign addr_read_c0 =
    assign addr_read_c1 =
    assign addr_read_c2 =
    assign addr_read_c3 =
    assign addr_read_c4 =


    // ===========================================================================
    // Outputs
    // The output variables basically set the output pins for this block
    // Main variables
    assign out_bit_1 =  (((reg_status == 4'b0111) || (reg_status == 4'b0000)) && (status_flag != 4'b0111) && (status_flag != 4'b0000)) ? out_1_first :
                        ((status_flag != 4'b0000) && (reg_status == status_flag) && (reg_counter_255 == 0)) ? out_1_c0 :
                        ((status_flag != 4'b0000) && (reg_status == status_flag) && (reg_counter_255 == 1)) ? out_1_c1 :
                        ((status_flag != 4'b0000) && (reg_status == status_flag) && (reg_counter_255 == 2)) ? out_1_c2 :
                        ((status_flag != 4'b0000) && (reg_status == status_flag) && (reg_counter_255 == 3)) ? out_1_c3 :
                        ((status_flag != 4'b0000) && (reg_status == status_flag) && (reg_counter_255 >= 4)) ? out_1_c4 :
                        8'd0;
    assign out_bit_2 =  (((reg_status == 4'b0111) || (reg_status == 4'b0000)) && (status_flag != 4'b0111) && (status_flag != 4'b0000)) ? out_1_first :
                        ((status_flag != 4'b0000) && (reg_status == status_flag) && (reg_counter_255 == 0)) ? out_2_c0 :
                        ((status_flag != 4'b0000) && (reg_status == status_flag) && (reg_counter_255 == 1)) ? out_2_c1 :
                        ((status_flag != 4'b0000) && (reg_status == status_flag) && (reg_counter_255 == 2)) ? out_2_c2 :
                        ((status_flag != 4'b0000) && (reg_status == status_flag) && (reg_counter_255 == 3)) ? out_2_c3 :
                        ((status_flag != 4'b0000) && (reg_status == status_flag) && (reg_counter_255 >= 4)) ? out_2_c4 :
                        8'd0;
    assign out_bit_3 =  (((reg_status == 4'b0111) || (reg_status == 4'b0000)) && (status_flag != 4'b0111) && (status_flag != 4'b0000)) ? out_3_first :
                        ((status_flag != 4'b0000) && (reg_status == status_flag) && (reg_counter_255 == 0)) ? out_3_c0 :
                        ((status_flag != 4'b0000) && (reg_status == status_flag) && (reg_counter_255 == 1)) ? out_3_c1 :
                        ((status_flag != 4'b0000) && (reg_status == status_flag) && (reg_counter_255 == 2)) ? out_3_c2 :
                        ((status_flag != 4'b0000) && (reg_status == status_flag) && (reg_counter_255 == 3)) ? out_3_c3 :
                        ((status_flag != 4'b0000) && (reg_status == status_flag) && (reg_counter_255 >= 4)) ? out_3_c4 :
                        8'd0;
    assign out_bit_4 =  (((reg_status == 4'b0111) || (reg_status == 4'b0000)) && (status_flag != 4'b0111) && (status_flag != 4'b0000)) ? out_4_first :
                        ((status_flag != 4'b0000) && (reg_status == status_flag) && (reg_counter_255 == 0)) ? out_4_c0 :
                        ((status_flag != 4'b0000) && (reg_status == status_flag) && (reg_counter_255 == 1)) ? out_4_c1 :
                        ((status_flag != 4'b0000) && (reg_status == status_flag) && (reg_counter_255 == 2)) ? out_4_c2 :
                        ((status_flag != 4'b0000) && (reg_status == status_flag) && (reg_counter_255 == 3)) ? out_4_c3 :
                        ((status_flag != 4'b0000) && (reg_status == status_flag) && (reg_counter_255 >= 4)) ? out_4_c4 :
                        8'd0;

    // Flag definition - Main Variable
    assign out_flag =   (((reg_status == 4'b0111) || (reg_status == 4'b0000)) && (status_flag != 4'b0111) && (status_flag != 4'b0000)) ? out_flag_first :
                        ((status_flag != 4'b0000) && (reg_status == status_flag) && (reg_counter_255 == 0)) ? out_flag_c0 :
                        ((status_flag != 4'b0000) && (reg_status == status_flag) && (reg_counter_255 == 1)) ? out_flag_c1 :
                        ((status_flag != 4'b0000) && (reg_status == status_flag) && (reg_counter_255 == 2)) ? out_flag_c2 :
                        ((status_flag != 4'b0000) && (reg_status == status_flag) && (reg_counter_255 == 3)) ? out_flag_c3 :
                        ((status_flag != 4'b0000) && (reg_status == status_flag) && (reg_counter_255 >= 4)) ? out_flag_c4 :
                        8'd0;

    // Sub-variables
    // Out 1
    assign out_1_first = buffer[reg_addr_read] + carry;
    assign out_1_c0 =
    assign out_1_c1 =
    assign out_1_c2 =
    assign out_1_c3 =
    assign out_1_c4 =

    // Out 2
    assign out_2_first =    (carry == 1'b1) ? 8'd0 :
                            8'd255;
    assign out_2_c0 =
    assign out_2_c1 =
    assign out_2_c2 =
    assign out_2_c3 =
    assign out_2_c4 =

    // Out 3

    assign out_3_first =    (carry == 1'b1) ? 8'd0 :
                            8'd255;
    assign out_3_c0 =
    assign out_3_c1 =
    assign out_3_c2 =
    assign out_3_c3 =
    assign out_3_c4 =

    // Out 4

    assign out_4_first =    ((reg_counter_255 >= 3) && (carry == 1'b1)) ? 8'd0 :
                            ((reg_counter_255 >= 3) && (carry == 1'b0)) ? 8'd255 :
                            ((status_flag == 4'b0100) && (carry == 1'b1)) ? 8'd0 :
                            ((status_flag == 4'b0100) && (carry == 1'b0)) ? 8'd255 :
                            ((status_flag != 4'b0001) && (status_flag != 4'b0010) && (status_flag != 0100) && (reg_counter_255 == 2)) ? in_bitstream_1[(OUTPUT_WIDTH-1):0] + in_bitstream_2[(INPUT_WIDTH-1):OUTPUT_WIDTH] :
                            8'd0;

    assign out_4_c0 =
    assign out_4_c1 =
    assign out_4_c2 =
    assign out_4_c3 =
    assign out_4_c4 =

    // Out Flag

    assign out_flag_first = ((reg_counter_255 == 2) && ((status_flag == 4'b0001) || (status_flag == 4'b0010))) ? 3'b010 :
                            3'b100;
    assign out_flag_c0 =    ((in_flag != 2'b00) && ((reg_addr_write-reg_addr_read) >= 4)) ? 3'b100 :
                            ((in_flag == 2'b11) && ((reg_addr_write-reg_addr_read) == 3)) ? 3'b100 :
                            ((in_flag == 2'b11) && ((reg_addr_write-reg_addr_read) == 2))
    assign out_flag_c1 =
    assign out_flag_c2 =
    assign out_flag_c3 =
    assign out_flag_c4 =


    // Counter 255
    // Instead of saving into the buffer each one of the 255 received in this block
    // It is better to count that number and release each one of initial begin
    assign counter_255 =    (flag_first) ? 0 :
                            (phase_flag == 2'b01) ? counter_255_start :
                            (phase_flag == 2'b10) ? counter_255_middle :
                            (phase_flag == 2'b11) ? counter_255_final :
                            0;
    // Sub variables
    assign counter_255_start =  ((!in_standby_flag) && (in_flag == 2'b11) && (in_bitstream_1 == 255) && (in_bitstream_2 == 255)) ? 2 :
                                ((in_standby_flag) && (in_flag == 2'b01) && (in_bitstream_1 == 255)) ? 2 :
                                ((in_standby_flag) && (in_flag == 2'b11) && (in_bitstream_1 == 255) && (in_bitstream_2 == 255)) ? 3 :
                                0;
    assign counter_255_middle = (in_flag == 2'b01) ? reg_counter_255 + 1 :
                                (in_flag == 2'b11) ? reg_counter_255 + 2 :
                                reg_counter_255;
    assign counter_255_final =  (((reg_status == 4'b0111) || (reg_status == 4'b0000)) && (status_flag != 4'b0111) && (status_flag != 4'b0000)) ? counter_255_final_first :
                                ((status_flag != 4'b0000) && (reg_status == status_flag) && (reg_counter_255 >= 4)) ? counter_255_final_c4 :
                                0;

    // Sub sub-variables
    assign counter_255_final_first =    (reg_counter_255 >= 3) ? reg_counter_255 - 3 :
                                        0;
    assign counter_255_final_c4 =   (reg_counter_255 == 4) ? 0 :
                                    reg_counter_255 - 4;


endmodule
