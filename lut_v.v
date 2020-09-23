module lut_v #(
    parameter DATA_WIDTH=16,
    parameter ADDR_WIDTH=8
    )(
	input [(ADDR_WIDTH-1):0] addr,
	input clk,
	output reg [(DATA_WIDTH-1):0] q
);

	// (* ram_init_file = "Scripts/lut_v.mif" *) reg [DATA_WIDTH-1:0] rom[2**ADDR_WIDTH-1:0];

    reg [DATA_WIDTH-1:0] rom[2**ADDR_WIDTH-1:0];

	initial
	begin
        $readmemh("Scripts/lut_v.mem", rom);
	end

	always @ (posedge clk)
	begin
		q <= rom[addr];
	end

endmodule
