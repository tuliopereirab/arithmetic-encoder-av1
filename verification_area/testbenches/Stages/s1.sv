`timescale 1ns / 1ps

module tb_s1 #(
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
  reg tb_clk, tb_bool;
  reg [(TB_RANGE_WIDTH-1):0] tb_fl, tb_fh;
  reg [(TB_SYMBOL_WIDTH-1):0] tb_symbol;
  reg [TB_SYMBOL_WIDTH:0] tb_nsyms;
  // Outputs
  wire tb_COMP_mux_1, tb_bool_out;
  wire [(TB_LUT_DATA_WIDTH-1):0] tb_lut_u_out, tb_lut_v_out;
  wire [(TB_SYMBOL_WIDTH-1):0] tb_out_symbol;
  wire [(TB_RANGE_WIDTH-1):0] tb_UU, tb_VV;
  // -------------------------------------

  // Architecture declaration
  stage_1 #(
    .RANGE_WIDTH (TB_RANGE_WIDTH),
    .SYMBOL_WIDTH (TB_SYMBOL_WIDTH),
    .LUT_ADDR_WIDTH (TB_LUT_ADDR_WIDTH),
    .LUT_DATA_WIDTH (TB_LUT_DATA_WIDTH)
    ) DUT_s1 (
      .clk_stage_1 (tb_clk),
      .bool_flag (tb_bool),
      .FL (tb_fl),
      .FH (tb_fh),
      .SYMBOL (tb_symbol),
      .NSYMS (tb_nsyms),
      // Outputs
      .COMP_mux_1 (tb_COMP_mux_1),
      .bool_out (tb_bool_out),
      .lut_u_out (tb_lut_u_out),
      .lut_v_out (tb_lut_v_out),
      .out_symbol (tb_out_symbol),
      .UU (tb_UU),
      .VV (tb_VV)
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
    tb_bool = temp_bool;
    tb_fl = temp_fl;
    tb_fh = temp_fh;
    tb_symbol = temp_symbol;
    tb_nsyms = temp_nsyms;
  endfunction

  function void CheckOutput;
    /* The check output just calculates the output results based upon the
    original equations for each component */
    int exp_UU, exp_VV, exp_lut_u, exp_lut_v, exp_symbol;
    // Expected Definitions
    exp_lut_u = 4 * ((temp_nsyms - 1) - (temp_symbol - 1));
    exp_lut_v = 4 * ((temp_nsyms - 1) - (temp_symbol + 0));
    exp_UU = temp_fl >> 6;
    exp_VV = temp_fh >> 6;
    // --------------------
    if(temp_fl < 32768) begin
      assert(tb_COMP_mux_1 == 1)
      else begin
        `ERROR("COMP_mux_1", counter, 1, tb_COMP_mux_1);
      end
    end else begin
      assert(tb_COMP_mux_1 == 0)
      else begin
        `ERROR("COMP_mux_1", counter, 0, tb_COMP_mux_1);
      end
    end
    assert(tb_bool_out == !temp_bool)
    else begin
      `ERROR("bool_out", counter, !temp_bool, tb_bool_out);
    end
    if(!temp_bool == 0) begin
      // The LUTs are only used/valid when running the CDF operation
      assert(tb_lut_u_out == exp_lut_u)
      else begin
        `ERROR("lut_u_out", counter, exp_lut_u, tb_lut_u_out);
      end
      assert(tb_lut_v_out == exp_lut_v)
      else begin
        `ERROR("lut_v_out", counter, exp_lut_v, tb_lut_v_out);
      end
    end
    assert(tb_UU == exp_UU)
    else begin
      `ERROR("UU", counter, exp_UU, tb_UU);
    end
    assert(tb_VV == exp_VV)
    else begin
      `ERROR("VV", counter, exp_VV, tb_VV);
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
