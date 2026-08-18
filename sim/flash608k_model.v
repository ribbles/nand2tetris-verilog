module FLASH608K (
    input  wire [8:0]  XADR,
    input  wire [5:0]  YADR,
    input  wire        XE,
    input  wire        YE,
    input  wire        SE,
    input  wire        ERASE,
    input  wire        PROG,
    input  wire        NVSTR,
    input  wire [31:0] DIN,
    output reg  [31:0] DOUT
);
endmodule