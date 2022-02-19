`include "uvm_macros.svh"

`define NUM_SEQ_ITEMS 100

`define PERIOD #4
`define HALF_PERIOD #2

// Architecture Parameters
`define RANGE_WIDTH      16
`define LOW_WIDTH        24
`define SYMBOL_WIDTH     4
`define LUT_ADDR_WIDTH   8
`define LUT_DATA_WIDTH   16
`define BITSTREAM_WIDTH  8
`define D_SIZE           5
`define ADDR_CARRY_WIDTH 4

//  Interface: ee_if
//
interface ee_if #(
  parameter RANGE_WIDTH       = 16,
  parameter LOW_WIDTH         = 24,
  parameter SYMBOL_WIDTH      = 4,
  parameter LUT_ADDR_WIDTH    = 8,
  parameter LUT_DATA_WIDTH    = 16,
  parameter BITSTREAM_WIDTH   = 8,
  parameter D_SIZE            = 5,
  parameter ADDR_CARRY_WIDTH  = 4
  )(
    input         clk
  );
  // Inputs
  logic                       rst, bool_flag, flag_first, final_flag;
  logic [(RANGE_WIDTH-1):0]   fl, fh;
  logic [(SYMBOL_WIDTH-1):0]  symbol;
  logic [SYMBOL_WIDTH:0]      nsyms;

  // Outputs
  logic                           out_flag_final;
  logic [(BITSTREAM_WIDTH-1):0]   fb_1, fb_2, fb_3, fb_4, fb_5;
  logic [2:0]                     fb_flag;
  
  // TODO - modports

endinterface: ee_if
