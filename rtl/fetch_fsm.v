module fetch_fsm (
    input  wire        clk,
    input  wire        reset,
    input  wire [15:0] rom_data,
    input  wire        rom_valid,
    output reg         rom_req,
    output wire        cpu_enable,
    output reg  [15:0] instruction
);

    localparam STATE_FETCH   = 1'b0;
    localparam STATE_EXECUTE = 1'b1;

    reg state = STATE_FETCH;

    assign cpu_enable = (state == STATE_EXECUTE);

    always @(posedge clk) begin
        if (reset) begin
            state       <= STATE_FETCH;
            rom_req     <= 1'b0;
            instruction <= 16'd0;
        end else begin
            case (state)
                STATE_FETCH: begin
                    if (rom_valid) begin
                        instruction <= rom_data;
                        rom_req     <= 1'b0;
                        state       <= STATE_EXECUTE;
                    end else begin
                        rom_req     <= 1'b1;
                    end
                end

                STATE_EXECUTE: begin
                    rom_req <= 1'b0;
                    state   <= STATE_FETCH;
                end
            endcase
        end
    end

endmodule
