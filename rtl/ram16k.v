// `timescale 1ns / 1ps

module RAM16K (
    input  wire        clk,      // Main system clock signal
    input  wire [15:0] in,       // 16-bit data input vector to write into memory
    input  wire        load,     // Write enable (1 = write 'in' to 'address', 0 = read-only)
    input  wire [13:0] address,  // 14-bit address bus (selects location 0 to 16383)
    output reg  [15:0] out       // 16-bit data output registered on negedge clk
);
  
  reg [15:0] ram [0:16383];
  
  `ifndef SYNTHESIS
  initial begin
    for (int i = 0; i < 16384; i++) begin
      ram[i] = 16'b0;
      end
  end
    
//   always @(negedge clk) begin
//     out <= ram[address];
//     if (load) begin // write
//       ram[address] <= in;
//     end
//   end
  
  `endif
  always @(negedge clk) begin
    if (load) begin
        ram[address] <= in;
        out <= in;          // Drive new write value directly to output
    end else begin
        out <= ram[address]; // Normal read
    end
  end
  
endmodule