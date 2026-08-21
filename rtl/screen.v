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
    input  wire [13:0] read_addr,  // Address requested by HDMI driver
    output reg  [7:0] read_data   // 8-bit word output to HDMI driver
);
  
  // 512x256=131072
  // or 8192x16bit words
  reg [15:0] frame_buffer [0:8191];
  

  `ifdef SIMULATION
integer i;

  initial begin
    for (i = 0; i < 8192; i = i + 1) begin
      frame_buffer[i] = 16'b0;
    end
    //     $readmemb("Boot.hack", rom);
  end
  
  `endif
  always @(negedge clk) begin
    if (load) begin
        out <= frame_buffer[address]; // Preserve old-word read semantics during writes.
        frame_buffer[address] <= in;
    end else begin
        out <= frame_buffer[address]; // Normal read
    end
  end
  
  // Port B Read-Only Logic (Synchronous)
    always @(posedge clk) begin
      // 16-bit address lookup splits to high or low end of 16-bit word and selects 8 bits
        read_data <= frame_buffer[read_addr[13:1]][read_addr[0]*8 +:8];
    end
  
endmodule