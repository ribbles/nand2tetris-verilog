`timescale 1ns / 1ps

module Keyboard (
  input  wire [4:0]  btn,
  output wire [15:0] out
);

// Pure combinational lookup (priority encoder)
    assign out = (~btn[0]) ? 16'd32  : // Space
                 (~btn[1]) ? 16'd128 : // Enter
                 (~btn[2]) ? 16'd129 : // Backspace
                 (~btn[3]) ? 16'd130 : // Left
                 (~btn[4]) ? 16'd131 : // Up
                             16'd0;    // Default idle state

endmodule