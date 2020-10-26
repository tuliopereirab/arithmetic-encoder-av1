module lut_u #(
    parameter DATA_WIDTH=16,
    parameter ADDR_WIDTH=8
    )(
	input [(ADDR_WIDTH-1):0] addr,
	input clk,
	output wire [(DATA_WIDTH-1):0] q
);


    // (* ram_init_file = "Scripts/lut_u.mif" *) reg [DATA_WIDTH-1:0] rom[2**ADDR_WIDTH-1:0];
    reg [DATA_WIDTH-1:0] rom[2**ADDR_WIDTH-1:0];


//     initial
// 	begin
//         $readmemh("lut/lut_u.mem", rom);
// 	end


	assign q = rom[addr];


endmodule
