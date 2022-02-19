include "uvm_macros.svh"

`include "header.svh"
`include "sequence.sv"
`include "driver.sv"
`include "monitor.sv"
`include "scoreboard.sv"
`include "model.sv"

package av1_ee_rand_1_bool_uvm;
  import uvm_pkg::*;

  //  Class: ee_tx
  //
  class ee_tx extends uvm_sequence_item;
    typedef ee_tx this_type_t;
    `uvm_object_utils(ee_tx);
  
    //  Group: Variables
    // Random Input Variables
    rand bit [(`RANGE_WIDTH):0]     fl, fh;
    rand bit [(`SYMBOL_WIDTH-1):0]  symbol;
    rand bit [(`SYMBOL_WIDTH):0]    nsyms;
    rand bit                        bool_flag;

    // Non-random Input Variables
    bit                           flag_first, final_flag;   // As a non-random variable, they're assigned by the 
    bit                           rst;                      // sequence class. At the first symbol of a frame, 

    // Control Variables
    rand int                      frame_length;   // Defines the number of symbols within a frame
    int                           symbols_remaining = null;  // Once a new frame is started, symbols executed are set
    int                           symbols_executed  = null;       // to zero and symbols remaining are set to the 
                                  // frame_length. Once the frame is over (i.e., when symbols_remaining = 0), then the  
                                  // flag_final set to '1' and the reset procedure starts.  
  
    // Output Variables from the architecture
    bit                           out_flag_final;
    bit [2:0]                     fb_flag;
    bit [(`BITSTREAM_WIDTH-1):0]  fb_1, fb_2, fb_3, fb_4, fb_5;

    // Intern Variables
    bit [(`RANGE_WIDTH-1):0]      final_range;
    bit [(`LOW_WIDTH-1):0]        final_low;
    bit [(`D_SIZE-1):0]           final_cnt, d;
    
    bit [(`BITSTREAM_WIDTH-1):0]  pb_1, pb_2;
    bit [1:0]                     pb_flag;

    // Expected Output Variables
    bit [(`BITSTREAM_WIDTH-1):0]  expected_fb_1, expected_fb_2, expected_fb_3;
    bit [(`BITSTREAM_WIDTH-1):0]  expected_fb_4, expected_fb_5;
    bit [2:0]                     expected_fb_flag;

    //  Group: Constraints
    constraint prob_c {
      fl inside {[0 : 32768]};
      fh < fl;
    }

    constraint symb_c {
      nsyms inside {[0 : 16]};
      nsyms > symbol;
    }

    constraint bool_c {
      bool_flag dist {1 := 20, 0 := 80};    // There's a 20% chance that the encoding symbol is a boolean.
    }
  

    //  Group: Functions
  
    //  Constructor: new
    function new(string name = "ee_tx");
      super.new(name);
    endfunction: new
  
    //  Function: convert2string
    extern function string inputs2str();
    extern function string ctrl2str();
    extern function string outputs2str();
    
    // Function: set_ctrl_variables 
    // Defines the control variables symbols_remaining and symbols executed according to previous a item
    extern function void set_ctrl_variables(int prev_symb_exec, 
                                            int prev_symb_remaining);
  endclass: ee_tx
  
  //  Class: ee_sequence
  //
  class ee_sequence extends uvm_sequence;
    `uvm_object_utils(ee_sequence);
  
    //  Group: Variables
    // TODO
  
    //  Group: Functions
  
    //  Constructor: new
    function new(string name = "ee_sequence");
      super.new(name);
    endfunction: new
  
    extern virtual task body();
    
  endclass: ee_sequence

  // Sequencer
  typedef uvm_sequencer #(ee_tx) ee_sequencer;
  
  //  Class: ee_driver
  //
  class ee_driver extends uvm_driver;
    `uvm_component_utils(ee_driver);
  
    //  Group: Components
    // TODO
  
    //  Group: Variables
    // TODO
  
    //  Group: Functions
  
    //  Constructor: new
    function new(string name = "ee_driver", uvm_component parent);
      super.new(name, parent);
    endfunction: new
  
    // TODO
    
  endclass: ee_driver
  
  //  Class: ee_monitor
  //
  class ee_monitor extends uvm_monitor;
    `uvm_component_utils(ee_monitor);
  
    //  Group: Variables
    // TODO
  
    //  Group: Functions
  
    //  Constructor: new
    function new(string name = "ee_monitor", uvm_component parent);
      super.new(name, parent);
    endfunction: new
    
    // TODO
    
  endclass: ee_monitor
  
  //  Class: ee_agent
  //
  class ee_agent extends uvm_agent;
    `uvm_component_utils(ee_agent);
  
    //  Group: Components
    ee_driver     m_drv;
    ee_sequencer  m_seqr;
    ee_monitor    m_mon;
  
    //  Group: Variables
    // TODO
  
    //  Group: Functions
  
    //  Constructor: new
    function new(string name = "ee_agent", uvm_component parent);
      super.new(name, parent);
    endfunction: new
  
    function void build_phase(uvm_phase phase);
      m_drv   = ee_driver   ::type_id::create("m_drv", this);
      m_seqr  = ee_sequencer::type_id::create("m_seqr", this);
      m_mon   = ee_monitor  ::type_id::create("m_mon", this);  
    endfunction: build_phase

    // TODO
    
  endclass: ee_agent

  //  Class: ee_scoreboard
  //
  class ee_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(ee_scoreboard);
  
    //  Group: Components
    // TODO
  
    //  Group: Variables
    // TODO
  
    //  Group: Functions
  
    //  Constructor: new
    function new(string name = "ee_scoreboard", uvm_component parent);
      super.new(name, parent);
    endfunction: new
  
    // TODO
    
  endclass: ee_scoreboard
  
  //  Class: ee_env
  //
  class ee_env extends uvm_env;
    `uvm_component_utils(ee_env);
  
    //  Group: Components
    ee_agent      = m_agt;
    ee_scoreboard = m_scbd;
  
    //  Group: Variables
    // TODO
  
    //  Group: Functions
  
    //  Constructor: new
    function new(string name = "ee_env", uvm_component parent);
      super.new(name, parent);
    endfunction: new
  
    function void build_phase(uvm_phase phase);
      m_agt   = ee_agent      ::type_id::create("m_agt", this);
      m_scbd  = ee_scoreboard ::type_id::create("m_scbd", this);
      // TODO
    endfunction: build_phase
    
    // TODO
    
  endclass: ee_env
  
  //  Class: ee_rand_test
  //
  class ee_rand_test extends uvm_component;
    `uvm_component_utils(ee_rand_test);
  
    //  Group: Components
    // TODO
    
  
    //  Group: Variables
    // TODO
    
  
    //  Group: Functions
  
    //  Constructor: new
    function new(string name = "ee_rand_test", uvm_component parent);
      super.new(name, parent);
    endfunction: new
  
    // TODO
    
  endclass: ee_rand_test
  
endpackage : av1_ee_rand_1_bool_uvm