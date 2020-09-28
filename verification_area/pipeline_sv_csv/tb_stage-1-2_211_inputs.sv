// This testbench will incorporate the registers and control signals from the top entity.
// It imports both Stages (1 and 2), creates a register connecting them and send values for input_range and input_low.
// As there isn't a normalize stage here, the input_range and input_low must to be send as inputs in the Stage 2.

    // The verification is made between Normalize Input Range and Low, which represents the output for stages 1 and 2.
    // All values were inserted into the file from the reference algorithm.

module tb_stage_1_2 #(
    parameter TB_RANGE_WIDTH = 16,
    parameter TB_LOW_WIDTH = 24,
    parameter TB_SYMBOL_WIDTH = 4,
    parameter TB_LUT_ADDR_WIDTH = 8,
    parameter TB_LUT_DATA_WIDTH = 16,
    parameter TB_D_SIZE = 4,
    parameter INTERNAL_TB_SIZE = 211
    ) ();

    typedef struct {
        int input_range;
        int input_low;
        int input_fl;
        int input_fh;
        int input_s;
        int input_nsyms;
        int norm_input_range;   // Used as verification value
        int norm_input_low;     // Used as verification value
        int norm_output_range;       // not used in the TB
        int norm_output_low;         // not used in this TB
    } sim_data;

    // -------------------------------------
        // As the file miss-video_stage-1-2_tb_211rows.csv has some problems, it's required to pay closely attention.
        // The lines (i=) 14, 105, 109, 141, 145, 176, 189, 198 and 202 ARE NOT inputs!!!!
        // These lines only contain the Normalize values (input and output), which means they can't be executed.
    // -------------------------------------

    sim_data simulation [(INTERNAL_TB_SIZE-1):0];      // creates the simulation vector

    // file reader
    integer fd;
    int temp_low_in, temp_range_in, temp_fl_in, temp_fh_in, temp_s_in, temp_nsyms_in;
    int temp_norm_range_in, temp_norm_low_in, temp_range_out, temp_low_out;
    int status;
    int i;
    // ----------------------

    // top entity values
    wire [(TB_LUT_DATA_WIDTH-1):0] lut_u, lut_v;
    wire [(TB_RANGE_WIDTH-1):0] uu_out, vv_out;
    wire comp_mux_1_out;
    // registers
    reg [(TB_LUT_DATA_WIDTH-1):0] reg_lut_u, reg_lut_v;
    reg reg_comp_mux_1;
    reg [(TB_RANGE_WIDTH-1):0] reg_uu, reg_vv;
    // control sign
    reg ctrl_reg;

    // ------------------------

    reg tb_clk;
    reg [(TB_RANGE_WIDTH-1):0] tb_range_in, tb_fl_in, tb_fh_in;
    reg [(TB_LOW_WIDTH-1):0] tb_low_in;
    reg [(TB_SYMBOL_WIDTH-1):0] tb_symbol;
    reg [TB_SYMBOL_WIDTH:0] tb_nsyms;
    wire [(TB_RANGE_WIDTH-1):0] tb_range_out;
    wire [(TB_LOW_WIDTH-1):0] tb_low_out;


    stage_1 #(
        .RANGE_WIDTH (TB_RANGE_WIDTH),
        .SYMBOL_WIDTH (TB_SYMBOL_WIDTH),
        .LUT_ADDR_WIDTH (TB_LUT_ADDR_WIDTH),
        .LUT_DATA_WIDTH (TB_LUT_DATA_WIDTH)
        ) pipeline_stage_1 (
            .clk_stage_1 (tb_clk),
            .FL (tb_fl_in),
            .FH (tb_fh_in),
            .SYMBOL (tb_symbol),
            .NSYMS (tb_nsyms),
            // outputs
            .COMP_mux_1 (comp_mux_1_out),
            .lut_u_out (lut_u),
            .lut_v_out (lut_v),
            .UU (uu_out),
            .VV (vv_out)
        );
    stage_2 #(
        .RANGE_WIDTH (TB_RANGE_WIDTH),
        .LOW_WIDTH (TB_LOW_WIDTH)
        ) pipeline_stage_2 (
            .UU (reg_uu),
            .VV (reg_vv),
            .in_range (tb_range_in),
            .in_low (tb_low_in),
            .lut_u (reg_lut_u),
            .lut_v (reg_lut_v),
            .COMP_mux_1 (reg_comp_mux_1),
            // outputs
            .range (tb_range_out),
            .low (tb_low_out)
        );

        always #6ns tb_clk <= ~tb_clk;

        always @ (posedge tb_clk) begin
            if(ctrl_reg) begin
                reg_lut_u <= lut_u;
                reg_lut_v <= lut_v;
                reg_comp_mux_1 <= comp_mux_1_out;
                reg_uu <= uu_out;
                reg_vv <= vv_out;
            end
        end

        initial begin
            $display("Start to read the file.\n");
            tb_clk <= 1'b0;
            fd = $fopen("C:/Users/Tulio/Desktop/arithmetic_encoder_av1/verification_area/simulation_data/decimal-csv-files/miss-video_stage-1-2_tb_211rows.csv", "r");
            for(i=0; i<INTERNAL_TB_SIZE; i++) begin
                status = $fscanf (fd, "%d;%d;%d;%d;%d;%d;%d;%d;%d;%d\n", temp_range_in, temp_low_in, temp_fl_in, temp_fh_in, temp_s_in, temp_nsyms_in, temp_norm_range_in, temp_norm_low_in, temp_range_out, temp_low_out);
                if(status != 10) begin
                    $display("Not read %d\n", i);
                end
                else begin
                    simulation[i].input_range = temp_range_in;
                    simulation[i].input_low = temp_low_in;
                    simulation[i].input_fl = temp_fl_in;
                    simulation[i].input_fh = temp_fh_in;
                    simulation[i].input_s = temp_s_in;
                    simulation[i].input_nsyms = temp_nsyms_in;
                    simulation[i].norm_input_range = temp_norm_range_in;
                    simulation[i].norm_input_low = temp_norm_low_in;
                    simulation[i].norm_output_range = temp_range_out;
                    simulation[i].norm_output_low = temp_low_out;
                    // $display("Test print: \tInput_FL: %d\tOutput_low: %d\n----------\n", simulation[i].input_fl, simulation[i].output_low);
                end
            end
            $fclose(fd);
            $display("==============\nDone reading the file\n=============\n");

            // first assignment
            $display("-> Setting start values\n");
            ctrl_reg <= 1'b1;
            for(i=0; i<INTERNAL_TB_SIZE; i++) begin
                if((i == 14) || (i == 105) || (i == 109) || (i == 141) || (i == 145) || (i == 176) || (i == 189) || (i == 198) || (i == 202))
                    $display("Avoiding lines! # %d and %d\n", i, i+1);
                else begin
                    // if(i == 1)
                    //     ctrl_reg <= 1'b1;
                    $display("\t-> Setting data test # %d\n", i);
                    if(i > 0) begin
                        tb_range_in <= simulation[i-1].input_range;
                        tb_low_in <= simulation[i-1].input_low;
                    end
                    tb_fl_in <= simulation[i].input_fl;
                    tb_fh_in <= simulation[i].input_fh;
                    tb_symbol <= simulation[i].input_s;
                    tb_nsyms <= simulation[i].input_nsyms;
                    #6ns
                    // Now the simulation will only print values that don't match with expected.
                    if((i > 0) && (i != 15) && (i != 106) && (i != 110) && (i != 142) && (i != 146) && (i != 190) && (i != 177) && (i != 199) && (i != 203)) begin
                        if(tb_range_out != simulation[i-1].norm_input_range)
                            $display("\t\t-> Range doesn't match with what was expected. Got %d, expecting %d\n", tb_range_out, simulation[i].norm_input_range);

                        if(tb_low_out != simulation[i-1].norm_input_low)
                            $display("\t\t-> Low doesn't match with what was expected. Got %d, expecting %d\n", tb_low_out, simulation[i].norm_input_low);
                    end
                    else
                        $display("Not checking results for %d because it is was set to be avoided.\n", i);
                    $display("=================\n");
                    #6ns;
                end
            end
        end
endmodule
