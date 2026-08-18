module top (
    input  wire       clk,
    input  wire       btn1,
    input  wire       btn2,
    output wire [5:0] led
);

    // btn2 is the active-low Hack keyboard Space key; all other keys idle.
    wire [4:0] btn = {4'b1111, btn2};

    Computer computer (
        .clk(clk),
        .reset(btn1),
        .btn(btn)
    );

    assign led = 6'b0;
endmodule