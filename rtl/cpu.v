// `timescale 1ns / 1ps

module CPU (
    input wire clk,
    input wire reset,
    input wire [15:0] inM,        // Data from RAM[A]
    input wire [15:0] instruction, // Instruction from ROM
    output wire [15:0] outM,      // Data to write to RAM
    output wire writeM,           // RAM Write Enable
    output wire [14:0] addressM,  // Data memory address
    output wire [14:0] pc         // Instruction memory address
);

  reg [15:0] a_reg = 16'd0;
  reg [15:0] d_reg = 16'd0;
  wire [15:0] alu_out;
  wire [15:0] alu_y = instruction[12] ? inM : a_reg;
  wire [15:0] a_in = c_inst ? alu_out : instruction;
  wire a_load = a_inst | (c_inst & d1);
  wire c_inst = instruction[15];
  wire a_inst = ~instruction[15];
  wire d1, d2, d3;
  wire zr, ng;
  assign outM = alu_out;
  assign writeM = c_inst & d3;
//   assign addressM = a_reg[14:0];
  assign addressM = a_inst ? instruction[14:0] : a_reg[14:0];
  assign {d1, d2, d3} = {instruction[5:3]};

  // 1. Identify positive condition (neither zero nor negative)
  wire pos = ~zr & ~ng;

  // 2. Evaluate jump conditions against ALU flags
  wire j1 = instruction[2]; // Less than zero (ng)
  wire j2 = instruction[1]; // Equal to zero (zr)
  wire j3 = instruction[0]; // Greater than zero (pos)

  // 3. True if ANY enabled jump condition matches current ALU flags
  wire jump_condition = (j1 & ng) | (j2 & zr) | (j3 & pos);

  // 4. Load PC ONLY if it is a C-instruction AND jump condition is met
  wire pc_load = instruction[15] & jump_condition;
  
  PC pc1 (
    .clk(clk),
    .reset(reset),
    .load(pc_load),
    .inc(~pc_load),
    .in(a_reg[14:0]),
    .out(pc)
);
  
    ALU alu1 (
      .x(d_reg),
      .y(alu_y),
      .zx(instruction[11]),
      .nx(instruction[10]),
      .zy(instruction[9]),
      .ny(instruction[8]),
      .f(instruction[7]),
      .no(instruction[6]),
      .out(alu_out),
      .zr(zr),
      .ng(ng)
    );
  
always @(posedge clk) begin
    // --- A-Register Control ---
    // Loads instruction on A-inst, or ALU output on C-inst with d1 set
    if (a_inst) begin
      a_reg <= instruction;
    end else if (c_inst && d1) begin
      a_reg <= alu_out;
    end

    // --- D-Register Control ---
    // Independent block: Loads ALU output on C-inst with d2 set
    if (c_inst && d2) begin
      d_reg <= alu_out;
    end
end
  

endmodule