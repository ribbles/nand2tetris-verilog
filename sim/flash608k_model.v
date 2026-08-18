`timescale 1ns / 1ps

module FLASH608K (
    output reg  [31:0] DOUT,
    input  wire [31:0] DIN,
    input  wire [8:0]  XADR,
    input  wire [5:0]  YADR,
    input  wire        XE,
    input  wire        YE,
    input  wire        SE,
    input  wire        ERASE,
    input  wire        PROG,
    input  wire        NVSTR
);

    // Depth Calculation: 304 rows * 64 columns = 19,456 words of 32-bit (608 Kbits)
    reg [31:0] mem [0:19455];

    // Address and Page math (XADR[8:3] selects 1 of 38 pages, XADR[2:0] selects 1 of 8 rows per page)
    wire [14:0] abs_addr   = (XADR * 7'd64) + YADR;
    wire [5:0]  page_num   = XADR[8:3];
    wire [14:0] page_start = page_num * 10'd512;

    initial begin
        integer i;
        for (i = 0; i < 19456; i = i + 1) begin
            mem[i] = 32'hFFFFFFFF; // Erased flash defaults to all 1s
        end
    end

    // --- ASYNCHRONOUS READ (Combinational) ---
    always @(*) begin
        if (XE && YE && SE && !ERASE && !PROG && !NVSTR) begin
            DOUT = mem[abs_addr];
        end else begin
            DOUT = 32'hzzzzzzzz; // Tristate when idle or mid-write/erase operation
        end
    end

    // --- ASYNCHRONOUS WRITE / ERASE (Triggered on NVSTR strobe) ---
    always @(posedge NVSTR) begin
        // 1. Word Program Sequence
        if (XE && YE && PROG && !ERASE) begin
            mem[abs_addr] = mem[abs_addr] & DIN; // Hardware realization: logic ANDs down 1s to 0s
        end
        // 2. Page Erase Sequence (Wipes 512 words / 2048 bytes per page back to all 1s)
        else if (XE && ERASE && !PROG) begin
            integer j;
            for (j = 0; j < 512; j = j + 1) begin
                mem[page_start + j] = 32'hFFFFFFFF;
            end
        end
    end

endmodule
