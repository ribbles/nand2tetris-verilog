module flash608k_reader (
    input  wire        clk,
    input  wire        reset,

    input  wire [13:0] word_addr,   
    input  wire        req,         // request a fetch
    output wire [31:0] data,        // data out
    output wire        valid,       // one clock pulse: data is valid now
    output wire        busy
);
    reg read = 0;
    wire [31:0] flash_dout;
    reg [31:0] data_reg = 0;

    flash608k_primitive flash_inst (
        .dout(flash_dout),
        .xe(read),
        .ye(read),
        .se(read),
        .prog(1'b0),
        .erase(1'b0),
        .nvstr(1'b0),
        .xadr({ 1'b0, word_addr[13:6] }), //9'b0 X Address (Row)
        .yadr(word_addr[5:0]) // 6'b0 Y Address (Column)
    );

    reg is_busy = 0, is_valid = 0;
    assign busy = is_busy;
    assign valid = is_valid;
    assign data = data_reg;

    always @(posedge clk) begin
        if (reset) begin
            is_busy <= 0;
            is_valid <= 0;
            read <= 0;
            data_reg <= 0;
        end else if (req & ~is_busy & ~valid) begin  // start fetching
            read <= 1;
            is_valid <= 0;
            is_busy <= 1;
        end else if (is_busy) begin // finished fetching - time to publish
            is_busy <= 0;
            is_valid <= 1;
            read <= 0;
            data_reg <= flash_dout;
        end else if (is_valid) begin // caller finished reading - time to reset
            is_busy <= 0;
            is_valid <= 0;
            read <= 0;
        end
    end
endmodule