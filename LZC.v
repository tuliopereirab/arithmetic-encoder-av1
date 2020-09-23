// This module was based on:
    // @ARTICLE{4539802,
        // author={G. {Dimitrakopoulos} and K. {Galanopoulos} and C. {Mavrokefalidis} and D. {Nikolos}},
        // journal={IEEE Transactions on Very Large Scale Integration (VLSI) Systems},
        // title={Low-Power Leading-Zero Counting and Anticipation Logic for High-Speed Floating Point Units},
        // year={2008},
        // volume={16},
        // number={7},
        // pages={837-850},
        // doi={10.1109/TVLSI.2008.2000458}
    //}

module leading_zero #(
    parameter RANGE_SIZE = 16
    )(
        input [(RANGE_SIZE)-1:0] in_range,
        output wire [4:0] lzc_out
    );

    wire [31:0] range_adjusted;
    assign range_adjusted = {16'h0, in_range};



endmodule
