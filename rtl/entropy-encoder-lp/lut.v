module lut #(
    parameter DATA_WIDTH=16,
    parameter ADDR_WIDTH=8,
    parameter MEM_INDICATION=0
    )(
          input [(ADDR_WIDTH-1):0] addr,
          input clk,
          output wire [(DATA_WIDTH-1):0] q
);


    // (* ram_init_file = "Scripts/lut_u.mif" *) reg [DATA_WIDTH-1:0] rom[2**ADDR_WIDTH-1:0];
    reg [DATA_WIDTH-1:0] rom[2**ADDR_WIDTH-1:0];


     initial
     begin
          if(MEM_INDICATION == 0)
               $readmemh("lut/lut_u.mem", rom);
          else
               $readmemh("lut/lut_v.mem", rom);
     end


	assign q = rom[addr];


endmodule
