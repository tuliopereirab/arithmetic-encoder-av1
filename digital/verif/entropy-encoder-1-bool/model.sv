`include "uvm_macros.svh"

`include "header.svh"
`include "top_uvm.sv"
`include "sequence.sv"
`include "driver.sv"
`include "monitor.sv"
`include "scoreboard.sv"

class ee_model;
  function ee_tx range_update(ee_tx item, 
    bit [(`RANGE_WIDTH-1):0] prev_range);
    // TODO - Range update 
    // Input: the current item + previous range
    // Output: the current item updated with the final range & d
  endfunction : range_update

  function ee_tx low_update(ee_tx item, bit [(`LOW_WIDTH-1):0] prev_low, 
                            bit [(`D_SIZE-1):0] prev_cnt);
    // TODO - Range update
    // Input: current item, previous low and previous cnt
    // Output: the current item updated with final low, final cnt, the 
    // pre-bitstreams (pb_1 and pb_2), and the pre-bitstream flag (pb_flag).
  endfunction : low_update

  function ee_tx carry_propagation(ee_tx item);
    // TODO - Carry Propagation
    // Inputs: the current item, which must already contain the pre-bitstreams
    // Outputs: updated item with the expected final bitstreams
    // Methodology:
    //  - Consider the flag_final to generate the Last_Bits bitstreams
    //  - Propagate the carry according to the incoming pb_flag or generated 
    // last_bits flag.
  endfunction : carry_propagation

endclass : ee_model