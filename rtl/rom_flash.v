module rom_flash (
    input  wire        clk,
    input  wire        reset,
    input  wire [14:0] addr,
    input  wire        req,     // request a fetch
    output wire [15:0] data,    // requested Hack instruction
    output wire        valid    // one clock pulse: data is valid now
);

    wire [13:0] word_addr = addr[14:1];
    wire [31:0] word_out;
    wire        busy;
    
    flash608k_reader reader (
        .clk(clk),
        .reset(reset),
        .word_addr(word_addr),
        .req(req),
        .data(word_out),
        .valid(valid),
        .busy(busy)
    );

    assign data = (busy || !valid || reset) 
                    ? 16'b0
                    : addr[0] 
                        ? word_out[15:0]
                        : word_out[31:16];

endmodule