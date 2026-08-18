`timescale 1ns / 1ps

module tb_flash_primative;
    wire [31:0] dout;
    reg  [31:0] din;
    reg  [8:0]  xadr;
    reg  [5:0]  yadr;
    reg         xe, ye, se, erase, prog, nvstr;

    flash608k_primitive uut (
        .dout(dout),
        .din(din),
        .xadr(xadr),
        .yadr(yadr),
        .xe(xe),
        .ye(ye),
        .se(se),
        .erase(erase),
        .prog(prog),
        .nvstr(nvstr)
    );

    initial begin
        // Init
        xadr = 0; yadr = 0; din = 0; xe = 0; ye = 0; se = 0; erase = 0; prog = 0; nvstr = 0;
        #100;

        // --- STEP 1: WRITE DEADBEEF ---
        xadr = 9'd4; yadr = 6'd10; din = 32'hDEADBEEF;
        #10;
        xe = 1; ye = 1; prog = 1; // Assert control lines
        #20;
        nvstr = 1;                // Strobe high to execute write
        #16000;                   // Maintain physical program delay window
        nvstr = 0;
        #10;
        xe = 0; ye = 0; prog = 0;
        #100;

        // --- STEP 2: READ VALUE BACK ---
        xadr = 9'd4; yadr = 6'd10;
        #10;
        xe = 1; ye = 1; se = 1;   // Sense amplifiers high to read out
        #40;
        $display("[TIME %0t] Read Out Value: %h (Expected: DEADBEEF)", $time, dout);
        xe = 0; ye = 0; se = 0;

        #100;
        $finish;
    end
endmodule
