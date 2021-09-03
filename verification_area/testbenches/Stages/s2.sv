`timescale 1ns / 1ps

module tb_s2 #(
  /* These parameters (lines 11 through 17) represent the architecture
  parameters.
  They must be changed ONLY IF THERE ARE CHANGES IN THE ARCHITECTURE.
  Changing these parameters WILL NOT ensure a correct execution by the
  architecture.
  All changes on these parameters must be analyzed before and change some
  internal defaults in the architecture. */
  parameter TB_BITSTREAM_WIDTH = 8,
  parameter TB_RANGE_WIDTH = 16,
  parameter TB_LOW_WIDTH = 24,
  parameter TB_SYMBOL_WIDTH = 4,
  parameter TB_LUT_ADDR_WIDTH = 8,
  parameter TB_LUT_DATA_WIDTH = 16,
  parameter TB_D_SIZE = 5
  )();
  // STOP_MAX_FLAG enables (1) or disables (0) the MAX_ROUNDS
  // MAX_ROUNDS forces the stop after X number of rounds
  `define STOP_MAX_FLAG 0
  `define MAX_ROUNDS 100000
  // PRINT_RATE prints a message every X rounds
  `define PRINT_RATE 10000
  // Config variables
  `define DUMPFILE 0     // Generate a .vcd file as output
  `define MODELSIM_FLOW 0
  /* MODELSIM_FLOW
    1 for modelsim_flow.tcl;
    0 for specific file (set the SPECIFIC_* variables below);
  DUMPFILE_PATH sets the path for the dumpfile. It must contain the name of the
  file.vcd.
  */
  `define DUMPFILE_PATH "/home/vcds/dump.vcd"
  // TARGET_PATH specifies the path where main_data and bitstream files will be.
  // TARGET_PATH must end with a /
  // TARGET_PATH Shouldn't be changed. Used to run with modelsim_flow.tcl
  `define TARGET_PATH "/home/datasets/target/"
  `define SPECIFIC_PATH "/home/datasets/Entire_Files/"
  // TARGET_MAIN shouldn't be changed. Used to run with modelsim_flow.tcl
  `define TARGET_MAIN "target-main_data.csv"
  `define SPECIFIC_MAIN "Netflix_RollerCoaster_1280x720_60fps_8bit_420_60f-main_data.csv"
  // Next lines define the num of cols in the -main_data.csv and -bitstream.csv
  `define NUM_COL_MAIN 11
  `define NUM_COL_BITSTREAM 1
  // Below are the clock definitions
  `define FULL_PERIOD #2
  `define HALF_PERIOD #1
  // Useful macros
  `define INCR(A) A+1
  `define RUNNING_MSG(A) \
    $display("\t-> Currently at \t-> %d", A)
  `define ERROR(VAR,A,B,C) \
    $display("------------------------------"); \
    $display("MISMATCH in %s at %d:\t Expected %d and got %d.", VAR, A, B, C); \
    $display("------------------------------\n"); \
    $stop;  // A-> counter, B-> expected, C-> got, D-> bistreams counter
  // -------------------------------------

  // Testbench variables
  int counter;
  int file_main;  // File variables
  // From main_data
  int temp_fl, temp_fh, temp_symbol, temp_nsyms, temp_bool;  // Arc inputs
  int temp_range, temp_low;  // Final range and low  (Used to check for resets)
  int temp_init_range, temp_init_low;    // Used to check for resets
  int temp_norm_in_low, temp_norm_in_rng;    // Useless
  // -------------------------------------

  // Architecture variables
  // Inputs
  reg tb_clk, tb_COMP_mux_1, tb_bool_flag;
  reg [(TB_RANGE_WIDTH-1):0] tb_UU, tb_VV, tb_in_range, tb_lut_u, tb_lut_v;
  reg [(TB_SYMBOL_WIDTH-1):0] tb_symbol;
  // Outputs
  wire [(TB_RANGE_WIDTH-1):0] tb_initial_range, tb_out_range;
  wire [TB_RANGE_WIDTH:0] tb_u_out, tb_v_bool_out;
  wire [(TB_D_SIZE-1):0] tb_out_d;
  wire [1:0] tb_bool_symbol;
  wire tb_COMP_mux_1_out;
  // -------------------------------------

  // Architecture declaration
  stage_2 #(
    .RANGE_WIDTH (TB_RANGE_WIDTH),
    .D_SIZE (TB_D_SIZE),
    .SYMBOL_WIDTH (TB_SYMBOL_WIDTH)
    ) DUT_s2 (
      .UU (tb_UU),
      .VV (tb_VV),
      .in_range (tb_in_range),
      .lut_u (tb_lut_u),
      .lut_v (tb_lut_v),
      .COMP_mux_1 (tb_COMP_mux_1),
      .symbol (tb_symbol),
      .bool_flag (tb_bool_flag),
      // Outputs
      .u (tb_u_out),
      .v_bool (tb_v_bool_out),
      .initial_range (tb_initial_range),
      .out_range (tb_out_range),
      .out_d (tb_out_d),
      .bool_symbol (tb_bool_symbol),
      .COMP_mux_1_out (tb_COMP_mux_1_out)
    );
  // -------------------------------------

  function void OpenFiles;
    if(`MODELSIM_FLOW == 1) begin
      file_main = $fopen({`TARGET_PATH, `TARGET_MAIN}, "r");
    end else begin
      file_main = $fopen({`SPECIFIC_PATH, `SPECIFIC_MAIN}, "r");
    end
  endfunction

  function void ReadMain;
    int num_read;
    num_read = $fscanf (file_main, "%d;%d;%d;%d;%d;%d;%d;%d;%d;%d;%d;\n",
      temp_bool, temp_init_range, temp_init_low, temp_fl, temp_fh, temp_symbol,
      temp_nsyms, temp_norm_in_rng, temp_norm_in_low,
      temp_range, temp_low);
    if(num_read != `NUM_COL_MAIN) begin
      $display("ERROR: Read %d instead of %d from the '%s' file.\n", num_read,
        `NUM_COL_MAIN, `TARGET_MAIN);
      $stop;
    end
  endfunction

  function void SetArchitectureInputs;
    tb_UU = temp_fl >> 6;
    tb_VV = temp_fh >> 6;
    tb_in_range = temp_init_range;
    tb_lut_u = 4 * ((temp_nsyms - 1) - (temp_symbol - 1));
    tb_lut_v = 4 * ((temp_nsyms - 1) - (temp_symbol + 0));
    tb_symbol = temp_symbol;
    tb_bool_flag = ~temp_bool;  // Inverted because of the input files
                                // The NOT happens usually in Stage 1
    if(temp_fl < 32768)
      tb_COMP_mux_1 = 1;
    else
      tb_COMP_mux_1 = 0;
  endfunction

  function void CheckOutput;
    /* This function calculates the expected values for each variable according
    to the AV1 reference software and its original equations. */
    int exp_u, exp_v_bool, exp_out_range, exp_bool_symbol, exp_out_d;
    int var_v, count_d, alt_range;  // Used only to represent the 'v' variable in od_ec_encode_q15()
    // Expected Definitions
    exp_u = ((temp_init_range >> 8) * (temp_fl >> 6) >> 1) +
            4 * ((temp_nsyms - 1) - (temp_symbol - 1));
    var_v = ((temp_init_range >> 8) * (temp_fh >> 6) >> 1) +
            4 * ((temp_nsyms - 1) - (temp_symbol + 0));
    exp_v_bool = ((temp_init_range >> 8) * (temp_fh >> 6) >> 1) + 4;
    exp_bool_symbol = {tb_bool_flag, tb_symbol[0]};
    // --------------------
    if(!temp_bool == 0) begin
      // CDF Operation
      if(temp_fl < 32768) begin
        exp_out_range = exp_u - var_v;
        assert(tb_COMP_mux_1_out == 1)
        else begin
          `ERROR("COMP_mux_1_out", counter, 1, tb_COMP_mux_1_out);
        end
      end else begin
        exp_out_range = temp_init_range - (((temp_init_range >> 8) *
                        (temp_fh >> 6) >> 1) + 4 * ((temp_nsyms - 1) -
                        (temp_symbol + 0)));
        assert(tb_COMP_mux_1_out == 0)
        else begin
          `ERROR("COMP_mux_1_out", counter, 0, tb_COMP_mux_1_out);
        end
      end
      assert(exp_u == tb_u_out)
      else begin
        `ERROR("u", counter, exp_u, tb_u_out);
      end
    end else begin
      // Boolean Operation
      exp_v_bool = ((temp_init_range >> 8) * (temp_fh >> 6) >> 1) + 4;
      if(tb_symbol[0] == 1)
        exp_out_range = exp_v_bool;
      else
        exp_out_range = temp_init_range - exp_v_bool;
      assert(exp_v_bool == tb_v_bool_out)
      else begin
        `ERROR("v_bool", counter, exp_v_bool, tb_v_bool_out);
      end
    end
    // Define D
    count_d = -1;
    alt_range = exp_out_range;
    while(alt_range < 32768) begin
      alt_range = exp_out_range;
      count_d = `INCR(count_d);
      alt_range = alt_range << count_d;
    end
    if(count_d == -1)
      exp_out_d = 0;
    else
      exp_out_d = count_d;
    assert(temp_init_range == tb_initial_range)
    else begin
      `ERROR("initial_range", counter, temp_init_range, tb_initial_range);
    end
    assert((exp_out_range << exp_out_d) == tb_out_range)
    else begin
      `ERROR("out_range", counter, (exp_out_range << exp_out_d), tb_out_range);
    end
    assert(exp_bool_symbol == tb_bool_symbol)
    else begin
      `ERROR("bool_symbol", counter, exp_bool_symbol, tb_bool_symbol);
    end
  endfunction

  function void CheckConfig;
    if(`DUMPFILE == 1) begin
      $display("\tCONFIG 1: Generating VCD file. File name '%s'",
        `DUMPFILE_PATH);
      $dumpfile(`DUMPFILE_PATH);
      $dumpvars;
    end else begin
      $display("\tCONFIG 1: No VCD set.");
    end
    if(`MODELSIM_FLOW == 1) begin
      $display("\tCONFIG 2: Running with Modelsim_Flow.");
    end else begin
      $display("\tCONFIG 2: Running specific file: %s", `SPECIFIC_MAIN);
    end
  endfunction

  always `HALF_PERIOD tb_clk <= ~tb_clk;

  initial begin
    $display("-> Starting testbench...");
    CheckConfig();
    $display("-> Starting simulation...");
    tb_clk <= 1'b1;    // Clk initiation value
    counter = 0;     // Counts the number of current inputs
    OpenFiles();
    while(!$feof(file_main)) begin
      counter = `INCR(counter);
      ReadMain();
      SetArchitectureInputs();
      `FULL_PERIOD;
      CheckOutput();
      if((counter % `PRINT_RATE) == 0) begin
        // Prints a message every PRINT_RATE rounds
        `RUNNING_MSG(counter);
      end
      if(`STOP_MAX_FLAG == 1) begin
        if(counter > `MAX_ROUNDS) begin
          // Stops the simulation after X rounds
          break;
        end
      end
    end
    $display("==================");
    $display("Done with simulation.");
    $display("==================");
    $display("\t-> Total inputs: %d\n\t-> No error detected.", counter);
    $display("==================");
    $stop;
  end
endmodule
