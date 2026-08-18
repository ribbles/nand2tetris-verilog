// `timescale 1ns / 1ps

module ROM32K (
	input  wire [14:0] address,     // Which instruction word to read (0 to 32767)
 	output wire [15:0] out          // 16-bit instruction at that address
);

  reg [15:0] rom [0:32767];
  
  initial begin
    $readmemb("Prog.hack", rom);
  end
  assign  out = rom[address];
  
//   always @(negedge clk) begin
//   end
  
endmodule