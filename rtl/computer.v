// `timescale 1ns / 1ps
// `include "CPU"
// `include "rom32k"
// `include "memory"

module Computer (
    input wire clk,
    input wire reset,
    input wire [4:0] btn
);

    // Internal wires connecting CPU, ROM32K, and Memory
    wire [15:0] instruction;
    wire [15:0] inM;
    wire [15:0] outM;
    wire        writeM;
    wire [14:0] addressM;
    wire [14:0] pc; // Instruction memory address - why is this called pc????

    CPU cpu (
        .clk(clk),
        .reset(reset),
        .inM(inM),
        .instruction(instruction),
        .outM(outM),
        .writeM(writeM),
        .addressM(addressM),
        .pc(pc)
    );
  
  ROM32K rom (//input  wire [14:0] address, output wire [16:0] out);
    .address(pc),
    .out(instruction)
  );
  Memory mem (//input wire clk, input wire [14:0] address, input wire [15:0] in, input wire load, output wire [15:0] out);
    .clk(clk),
    .address(addressM),
    .in(outM),
    .load(writeM),
    .out(inM),
    .btn(btn)
  );
  

endmodule