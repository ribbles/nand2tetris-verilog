// `timescale 1ns / 1ps
// `include "CPU"
// `include "rom32k"
// `include "memory"

module Computer (
    input  wire       clk,
    input  wire       reset,
    input  wire [4:0] btn,
    output wire [5:0] debug
);

    wire [15:0] instruction;
    wire [15:0] inM;
    wire [15:0] outM;
    wire        writeM;
    wire [14:0] addressM;
    wire [14:0] pc;

    wire [15:0] rom_data;
    wire        rom_valid;
    wire        rom_req;
    wire        cpu_enable;

    fetch_fsm fsm (
        .clk(clk),
        .reset(reset),
        .rom_data(rom_data),
        .rom_valid(rom_valid),
        .rom_req(rom_req),
        .cpu_enable(cpu_enable),
        .instruction(instruction)
    );

    CPU cpu (
        .clk(clk),
        .reset(reset),
        .enable(cpu_enable),
        .inM(inM),
        .instruction(instruction),
        .outM(outM),
        .writeM(writeM),
        .addressM(addressM),
        .pc(pc)
    );
  
    rom_flash rom (
        .clk(clk),
        .reset(reset),
        .addr(pc),
        .req(rom_req),
        .data(rom_data),
        .valid(rom_valid)
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