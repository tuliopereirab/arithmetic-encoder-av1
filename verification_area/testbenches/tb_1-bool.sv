`timescale 1ns / 1ps

module entropy_encoder_tb #(
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
  // TARGET_BITSTREAM and TARGET_MAIN specify the name of the target file
  // TARGET_MAIN shouldn't be changed. Used to run with modelsim_flow.tcl
  `define TARGET_MAIN "target-main_data.csv"
  // TARGET_BITSTREAM shouldn't be changed. Used to run with modelsim_flow.tcl
  `define TARGET_BITSTREAM "target-bitstream.csv"
  `define SPECIFIC_BITSTREAM "Netflix_RollerCoaster_1280x720_60fps_8bit_420_60f-bitstream.csv"
  `define SPECIFIC_MAIN "Netflix_RollerCoaster_1280x720_60fps_8bit_420_60f-main_data.csv"
  // Next lines define the num of cols in the -main_data.csv and -bitstream.csv
  `define NUM_COL_MAIN 11
  `define NUM_COL_BITSTREAM 1
  // Below are the clock definitions
  `define FULL_PERIOD #2
  `define HALF_PERIOD #1
  // Useful macros
  `define INCR(A) A+1
  `define RESET_MSG(A,B,C) $display("\t%d-> Reset detected: \t-> %d <- \t%d in the frame", A, B, C)
  `define ERROR(A,B,C,D,E) \
         $display("------------------------------"); \
         $display("MISMATCH at %d:\t Expected %d and got %d.", A, B, C); \
         $display("\t-> Bitstreams generated: %d\n\t-> Flag: %d", D, E);  \
         $display("------------------------------\n"); \
         $stop;  // A-> counter, B-> expected, C-> got, D-> bistreams counter
  // -------------------------------------

  // Testbench variables
  int counter, resets_counter, from_last_reset, bitstreams_counter;
  int prev_range, prev_low;
  int file_main, file_bitstream;  // File variables
  // From main_data
  int temp_fl, temp_fh, temp_symbol, temp_nsyms, temp_bool;  // Arc inputs
  int temp_range, temp_low;  // Final range and low  (Used to check for resets)
  int temp_init_range, temp_init_low;    // Used to check for resets
  int temp_norm_in_low, temp_norm_in_rng;    // Useless
  // From bitstream;
  int temp_bitstream;
  // -------------------------------------

  // Architecture variables
  // Inputs
  reg tb_clk, tb_reset, tb_flag_first, tb_final_flag, tb_bool;
  reg [(TB_RANGE_WIDTH-1):0] tb_fl, tb_fh;
  reg [(TB_SYMBOL_WIDTH-1):0] tb_symbol;
  reg [TB_SYMBOL_WIDTH:0] tb_nsyms;
  // Outputs
  wire [(TB_BITSTREAM_WIDTH-1):0] tb_out_bit_1, tb_out_bit_2, tb_out_bit_3;
  wire [(TB_BITSTREAM_WIDTH-1):0] tb_out_bit_4, tb_out_bit_5;
  wire [2:0] tb_out_flag_bitstream;
  wire tb_out_flag_last;
  // -------------------------------------

  // Architecture declaration
  entropy_encoder #(
    .TOP_RANGE_WIDTH (TB_RANGE_WIDTH),
    .TOP_LOW_WIDTH (TB_LOW_WIDTH),
    .TOP_SYMBOL_WIDTH (TB_SYMBOL_WIDTH),
    .TOP_LUT_ADDR_WIDTH (TB_LUT_ADDR_WIDTH),
    .TOP_LUT_DATA_WIDTH (TB_LUT_DATA_WIDTH),
    .TOP_BITSTREAM_WIDTH (TB_BITSTREAM_WIDTH),
    .TOP_D_SIZE (TB_D_SIZE)
    ) DUT_ent_enc (
      .top_clk (tb_clk),
      .top_reset (tb_reset),
      .top_flag_first (tb_flag_first),
      .top_final_flag (tb_final_flag),
      .top_fl (tb_fl),
      .top_fh (tb_fh),
      .top_symbol (tb_symbol),
      .top_nsyms (tb_nsyms),
      .top_bool (tb_bool),
      // outputs
      .OUT_BIT_1 (tb_out_bit_1),
      .OUT_BIT_2 (tb_out_bit_2),
      .OUT_BIT_3 (tb_out_bit_3),
      .OUT_BIT_4 (tb_out_bit_4),
      .OUT_BIT_5 (tb_out_bit_5),
      .OUT_FLAG_BITSTREAM (tb_out_flag_bitstream),
      .OUT_FLAG_LAST (tb_out_flag_last)
    );
  // -------------------------------------

  function void OpenFiles;
    if(`MODELSIM_FLOW == 1) begin
      file_main = $fopen({`TARGET_PATH, `TARGET_MAIN}, "r");
      file_bitstream = $fopen({`TARGET_PATH, `TARGET_BITSTREAM}, "r");
    end else begin
      file_main = $fopen({`SPECIFIC_PATH, `SPECIFIC_MAIN}, "r");
      file_bitstream = $fopen({`SPECIFIC_PATH, `SPECIFIC_BITSTREAM}, "r");
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

  function void ReadBitstream;
    int num_read;
    bitstreams_counter = `INCR(bitstreams_counter);
    num_read = $fscanf (file_bitstream, "%d;\n", temp_bitstream);
    if(num_read != `NUM_COL_BITSTREAM) begin
      $display("ERROR: Read %d instead of %d from the '%s' file.\n", num_read,
        `NUM_COL_BITSTREAM, `TARGET_BITSTREAM);
      $stop;
    end
  endfunction

  function void SetArchitectureInputs;
    input int first;
    tb_flag_first = first;
    tb_final_flag = 0;
    tb_fl = temp_fl;
    tb_fh = temp_fh;
    tb_symbol = temp_symbol;
    tb_nsyms = temp_nsyms;
    tb_bool = temp_bool;
  endfunction

  task SetFlagLast;
    tb_final_flag = 1;
  endtask

  task SetReset;
    from_last_reset = 0;  // Counts the number of inputs since the last reset
    resets_counter = `INCR(resets_counter);
    tb_reset <= 1;
    `FULL_PERIOD;
    tb_reset <= 0;
  endtask

  function int CheckReset;
    int ret;
    if(
      (temp_init_low == 0) &&
      (temp_init_range == 32768) &&
      ((temp_init_low != prev_low) || (temp_init_range != prev_range))

    ) begin
      ret = 1;
    end else begin
      ret = 0;
    end
    prev_range = temp_range;
    prev_low = temp_low;
    return ret;
  endfunction

  function void CheckOutput;
    int j, comp;
    if(tb_out_flag_bitstream < 4) begin
      for(j=1; j<=tb_out_flag_bitstream; j=`INCR(j)) begin
       ReadBitstream();
       case(j)
         1  : comp = tb_out_bit_1;
         2  : comp = tb_out_bit_2;
         3  : comp = tb_out_bit_3;
         default : begin
           $display("ERROR: Invalid flag. Stopped.\n");
           $stop;
         end
       endcase
       assert(comp == temp_bitstream)
       else begin
         `ERROR(counter, temp_bitstream, comp, bitstreams_counter,
           tb_out_flag_bitstream);
       end
      end
    end else if(tb_out_flag_bitstream > 4) begin
      ReadBitstream();
      assert(tb_out_bit_1 == temp_bitstream)
      else begin
       `ERROR(counter, temp_bitstream, tb_out_bit_1, bitstreams_counter,
         tb_out_flag_bitstream);
      end
      for(j=0; j<tb_out_bit_3; j=`INCR(j)) begin
       ReadBitstream();
       assert(tb_out_bit_2 == temp_bitstream)
       else begin
         `ERROR(counter, temp_bitstream, tb_out_bit_2, bitstreams_counter,
           tb_out_flag_bitstream);
       end
      end
      if(tb_out_flag_bitstream > 5) begin
       ReadBitstream();
       assert(tb_out_bit_4 == temp_bitstream)
       else begin
         `ERROR(counter, temp_bitstream, tb_out_bit_4, bitstreams_counter,
           tb_out_flag_bitstream);
       end
      end
      if(tb_out_flag_bitstream == 7) begin
       ReadBitstream();
       assert(tb_out_bit_5 == temp_bitstream)
       else begin
         `ERROR(counter, temp_bitstream, tb_out_bit_5, bitstreams_counter,
           tb_out_flag_bitstream);
       end
      end
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
    resets_counter = -1;  // It's incremented inside SetReset()
    prev_range = -1;
    prev_low = -1;
    bitstreams_counter = 0;
    OpenFiles();
    SetReset();
    while(!$feof(file_main)) begin
      if(`STOP_MAX_FLAG == 1 && counter > `MAX_ROUNDS)
        break;
      ReadMain();
      if(CheckReset() == 1 && counter > 0) begin
        `RESET_MSG(counter, `INCR(resets_counter), from_last_reset);
        SetFlagLast();
        while(tb_out_flag_last != 1) begin
          // Runs until the flag_last arrives at the end of the architecture
          `FULL_PERIOD;
        end
        SetReset();
      end
      if(counter == 0 || from_last_reset == 0)
        SetArchitectureInputs(1);
      else
        SetArchitectureInputs(0);
        counter = `INCR(counter);
        from_last_reset = `INCR(from_last_reset);
        `FULL_PERIOD;
    end
    $display("==================");
    $display("Done with simulation.");
    $display("==================");
    $display("\t-> Total inputs: %d\n\t-> Total resets: %d\n\tTotal bitstreams: %d",
      counter, resets_counter, bitstreams_counter);
    $display("==================");
    $stop;
  end

  always @ (negedge tb_clk) begin
    /* Everytime there is a negedge in the clock, then this always checks the
    output flag_bitstream.
      If the flag_bitstream is different than zero, there are bitstreams waiting
    at the output pins and they need to be checked. */
    if(tb_out_flag_bitstream != 0) begin
      CheckOutput();
    end
  end
endmodule
