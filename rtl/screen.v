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
    output wire [7:0] read_data   // 8-bit word output to HDMI driver
);

    // Two 8-bit true-dual-port RAMs implement the Hack's 8K x 16 Screen.
    // Equal-width ports allow Gowin to infer BSRAM rather than flip-flops.
    reg [7:0] frame_buffer_lo [0:8191];
    reg [7:0] frame_buffer_hi [0:8191];

  //`ifdef SIMULATION
integer i;
  initial begin
    for (i = 0; i < 2000; i = i + 4) begin
      frame_buffer_lo[i] = 8'h00;
      frame_buffer_lo[i+1] = 8'h00;
      frame_buffer_hi[i] = 8'hFF;
      frame_buffer_hi[i+1] = 8'hFF;
    end
  end
  //`endif

  // Port A: Hack CPU, one 16-bit word per address.
    always @(posedge clk) begin
        if (load) begin
            frame_buffer_lo[address] <= in[7:0];
            frame_buffer_hi[address] <= in[15:8];
            // Hold the CPU read output while writing; this is the mode the
            // Gowin dual-port BSRAM supports for this mixed-width layout.
        end else begin
            out <= {frame_buffer_hi[address], frame_buffer_lo[address]};
        end
    end

    // Port B: HDMI, one byte per address.
    reg [7:0] hdmi_read_lo;
    reg [7:0] hdmi_read_hi;
    reg hdmi_byte_select;

    always @(posedge clk) begin
        hdmi_read_lo <= frame_buffer_lo[read_addr[13:1]];
        hdmi_read_hi <= frame_buffer_hi[read_addr[13:1]];
        hdmi_byte_select <= read_addr[0];
    end

    assign read_data = hdmi_byte_select ? hdmi_read_hi : hdmi_read_lo;

endmodule
