// `timescale 1ns / 1ps
// `include "RAM16K"
// `include "Screen"
// `include "Keyboard"

module Memory (
    input  wire        clk,      // System clock for FPGA (crucial for BRAM)
    input  wire [15:0] in,       // 16-bit data input to be written
    input  wire        load,     // Write-enable flag (1 = write, 0 = read only)
    input  wire [14:0] address,  // 15-bit address from the CPU
  input  wire [4:0] btn,
    output wire [15:0] out       // 16-bit data output to the CPU
);

  wire is_ram = address[14] == 1'b0;
  wire is_scr = address[14:13] == 2'b10;
  wire is_kbd = address == 15'd25196;
  wire [15:0] ram_in, scr_in;
  wire [15:0] ram_out, scr_out, kbd_out;
  wire [12:0] read_addr; // TODO
  wire [15:0] read_data; // TODO
  
  assign ram_in = is_ram ? in : 16'b0;
  assign scr_in = is_scr ? in : 16'b0;
  
  RAM16K ram(clk, ram_in, is_ram & load, address[13:0], ram_out);
  Screen scr(clk, scr_in, is_scr & load, address[12:0], scr_out, read_addr, read_data);
  Keyboard kbd(btn, kbd_out);
  
  assign out = is_ram ? ram_out :
               is_scr ? scr_out :
    		   is_kbd ? kbd_out : out;
  

endmodule