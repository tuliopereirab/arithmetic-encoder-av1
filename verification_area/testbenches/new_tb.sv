`timescale 1ns / 1ps

module entropy_encoder_tb #(
     parameter TB_BITSTREAM_WIDTH = 8,
     parameter TB_RANGE_WIDTH = 16,          // These parameters (lines 2 to 7) represent the architecture parameters
     parameter TB_LOW_WIDTH = 24,            // They must be changed ONLY IF THERE ARE CHANGES IN THE ARCHITECTURE
     parameter TB_SYMBOL_WIDTH = 4,          // Changing these parameters WILL NOT ensure a correct execution by the architecture
     parameter TB_LUT_ADDR_WIDTH = 8,        // All changes on these parameters must be analyzed before and change some internal defaults in the architecture
     parameter TB_LUT_DATA_WIDTH = 16,
     parameter TB_D_SIZE = 5
     )();
     // Config variables
     `define DUMPFILE 0             // Generate a .vcd file as output
     // The variable below sets the path for the dumpfile. It must contain the name of the file.vcd
     `define DUMPFILE_PATH "/home/vcds/dump.vcd"
     // TARGET_PATH specifies the path where the main_data and bitstream files will be.
     // TARGET_PATH must end with a /
     // `define TARGET_PATH "/home/datasets/target/"
     `define TARGET_PATH "/home/datasets/Reduced_Datasets/cq20/allintra/"
     // TARGET_BITSTREAM and TARGET_MAIN specify the name of the target file
     // `define TARGET_MAIN "target-main_data.csv"
     // `define TARGET_BITSTREAM "target-bitstream.csv"
     `define TARGET_BITSTREAM "KristenAndSara_1280x720_60_120f-bitstream.csv"
     `define TARGET_MAIN "KristenAndSara_1280x720_60_120f-main_data.csv"
     // The lines below define the number of columns in the -main_data.csv and -bitstream.csv
     `define NUM_COL_MAIN 11
     `define NUM_COL_BITSTREAM 1
     // Below are the clock definitions
     `define FULL_PERIOD #2
     `define HALF_PERIOD #1
     // Useful macros
     `define INCR(A) A+1
     `define RESET_MSG(A,B,C) $display("%d-> Reset detected: \t-> %d <- \t%d in the frame", A, B, C)
     `define ERROR(cnt,exp,got,bits_cnt,flag) \
                         $display("\n------------------------------"); \
                         $display("MISMATCH at %d:\t Expected %d and got %d.", cnt, exp, got); \
                         $display("\t-> Bitstreams generated: %d\n\t-> Flag: %d", bits_cnt, flag);    \
                         $display("------------------------------\n"); \
                         $stop;    // A-> counter, B-> expected, C-> got, D-> bistreams counter
     // -------------------------------------

     // Testbench variables
     int i, counter, resets_counter, from_last_reset, bitstreams_counter;     // Control variables
     int prev_range, prev_low;
     int file_main, file_bitstream;     // File variables
     // From main_data
     int temp_fl, temp_fh, temp_symbol, temp_nsyms, temp_bool;   // Architecture inputs
     int temp_range, temp_low;     // Final range and low   (Used to check for resets)
     int temp_init_range, temp_init_low;          // Used to check for resets
     int temp_norm_in_low, temp_norm_in_rng;       // Useless
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
     wire [(TB_BITSTREAM_WIDTH-1):0] tb_out_bit_1, tb_out_bit_2, tb_out_bit_3, tb_out_bit_4, tb_out_bit_5;
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
          file_main = $fopen({`TARGET_PATH, `TARGET_MAIN}, "r");
          file_bitstream = $fopen({`TARGET_PATH, `TARGET_BITSTREAM}, "r");
     endfunction

     function void ReadMain;
          int num_read;
          num_read = $fscanf (file_main, "%d;%d;%d;%d;%d;%d;%d;%d;%d;%d;%d;\n", temp_bool, temp_init_range,
               temp_init_low, temp_fl, temp_fh, temp_symbol, temp_nsyms, temp_norm_in_rng, temp_norm_in_low,
               temp_range, temp_low);
          if(num_read != `NUM_COL_MAIN) begin
               $display("ERROR: Read %d instead of %d from the '%s' file.\n", num_read, `NUM_COL_MAIN,
                    `TARGET_MAIN);
               $stop;
          end
     endfunction

     function void ReadBitstream;
          int num_read;
          bitstreams_counter = `INCR(bitstreams_counter);
          num_read = $fscanf (file_bitstream, "%d;\n", temp_bitstream);
          if(num_read != `NUM_COL_BITSTREAM) begin
               $display("ERROR: Read %d instead of %d from the '%s' file.\n", num_read, `NUM_COL_BITSTREAM,
                    `TARGET_BITSTREAM);
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
          from_last_reset = 0;     // Counts the number of inputs since the last reset
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
                         1    : comp = tb_out_bit_1;
                         2    : comp = tb_out_bit_2;
                         3    : comp = tb_out_bit_3;
                         default : begin
                              $display("ERROR: Invalid flag. Stopped.\n");
                              $stop;
                         end
                    endcase
                    if(comp != temp_bitstream) begin
                         `ERROR(counter, temp_bitstream, comp, bitstreams_counter, tb_out_flag_bitstream);
                    end
               end
          end else if(tb_out_flag_bitstream > 4) begin
               ReadBitstream();
               if(tb_out_bit_1 != temp_bitstream)
                    `ERROR(counter, temp_bitstream, comp, bitstreams_counter, tb_out_flag_bitstream);
               for(j=0; j<tb_out_bit_3; j=`INCR(j)) begin
                    ReadBitstream();
                    if(tb_out_bit_2 != temp_bitstream)
                         `ERROR(counter, temp_bitstream, comp, bitstreams_counter, tb_out_flag_bitstream);
               end
               if(tb_out_flag_bitstream > 5) begin
                    ReadBitstream();
                    if(tb_out_bit_4 != temp_bitstream)
                         `ERROR(counter, temp_bitstream, comp, bitstreams_counter, tb_out_flag_bitstream);
               end
               if(tb_out_flag_bitstream == 7) begin
                    ReadBitstream();
                    if(tb_out_bit_5 != temp_bitstream)
                         `ERROR(counter, temp_bitstream, comp, bitstreams_counter, tb_out_flag_bitstream);
               end
          end
     endfunction

     always `HALF_PERIOD tb_clk <= ~tb_clk;

     initial begin
          $display("-> Starting testbench...");
          if(`DUMPFILE == 1) begin
               $display("\tCONFIG: Generating VCD file. File name '%s'", `DUMPFILE_PATH);
               $dumpfile(`DUMPFILE_PATH);
               $dumpvars;
          end
          tb_clk <= 1'b0;
          counter = 0;             // Counts the number of current inputs
          resets_counter = -1;     // It's incremented inside SetReset()
          prev_range = -1;
          prev_low = -1;
          bitstreams_counter = 0;
          OpenFiles();
          SetReset();
          while(!$feof(file_main)) begin
               ReadMain();
               if(CheckReset() == 1 && counter > 0) begin
                    `RESET_MSG(counter, `INCR(resets_counter), from_last_reset);
                    SetFlagLast();
                    while(tb_out_flag_last != 1) begin
                         if(tb_out_flag_bitstream != 0)
                              CheckOutput();
                         `FULL_PERIOD;
                    end
                    if(tb_out_flag_bitstream != 0)
                         CheckOutput();
                    SetReset();
               end else begin
                    if(tb_out_flag_bitstream != 0)
                         CheckOutput();
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
          $stop;
     end

     initial begin

     end
endmodule
