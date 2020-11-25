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
    wire [(ADDR_WIDTH-1):0] addr_write_start, addr_write_middle, addr_write_final;
    wire [(ADDR_WIDTH-1):0] addr_write_final_first, addr_write_final_second_no_carry, addr_write_final_carry;
    reg [(ADDR_WIDTH-1):0] reg_addr_write;

    // addr_read
    wire [(ADDR_WIDTH-1):0] addr_read;
    wire [(ADDR_WIDTH-1):0] addr_read_first, addr_read_second_no_carry, addr_read_second_carry;
    reg [(ADDR_WIDTH-1):0] reg_addr_read;

    // connections for the 4 out_bit output pins
    wire [(OUTPUT_WIDTH-1):0] out_1_first, out_1_second_no_carry, out_1_second_carry;
    wire [(OUTPUT_WIDTH-1):0] out_2_first, out_2_second_no_carry, out_2_second_carry;
    wire [(OUTPUT_WIDTH-1):0] out_3_first, out_3_second_no_carry, out_3_second_carry;
    wire [(OUTPUT_WIDTH-1):0] out_4_first, out_4_second_no_carry, out_4_second_carry;
    wire [2:0] out_flag_first, out_flag_second_no_carry, out_flag_second_carry;

    // all wires related to the buffer operations
    wire [(OUTPUT_WIDTH-1):0] buffer_1, buffer_2, buffer_3, buffer_4;
    // buffer 1
    wire [(OUTPUT_WIDTH-1):0] buffer_1_final, buffer_1_middle, buffer_1_start;
    wire [(OUTPUT_WIDTH-1):0] buffer_1_final_first, buffer_1_final_second_no_carry, buffer_1_final_second_carry;
    // buffer 2
    wire [(OUTPUT_WIDTH-1):0] buffer_2_final, buffer_2_middle, buffer_2_start;
    wire [(OUTPUT_WIDTH-1):0] buffer_2_final_first, buffer_2_final_second_no_carry, buffer_2_final_second_carry;
    //buffer 3
    wire [(OUTPUT_WIDTH-1):0] buffer_3_final, buffer_3_middle, buffer_3_start;
    wire [(OUTPUT_WIDTH-1):0] buffer_3_final_second_no_carry, buffer_3_final_second_carry;
    // Buffer 4 doesn't have any connections because it is only used during the START phase
    // Buffer control
    wire [2:0] buffer_ctrl;
    wire [2:0] buffer_ctrl_start, buffer_ctrl_middle, buffer_ctrl_final;
    wire [2:0] buffer_ctrl_final_first, buffer_ctrl_final_second_no_carry, buffer_ctrl_final_second_carry;

    // Other control variables
    reg [(ADDR_WIDTH-1):0] reg_propag;
    wire [(ADDR_WIDTH-1):0] propag_zero;    // if FINAL phase and carry required to propagate inside the buffer
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
            reg_propag <= 4'd0;
        end else begin
            reg_propag <= propag_zero;
            reg_status <= status_flag;
            reg_addr_write <= addr_write;
            reg_addr_read <= addr_read;
            ctrl_mux_last_bit <= mux_use_last_bit;
        end
    end


    // The following always basically defines what to do with the buffer each cycle
    always @ (posedge clk) begin
        case(buffer_ctrl)
            3'b100 : begin
                buffer[reg_addr_write] <= buffer_1;
                buffer[reg_addr_write+1] <= buffer_2;
                buffer[reg_addr_write+2] <= buffer_3;
                buffer[reg_addr_write+3] <= buffer_4;
            end
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
    assign propag_zero =    ((status_flag == 4'b0010) || (status_flag == 4'b0110) || (status_flag == 4'b0011) && ((reg_status == 4'b0000) || (reg_status == 4'b0111))) ? reg_addr_write :
                            ((status_flag == 4'b0100) && ((reg_status == 4'b0000) || (reg_status == 4'b0111))) ? reg_addr_write + 4'd1 :
                            ((reg_status != 4'b0111) && (reg_status != 4'b0000)) ? reg_propag :
                            4'd0;

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
                            (phase_flag == 2'b10) ? buffer_ctrl_middle :
                            (phase_flag == 2'b11) ? buffer_ctrl_final :
                            3'b000;

    assign buffer_ctrl_start =  ((!in_standby_flag) && (in_flag == 2'b11) && (in_bitstream_1 == 255) && (in_bitstream_2 == 255)) ? 3'b011 :
                                ((in_standby_flag) && (in_flag == 2'b01) && (in_bitstream_1 == 255)) ? 3'b011 :
                                ((in_standby_flag) && (in_flag == 2'b11) && (in_bitstream_1 == 255) && (in_bitstream_2 == 255)) ? 3'b100 :
                                3'b000;
    assign buffer_ctrl_middle = ((in_flag == 2'b01) && (status_flag == 4'b0111)) ? 3'b001 :
                                ((in_flag == 2'b11) && (status_flag == 4'b0111)) ? 3'b010 :
                                3'b000;
    assign buffer_ctrl_final =  (((reg_status == 4'b0111) || (reg_status == 4'b0000)) && (status_flag != 4'b0111) && (status_flag != 4'b0000)) ? buffer_ctrl_final_first :
                                ((status_flag != 4'b0000) && (reg_status == status_flag) && (reg_addr_read >= propag_zero)) ? buffer_ctrl_final_second_no_carry :
                                ((reg_status == status_flag) && (reg_addr_read < propag_zero)) ? buffer_ctrl_final_second_carry :
                                3'b000;


    // This buffer_ctrl_final_first doesn't consider the in_flag or any bitstreams in the comparisons
        // because these values were already defined by Status_Flag
    assign buffer_ctrl_final_first =    (((status_flag == 4'b0001) || (status_flag == 4'b0010)) && (reg_addr_write > 4)) ? 3'b001 :
                                        (((status_flag == 4'b0100) || (status_flag == 4'b0101) || (status_flag == 4'b0110) || (status_flag == 4'b1000)) && (reg_addr_write > 3)) ? 3'b010 :
                                        ((status_flag == 4'b0011) && (reg_addr_write > 3)) ? 3'b010 :
                                        3'b000;
    assign buffer_ctrl_final_second_no_carry =  ((in_flag == 2'b01) && ((reg_addr_write - reg_addr_read) == 4)) ? 3'b001 :
                                                ((in_flag == 2'b11) && ((reg_addr_write - reg_addr_read) == 4)) ? 3'b010 :
                                                ((in_flag == 2'b01) && (in_bitstream_1 < 255) && ((reg_addr_write - reg_addr_read) > 4)) ? 3'b001 :
                                                ((in_flag == 2'b01) && (in_bitstream_1 > 255) && ((reg_addr_write - reg_addr_read) > 4)) ? 3'b101 :
                                                ((in_flag == 2'b11) && (in_bitstream_1 < 255) && ((reg_addr_write - reg_addr_read) > 4)) ? 3'b010 :
                                                ((in_flag == 2'b11) && (in_bitstream_1 > 255) && ((reg_addr_write - reg_addr_read) > 4)) ? 3'b110 :
                                                3'b000;
    // When it's necessary to propagate a carry through all 255 bitstreams saved into the buffer
    // The propagation will be done without throwing out the bitstream != 255
    // For that, all new values will be saved into the buffer
    assign buffer_ctrl_final_second_carry = (in_flag == 2'b01) ? 3'b101 :
                                            (in_flag == 2'b11) ? 3'b110 :
                                            3'b000;


    // set the three main buffer variables
    assign buffer_1 =   (phase_flag == 2'b01) ? buffer_1_start :
                        (phase_flag == 2'b10) ? buffer_1_middle :
                        (phase_flag == 2'b11) ? buffer_1_final :
                        8'd0;

    assign buffer_2 =   (phase_flag == 2'b01) ? buffer_2_start :
                        (phase_flag == 2'b10) ? buffer_2_middle :
                        (phase_flag == 2'b11) ? buffer_2_final :
                        8'd0;

    assign buffer_3 =   (phase_flag == 2'b01) ? buffer_3_start :
                        (phase_flag == 2'b10) ? buffer_3_middle :
                        (phase_flag == 2'b11) ? buffer_3_final :
                        8'd0;

    // The buffer 4 doesn't have sub-variables because it is used only during the Start Phase
    assign buffer_4 =   ((in_standby_flag) && (in_flag == 2'b11) && (in_bitstream_1 == 255) && (in_bitstream_2 == 255)) ? in_bitstream_2[(OUTPUT_WIDTH-1):0] :
                        8'd0;

    // First set of sub-variables for buffer
    // Buffer 1
    assign buffer_1_start = ((!in_standby_flag) && (in_flag == 2'b11) && (in_bitstream_1 == 255) && (in_bitstream_2 == 255)) ? in_previous_bitstream :
                            ((in_standby_flag) && (in_flag == 2'b01) && (in_bitstream_1 == 255)) ? in_standby_bitstream :
                            ((in_standby_flag) && (in_flag == 2'b11) && (in_bitstream_1 == 255) && (in_bitstream_2 == 255)) ? in_standby_bitstream :
                            8'd0;
    assign buffer_1_middle =    ((in_flag == 2'b01) && (status_flag == 4'b0111)) ? in_bitstream_1[(OUTPUT_WIDTH-1):0] :
                                ((in_flag == 2'b11) && (status_flag == 4'b0111)) ? in_bitstream_1[(OUTPUT_WIDTH-1):0] :
                                8'd0;
    assign buffer_1_final =     (((reg_status == 4'b0111) || (reg_status == 4'b0000)) && (status_flag != 4'b0111) && (status_flag != 4'b0000)) ? buffer_1_final_first :
                                ((status_flag != 4'b0000) && (reg_status == status_flag) && (reg_addr_read >= propag_zero)) ? buffer_1_final_second_no_carry :
                                ((reg_status == status_flag) && (reg_addr_read < propag_zero)) ? buffer_1_final_second_carry :
                                8'd0;
    // Buffer 2
    assign buffer_2_start = ((!in_standby_flag) && (in_flag == 2'b11) && (in_bitstream_1 == 255) && (in_bitstream_2 == 255)) ? in_bitstream_1[(OUTPUT_WIDTH-1):0] :
                            ((in_standby_flag) && (in_flag == 2'b01) && (in_bitstream_1 == 255)) ? in_previous_bitstream :
                            ((in_standby_flag) && (in_flag == 2'b11) && (in_bitstream_1 == 255) && (in_bitstream_2 == 255)) ? in_previous_bitstream :
                            8'd0;
    assign buffer_2_middle =    ((in_flag == 2'b11) && (status_flag == 4'b0111)) ? in_bitstream_2[(OUTPUT_WIDTH-1):0] :
                                8'd0;
    assign buffer_2_final =     (((reg_status == 4'b0111) || (reg_status == 4'b0000)) && (status_flag != 4'b0111) && (status_flag != 4'b0000)) ? buffer_2_final_first :
                                ((status_flag != 4'b0000) && (reg_status == status_flag) && (reg_addr_read >= propag_zero)) ? buffer_2_final_second_no_carry :
                                ((reg_status == status_flag) && (reg_addr_read < propag_zero)) ? buffer_2_final_second_carry :
                                8'd0;
    // Buffer 3
    assign buffer_3_start = ((!in_standby_flag) && (in_flag == 2'b11) && (in_bitstream_1 == 255) && (in_bitstream_2 == 255)) ? in_bitstream_2[(OUTPUT_WIDTH-1):0] :
                            ((in_standby_flag) && (in_flag == 2'b01) && (in_bitstream_1 == 255)) ? in_bitstream_1[(OUTPUT_WIDTH-1):0] :
                            ((in_standby_flag) && (in_flag == 2'b11) && (in_bitstream_1 == 255) && (in_bitstream_2 == 255)) ? in_bitstream_1[(OUTPUT_WIDTH-1):0] :
                            8'd0;
    assign buffer_3_middle =    8'd0;   // Not used during the Middle Phase
    assign buffer_3_final =     ((status_flag != 4'b0000) && (reg_status == status_flag) && (reg_addr_read >= propag_zero)) ? buffer_3_final_second_no_carry :
                                ((reg_status == status_flag) && (reg_addr_read < propag_zero)) ? buffer_3_final_second_carry :
                                8'd0;
    // --------
    // Sub sub-variables
    // Buffer 1 Final
    assign buffer_1_final_first =   (((status_flag == 4'b0001) || (status_flag == 4'b0010)) && (reg_addr_write > 4)) ? in_bitstream_1[(OUTPUT_WIDTH-1):0] :
                                    ((status_flag == 4'b0101) && (reg_addr_write > 3)) ? in_bitstream_1[(OUTPUT_WIDTH-1):0] + 1 :
                                    (((status_flag == 4'b0110) || (status_flag == 4'b1000)) && (reg_addr_write > 3)) ? in_bitstream_1[(OUTPUT_WIDTH-1):0] :
                                    ((status_flag == 4'b0011) && (reg_addr_write == 3)) ? 8'd0 :
                                    ((status_flag == 4'b0011) && (reg_addr_write > 3)) ? in_bitstream_1[(OUTPUT_WIDTH-1):0] + 1 :
                                    8'd0;
    assign buffer_1_final_second_no_carry = ((in_flag == 2'b01) && ((reg_addr_write - reg_addr_read) == 4)) ? in_bitstream_1[(OUTPUT_WIDTH-1):0] :
                                            ((in_flag == 2'b11) && (in_bitstream_1 != 255) && ((reg_addr_write - reg_addr_read) == 4)) ? in_bitstream_1[(OUTPUT_WIDTH-1):0] + in_bitstream_2[(INPUT_WIDTH-1):OUTPUT_WIDTH] :
                                            ((in_flag == 2'b01) && (in_bitstream_1 < 255) && ((reg_addr_write - reg_addr_read) > 4)) ? in_bitstream_1[(OUTPUT_WIDTH-1):0] :
                                            ((in_flag == 2'b01) && (in_bitstream_1 > 255) && ((reg_addr_write - reg_addr_read) > 4)) ? buffer[reg_addr_write-1] + 8'd1 :
                                            ((in_flag == 2'b11) && (in_bitstream_1 < 255) && ((reg_addr_write - reg_addr_read) > 4)) ? in_bitstream_1[(OUTPUT_WIDTH-1):0] + in_bitstream_2[(INPUT_WIDTH-1):OUTPUT_WIDTH] :
                                            ((in_flag == 2'b11) && (in_bitstream_1 > 255) && ((reg_addr_write - reg_addr_read) > 4)) ? buffer[reg_addr_write-1] + 8'd1 :
                                            8'd0;
    assign buffer_1_final_second_carry =    ((in_flag == 2'b01) || (in_flag == 2'b11)) ? buffer[reg_addr_write-1] + in_bitstream_1[(INPUT_WIDTH-1):OUTPUT_WIDTH] :
                                            8'd0;
    // Buffer 2 Final
    assign buffer_2_final_first =   (((status_flag == 4'b0100) || (status_flag == 4'b0101) || (status_flag == 4'b0110)) && (reg_addr_write > 3)) ? in_bitstream_2[(OUTPUT_WIDTH-1):0] :
                                    (((status_flag == 4'b0011) || (status_flag == 4'b1000)) && (reg_addr_write > 3)) ? in_bitstream_2[(OUTPUT_WIDTH-1):0] :
                                    8'd0;
    assign buffer_2_final_second_no_carry = ((in_flag == 2'b11) && (in_bitstream_1 != 255) && ((reg_addr_write - reg_addr_read) == 4)) ? in_bitstream_2[(OUTPUT_WIDTH-1):0] :
                                            ((in_flag == 2'b01) && (in_bitstream_1 > 255) && ((reg_addr_write - reg_addr_read) > 4)) ? in_bitstream_1[(OUTPUT_WIDTH-1):0] :
                                            ((in_flag == 2'b11) && (in_bitstream_1 < 255) && ((reg_addr_write - reg_addr_read) > 4)) ? in_bitstream_2[(OUTPUT_WIDTH-1):0] :
                                            ((in_flag == 2'b11) && (in_bitstream_1 > 255) && ((reg_addr_write - reg_addr_read) > 4)) ? in_bitstream_1[(OUTPUT_WIDTH-1):0] + in_bitstream_2[(INPUT_WIDTH-1):OUTPUT_WIDTH] :
                                            8'd0;
    assign buffer_2_final_second_carry =    (in_flag == 2'b01) ? in_bitstream_1[(OUTPUT_WIDTH-1):0] :
                                            (in_flag == 2'b11) ? in_bitstream_1[(OUTPUT_WIDTH-1):0] + in_bitstream_2[(INPUT_WIDTH-1):OUTPUT_WIDTH] :
                                            8'd0;
    // Buffer 3 Final
    assign buffer_3_final_second_no_carry = ((in_flag == 2'b11) && (in_bitstream_1 > 255) && ((reg_addr_write - reg_addr_read) > 4)) ? in_bitstream_2[(OUTPUT_WIDTH-1):0] :
                                            8'd0;
    assign buffer_3_final_second_carry =    (in_flag == 2'b11) ? in_bitstream_2[(OUTPUT_WIDTH-1):0] :
                                            8'd0;

    // ===========================================================================
    // Addresses definitions
    // All these variables identify different scenarios in the execution and, by checking flag_final and flag_start, they decide what to do with their addresses

    assign addr_write = (flag_first) ? 4'd0 :
                        (phase_flag == 2'b01) ? addr_write_start :
                        (phase_flag == 2'b10) ? addr_write_middle :
                        (phase_flag == 2'b11) ? addr_write_final :
                        4'd0;
    // Sub-variables for Addr Write
    assign addr_write_start =   ((!in_standby_flag) && (in_flag == 2'b11) && (in_bitstream_1 == 255) && (in_bitstream_2 == 255)) ? reg_addr_write + 4'd3 :
                                ((in_standby_flag) && (in_flag == 2'b01) && (in_bitstream_1 == 255)) ? reg_addr_write + 4'd3 :
                                ((in_standby_flag) && (in_flag == 2'b11) && (in_bitstream_1 == 255) && (in_bitstream_2 == 255)) ? reg_addr_write + 4'd4 :
                                reg_addr_write;
    assign addr_write_middle =  ((in_flag == 2'b01) && (status_flag == 4'b0111)) ? reg_addr_write + 4'd1 :
                                ((in_flag == 2'b11) && (status_flag == 4'b0111)) ? reg_addr_write + 4'd2 :
                                reg_addr_write;
    assign addr_write_final =   (((reg_status == 4'b0111) || (reg_status == 4'b0000)) && (status_flag != 4'b0111) && (status_flag != 4'b0000)) ? addr_write_final_first :
                                ((status_flag != 4'b0000) && (reg_status == status_flag) && (reg_addr_read >= propag_zero)) ? addr_write_final_second_no_carry :
                                ((reg_status == status_flag) && (reg_addr_read < propag_zero)) ? addr_write_final_carry :
                                4'd0;

    // Sub sub-variables
    assign addr_write_final_first = (((status_flag == 4'b0001) || (status_flag == 4'b0010)) && (reg_addr_write > 4)) ? reg_addr_write + 4'd1 :
                                    (((status_flag == 4'b0100) || (status_flag == 4'b0101) || (status_flag == 4'b0110) || (status_flag == 4'b1000)) && (reg_addr_write > 3)) ? reg_addr_write + 4'd2 :
                                    ((status_flag == 4'b0011) && (reg_addr_write > 3)) ? reg_addr_write + 4'd2 :
                                    4'd0;
    assign addr_write_final_second_no_carry =   ((in_flag == 2'b01) && ((reg_addr_write - reg_addr_read) == 4)) ? reg_addr_write + 4'd1 :
                                                ((in_flag == 2'b11) && (in_bitstream_1 != 255) && ((reg_addr_write - reg_addr_read) == 4)) ? reg_addr_write + 4'd2 :
                                                ((in_flag == 2'b00) && ((reg_addr_write - reg_addr_read) > 4)) ? reg_addr_write :
                                                ((in_flag == 2'b01) && (in_bitstream_1 < 255) && ((reg_addr_write - reg_addr_read) > 4)) ? reg_addr_write + 4'd1 :
                                                ((in_flag == 2'b01) && (in_bitstream_1 > 255) && ((reg_addr_write - reg_addr_read) > 4)) ? reg_addr_write + 4'd1 :
                                                ((in_flag == 2'b11) && (in_bitstream_1 < 255) && ((reg_addr_write - reg_addr_read) > 4)) ? reg_addr_write + 4'd2 :
                                                ((in_flag == 2'b11) && (in_bitstream_1 > 255) && ((reg_addr_write - reg_addr_read) > 4)) ? reg_addr_write + 4'd2 :
                                                4'd0;
    assign addr_write_final_carry = (in_flag == 2'b00) ? reg_addr_write :
                                    (in_flag == 2'b01) ? reg_addr_write + 4'd1 :
                                    (in_flag == 2'b11) ? reg_addr_write + 4'd2 :
                                    4'd0;


    // The addr_read basically tells the buffer which bitstreams must be released in the current clock cycle
    // All addr_read sub-variables here analyze different part of the execution and define, based on the analysis, what is the best way to update the addr
    assign addr_read =  (flag_first) ? 4'd0 :
                        (((reg_status == 4'b0111) || (reg_status == 4'b0000)) && (status_flag != 4'b0111) && (status_flag != 4'b0000)) ? addr_read_first :
                        ((status_flag != 4'b0000) && (reg_status == status_flag) && (reg_addr_read >= propag_zero)) ? addr_read_second_no_carry :
                        ((reg_status == status_flag) && (reg_addr_read < propag_zero)) ? addr_read_second_carry :
                        4'd0;

    // Addr_read's sub-variables
    assign addr_read_first =    (((status_flag == 4'b0001) || (status_flag == 4'b0010)) && (reg_addr_write > 4)) ? reg_addr_read + 4'd4 :
                                (((status_flag == 4'b0100) || (status_flag == 4'b0101) || (status_flag == 4'b0110) || (status_flag == 4'b1000)) && (reg_addr_write > 3)) ? reg_addr_read + 4'd4 :
                                ((status_flag == 4'b0011) && (reg_addr_write > 3)) ? reg_addr_read + 4'd4 :
                                4'd0;
    assign addr_read_second_no_carry =  ((in_flag == 2'b01) && ((reg_addr_write - reg_addr_read) == 4)) ? reg_addr_read + 4'd4 :
                                        ((in_flag == 2'b11) && (in_bitstream_1 != 255) && ((reg_addr_write - reg_addr_read) == 4)) ? reg_addr_read + 4'd4 :
                                        ((in_flag == 2'b00) && ((reg_addr_write - reg_addr_read) > 4)) ? reg_addr_read + 4'd4 :
                                        ((in_flag == 2'b01) && (in_bitstream_1 < 255) && ((reg_addr_write - reg_addr_read) > 4)) ? reg_addr_read + 4'd4 :
                                        ((in_flag == 2'b01) && (in_bitstream_1 > 255) && ((reg_addr_write - reg_addr_read) > 4)) ? reg_addr_read + 4'd4 :
                                        ((in_flag == 2'b11) && (in_bitstream_1 < 255) && ((reg_addr_write - reg_addr_read) > 4)) ? reg_addr_read + 4'd4 :
                                        ((in_flag == 2'b11) && (in_bitstream_1 > 255) && ((reg_addr_write - reg_addr_read) > 4)) ? reg_addr_read + 4'd4 :
                                        4'd0;
    assign addr_read_second_carry = (in_flag == 2'b00) ? reg_addr_read + 4'd1 :
                                    (in_flag == 2'b01) ? reg_addr_read + 4'd1 :
                                    (in_flag == 2'b11) ? reg_addr_read + 4'd1 :
                                    4'd0;


    // ===========================================================================
    // Outputs
    // The output variables basically set the output pins for this block
    // Main variables
    assign out_bit_1 =  (((reg_status == 4'b0111) || (reg_status == 4'b0000)) && (status_flag != 4'b0111) && (status_flag != 4'b0000)) ? out_1_first :
                        ((status_flag != 4'b0000) && (reg_status == status_flag) && (reg_addr_read >= propag_zero) && (reg_addr_read > 0)) ? out_1_second_no_carry :
                        ((reg_status == status_flag) && (reg_addr_read < propag_zero)) ? out_1_second_carry :
                        4'd0;
    assign out_bit_2 =  (((reg_status == 4'b0111) || (reg_status == 4'b0000)) && (status_flag != 4'b0111) && (status_flag != 4'b0000)) ? out_2_first :
                        ((status_flag != 4'b0000) && (reg_status == status_flag) && (reg_addr_read >= propag_zero) && (reg_addr_read > 0)) ? out_2_second_no_carry :
                        ((reg_status == status_flag) && (reg_addr_read < propag_zero)) ? out_2_second_carry :
                        4'd0;
    assign out_bit_3 =  (((reg_status == 4'b0111) || (reg_status == 4'b0000)) && (status_flag != 4'b0111) && (status_flag != 4'b0000)) ? out_3_first :
                        ((status_flag != 4'b0000) && (reg_status == status_flag) && (reg_addr_read >= propag_zero) && (reg_addr_read > 0)) ? out_3_second_no_carry :
                        ((reg_status == status_flag) && (reg_addr_read < propag_zero)) ? out_3_second_carry :
                        4'd0;
    assign out_bit_4 =  (((reg_status == 4'b0111) || (reg_status == 4'b0000)) && (status_flag != 4'b0111) && (status_flag != 4'b0000)) ? out_4_first :
                        ((status_flag != 4'b0000) && (reg_status == status_flag) && (reg_addr_read >= propag_zero) && (reg_addr_read > 0)) ? out_4_second_no_carry :
                        ((reg_status == status_flag) && (reg_addr_read < propag_zero)) ? out_4_second_carry :
                        4'd0;

    // Flag definition - Main Variable
    assign out_flag =   (((reg_status == 4'b0111) || (reg_status == 4'b0000)) && (status_flag != 4'b0111) && (status_flag != 4'b0000)) ? out_flag_first :
                        ((status_flag != 4'b0000) && (reg_status == status_flag) && (reg_addr_read >= propag_zero) && (reg_addr_read > 0)) ? out_flag_second_no_carry :
                        ((reg_status == status_flag) && (reg_addr_read < propag_zero)) ? out_flag_second_carry :
                        4'd0;

    // Sub-variables
    // Out 1
    assign out_1_first =    ((status_flag == 4'b0001) || (status_flag == 4'b0101) || (status_flag == 4'b1000)) ? buffer[reg_addr_read] :
                            ((status_flag == 4'b0010) || (status_flag == 4'b0000) || (status_flag == 4'b0110) || (status_flag == 4'b0011)) ? buffer[reg_addr_read] + 8'd1 :
                            8'd0;
    assign out_1_second_no_carry =  ((in_flag == 2'b00) && ((reg_addr_write - reg_addr_read) < 2)) ? 8'd0 :
                                    (((in_flag == 2'b01) || (in_flag == 2'b11)) && ((reg_addr_write - reg_addr_read) < 2)) ? buffer[addr_read] + in_bitstream_1[(INPUT_WIDTH-1):OUTPUT_WIDTH] :
                                    buffer[addr_read];
    assign out_1_second_carry = 8'd0;

    // Out 2
    assign out_2_first =    ((status_flag == 4'b0001) || (status_flag == 4'b0101) || (status_flag == 4'b1000)) ? buffer[reg_addr_read+1] :
                            8'd0;
    assign out_2_second_no_carry =  ((in_flag == 2'b00) && ((reg_addr_write - reg_addr_read) <= 2)) ? 8'd0 :
                                    ((in_flag == 2'b01) && ((reg_addr_write - reg_addr_read) < 2)) ? 8'd0 :
                                    ((in_flag == 2'b11) && ((reg_addr_write - reg_addr_read) < 2)) ? in_bitstream_1[(OUTPUT_WIDTH-1):0] + in_bitstream_2[(INPUT_WIDTH-1):OUTPUT_WIDTH] :
                                    ((reg_addr_write - reg_addr_read) == 2) ? buffer[reg_addr_read+1] + in_bitstream_1[(OUTPUT_WIDTH-1):0] :
                                    buffer[reg_addr_read+1];
    assign out_2_second_carry = 8'd0;

    // Out 3
    assign out_3_first =    ((status_flag == 4'b0001) || (status_flag == 4'b0101) || (status_flag == 4'b1000)) ? buffer[reg_addr_read+2] :
                            8'd0;
    assign out_3_second_no_carry =  ((reg_addr_write - reg_addr_read) < 2) ? 8'd0 :
                                    (((in_flag == 2'b01) || (in_flag == 2'b00)) && ((reg_addr_write - reg_addr_read) == 2)) ? 8'd0 :
                                    ((in_flag == 2'b11) && (in_bitstream_1 != 255) && ((reg_addr_write - reg_addr_read) == 2)) ? in_bitstream_1[(OUTPUT_WIDTH-1):0] + in_bitstream_2[(INPUT_WIDTH-1):OUTPUT_WIDTH] :
                                    ((in_flag == 2'b00) && ((reg_addr_write - reg_addr_read) == 3)) ? 8'd0 :
                                    ((in_flag == 2'b01) && ((reg_addr_write - reg_addr_read) == 3)) ? buffer[reg_addr_read+2] + in_bitstream_1[(INPUT_WIDTH-1):OUTPUT_WIDTH] :
                                    ((in_flag == 2'b11) && (in_bitstream_1 != 255) && ((reg_addr_write - reg_addr_read) == 3)) ? buffer[reg_addr_read+2] + in_bitstream_1[(INPUT_WIDTH-1):OUTPUT_WIDTH] :
                                    buffer[reg_addr_read+2];
    assign out_3_second_carry = 8'd0;
    // Out 4
    assign out_4_first =    ((status_flag == 4'b0001) && (reg_addr_write >= 4)) ? buffer[reg_addr_read+3] :
                            ((status_flag == 4'b0101) && (reg_addr_write == 3)) ? in_bitstream_1[(OUTPUT_WIDTH-1):0] + 8'd1 :
                            ((status_flag == 4'b0101) && (reg_addr_write > 3)) ? buffer[reg_addr_read+3] :
                            ((status_flag == 4'b0110) && (reg_addr_write == 3)) ? in_bitstream_1[(OUTPUT_WIDTH-1):0] :
                            ((status_flag == 4'b0011) && (reg_addr_write == 3)) ? in_bitstream_1[(OUTPUT_WIDTH-1):0] + 8'd1 :
                            ((status_flag == 4'b0011) && (reg_addr_write > 3)) ? 8'd0 :
                            ((status_flag == 4'b1000) && (reg_addr_write == 3)) ? in_bitstream_1[(OUTPUT_WIDTH-1):0] :
                            ((status_flag == 4'b1000) && (reg_addr_write > 3)) ? buffer[addr_read+3] :
                            8'd0;
    assign out_4_second_no_carry =  ((reg_addr_write - reg_addr_read) == 2) ? 8'd0 :
                                    ((in_flag == 2'b11) && (in_bitstream_1 != 255) && ((reg_addr_write - reg_addr_read) == 3)) ? in_bitstream_1[(OUTPUT_WIDTH-1):0] :
                                    ((reg_addr_write - reg_addr_read) == 3) ? 8'd0 :
                                    ((in_flag == 2'b01) && ((reg_addr_write - reg_addr_read) == 4)) ? buffer[reg_addr_read+3] + in_bitstream_1[(INPUT_WIDTH-1):OUTPUT_WIDTH] :
                                    ((in_flag == 2'b11) && (in_bitstream_1 != 255) && ((reg_addr_write - reg_addr_read) == 4)) ? buffer[reg_addr_read+3] + in_bitstream_1[(INPUT_WIDTH-1):OUTPUT_WIDTH] :
                                    buffer[reg_addr_read+3];
    assign out_4_second_carry = 8'd0;
    // Out Flag
    assign out_flag_first = ((status_flag == 4'b0001) && (reg_addr_write == 3)) ? 3'b010 :
                            ((status_flag == 4'b0001) && (reg_addr_write == 4)) ? 3'b100 :
                            ((status_flag == 4'b0001) && (reg_addr_write > 4)) ? 3'b100 :
                            // Status Flag = 010
                            ((status_flag == 4'b0010) && (reg_addr_write == 3)) ? 3'b010 :
                            ((status_flag == 4'b0010) && (reg_addr_write == 4)) ? 3'b100 :
                            ((status_flag == 4'b0010) && (reg_addr_write > 4)) ? 3'b100 :
                            3'b100;

    assign out_flag_second_no_carry =   ((in_flag == 2'b00) && ((reg_addr_write - reg_addr_read) < 2)) ? 3'b000 :
                                        ((in_flag == 2'b01) && ((reg_addr_write - reg_addr_read) < 2)) ? 3'b001 :
                                        ((in_flag == 2'b11) && ((reg_addr_write - reg_addr_read) < 2)) ? 3'b011 :
                                        ((in_flag == 2'b00) && ((reg_addr_write - reg_addr_read) == 2)) ? 3'b001 :
                                        ((in_flag == 2'b01) && ((reg_addr_write - reg_addr_read) == 2)) ? 3'b011 :
                                        ((in_flag == 2'b11) && ((reg_addr_write - reg_addr_read) == 2)) ? 3'b010 :
                                        ((in_flag == 2'b00) && ((reg_addr_write - reg_addr_read) == 3)) ? 3'b011 :
                                        ((in_flag == 2'b01) && ((reg_addr_write - reg_addr_read) == 3)) ? 3'b010 :
                                        3'b100;
    assign out_flag_second_carry =  ((reg_propag - reg_addr_read) == 1) ? 3'b001 :
                                    ((reg_propag - reg_addr_read) == 2) ? 3'b011 :
                                    ((reg_propag - reg_addr_read) == 3) ? 3'b010 :
                                    ((reg_propag - reg_addr_read) > 4) ? 3'b100 :
                                    3'd0;

endmodule
