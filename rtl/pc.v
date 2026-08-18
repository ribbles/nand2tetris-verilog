module PC (
    input  wire        clk,
    input  wire        reset,  // Reset signal (sets PC to 0)
    input  wire        load,   // Load signal (sets PC to 'in')
    input  wire        inc,    // Increment signal (PC = PC + 1)
  input  wire [14:0] in,     // 16-bit address input (from A register)
  output wire [14:0] out     // 16-bit address output (to ROM / CPU pc port)
);
  reg [14:0] pc_reg = 15'd0;
  assign out = pc_reg;
  
  always @(posedge clk) begin
    if (reset) begin
      pc_reg <= 15'b0;
    end else if (load) begin
      pc_reg <= in;
    end else if (inc) begin
      pc_reg <= out + 15'd1;
    end else begin
      pc_reg <= out;
    end
  end
  
endmodule
