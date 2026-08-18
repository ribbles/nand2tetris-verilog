`timescale 1ns / 1ps

module tb_flash_model;
    wire [31:0] DOUT;
    reg  [31:0] DIN;
    reg  [8:0]  XADR;
    reg  [5:0]  YADR;
    reg         XE, YE, SE, ERASE, PROG, NVSTR;

    FLASH608K uut (
        .DOUT(DOUT),
        .DIN(DIN),
        .XADR(XADR),
        .YADR(YADR),
        .XE(XE),
        .YE(YE),
        .SE(SE),
        .ERASE(ERASE),
        .PROG(PROG),
        .NVSTR(NVSTR)
    );

    initial begin
        // Init
        XADR = 0; YADR = 0; DIN = 0; XE = 0; YE = 0; SE = 0; ERASE = 0; PROG = 0; NVSTR = 0;
        #100;

        // --- STEP 1: WRITE DEADBEEF ---
        XADR = 9'd4; YADR = 6'd10; DIN = 32'hDEADBEEF;
        #10;
        XE = 1; YE = 1; PROG = 1; // Assert control lines
        #20;
        NVSTR = 1;                // Strobe high to execute write
        #16000;                   // Maintain physical program delay window
        NVSTR = 0;
        #10;
        XE = 0; YE = 0; PROG = 0;
        #100;

        // --- STEP 2: READ VALUE BACK ---
        XADR = 9'd4; YADR = 6'd10;
        #10;
        XE = 1; YE = 1; SE = 1;   // Sense amplifiers high to read out
        #40;
        $display("[TIME %0t] Read Out Value: %h (Expected: DEADBEEF)", $time, DOUT);
        XE = 0; YE = 0; SE = 0;

        #100;
        $finish;
    end
endmodule
