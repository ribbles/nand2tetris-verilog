
module top (
    input  wire       clk,
    input  wire       btn1,
    input  wire       btn2,
    input  wire       btn_space,
    input  wire       btn_enter,
    input  wire       btn_backspace,
    input  wire       btn_left,
    input  wire       btn_up,
    output wire [5:0] led
);

wire [4:0] btn = { btn_space, btn_enter, btn_backspace, btn_left, btn_up }

Computer computer (
    .clk(clk),
    .reset(btn1),
    .btn
    input wire clk,
    input wire reset,
    input wire [4:0] btn

endmodule