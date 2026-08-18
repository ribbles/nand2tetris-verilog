module hack_rom (
    input  wire        clk,
    input  wire        reset,

    // Request from the CPU
    input  wire [14:0] addr,       // Hack instruction word address: 0..32767
    input  wire        req,        // request a fetch

    // Response to the CPU
    output wire [15:0] data,       // requested Hack instruction
    output wire        valid       // one clock pulse: data is valid now
);
endmodule