// `timescale 1ns / 1ps
// `include "CPU"
// `include "rom32k"
// `include "memory"

module Computer (
    input wire clk,
    input wire reset,
    input wire [4:0] btn,
    output wire [5:0] debug
);

    wire [15:0] instruction;
    wire [15:0] inM;
    wire [15:0] outM;
    wire        writeM;
    wire [14:0] addressM;
    wire [14:0] pc;

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
  
  ROM32K rom (
    .address(pc),
    .out(instruction)
  );

  Memory mem (
    .clk(clk),
    .address(addressM),
    .in(outM),
    .load(writeM),
    .out(inM),
    .btn(btn)
  );

    assign debug = pc[5:0];

endmodule