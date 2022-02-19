`include "uvm_macros.svh"

`include "header.svh"
`include "top_uvm.sv"
`include "model.sv"
`include "driver.sv"
`include "monitor.sv"
`include "scoreboard.sv"

function string ee_tx::inputs2str();
  // Returns all the random and non-randomly generated input variables 
  // for the architecture and 
  string non_rand;
  non_rand = $sformatf("rst=%1b, flag_first=%1b, flag_final=%1b", rst, 
                      flag_first, flag_final);
  return $sformatf("bool_flag=%1d, fl=%5d, fh=%5d, symbol=%2d, nsyms=%2d, %s"
                  bool_flag, fl, fh, symbol, nsyms, non_rand);
endfunction : inputs2str

function string ee_tx::ctrl2str();
  // Returns all the item's control variables
  return $sformatf("frame_length=%10d, symbols_remaining=%10d, symbols_executed=%10d",
                  frame_length, symbols_remaining, symbols_executed)
endfunction : ctrl2str

function string ee_tx::outputs2str();
  // Returns all the architecture's output pins
  string fb_pins;
  fb_pints = $sformatf("fb_1=%3d, fb_2=%3d, fb_3=%3d, fb_4=%3d, fb_5=%3d",
                      fb_1, fb_2, fb_3, fb_4, fb_5);
  return $sformatf("out_flag_final=%1b, tb_flag=%3b, %s", out_flag_final, 
                  fb_flag, fb_pins);
endfunction : outputs2str

function void ee_tx::set_ctrl_variables(int prev_symb_exec, 
                                        int prev_symb_remaining);
  if(prev_symb_exec == -1) begin    
    // That means that the previous symbol was the last one on its frame.  
    // Now a new frame is starting and symbols_remaining and symbols_executed 
    // need to be set.
    this.symbols_remaining  = this.frame_length - 1;  // Removes first from total
    this.symbols_executed   = 1;                  // First symbol in a frame 
    this.flag_first         = 1'b1;               
    this.flag_final         = 1'b0;
  end else if(prev_symb_remaining == 0) begin
    // After the final symbol in a frame, the flag final needs to be passed as 
    // input so the Last Bits can be generated.
    this.symbols_remaining  = -1;     // Indicates that the final flag was 
                                      // already assigned.
    this.symbols_executed   = -1;     // Flags that the next item will be the 
                                      // first of its frame.
    this.flag_first         = 1'b0;
    this.flag_final         = 1'b1;   // Flags to the architecture to release 
                                      // the Last_Bits.
  end else begin
    // When the current symbol isn't the first nor the final, then the following
    // assignments are made so the next item will be correctly executed. 
    this.rst                = 1'b0;
    this.flag_first         = 1'b0;
    this.flag_final         = 1'b0;
    this.symbols_remaining  = prev_symb_remaining - 1;
    this.symbols_executed   = prev_symb_exec + 1;
  end
endfunction : set_ctrl_variables

virtual task ee_sequence::body();
  // TODO
endtask : body