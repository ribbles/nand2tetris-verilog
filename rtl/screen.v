`timescale 1ns / 1ps

module Screen (
    // =======================================================
    // Port A: Hack CPU Interface (Standard Nand2Tetris)
    // =======================================================
    input  wire        clk,        // System clock
    input  wire [15:0] in,         // 16-bit data input from CPU
    input  wire        load,       // Write enable from CPU
    input  wire [12:0] address,    // 13-bit memory address from CPU (0 to 8191)
    output reg  [15:0] out,        // 16-bit data output to CPU

    // =======================================================
    // Port B: Display Driver Interface (Read-Only)
    // =======================================================
    input  wire [12:0] read_addr,  // Address requested by SPI driver
    output reg  [15:0] read_data   // 16-bit word output to SPI driver
);
  
  // 512x256=131072
  // or 8192x16bit words
  reg [15:0] frame_buffer [0:8191];
  

  `ifndef SYNTHESIS
  initial begin
    for (int i = 0; i < $size(frame_buffer); i++) begin
      frame_buffer[i] = 16'b0;
    end
    //     $readmemb("Boot.hack", rom);
  end
  
  `endif
  always @(negedge clk) begin
    if (load) begin
        frame_buffer[address] <= in;
        out <= in;          // Drive new write value directly to output
    end else begin
        out <= frame_buffer[address]; // Normal read
    end
  end
  
  // Port B Read-Only Logic (Synchronous)
    always @(posedge clk) begin
        read_data <= frame_buffer[read_addr];
    end
  
endmodule