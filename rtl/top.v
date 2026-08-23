module top (
    input  wire       clk,
    input  wire       btn1,
    input  wire       btn2,
    input  wire       btn_space,
    input  wire       btn_enter,
    input  wire       btn_backspace,
    input  wire       btn_left,
    input  wire       btn_up,
    output wire [5:0] led,
    output wire       O_tmds_clk_p,
    output wire       O_tmds_clk_n,
    output wire [2:0] O_tmds_data_p,
    output wire [2:0] O_tmds_data_n
);

    wire [4:0] btn = {
        btn_up,
        btn_left,
        btn_backspace,
        btn_enter,
        btn_space & btn2
    };

    wire [5:0] debug;

    Computer computer (
        .clk(clk),
        .reset(btn1),
        .btn(btn),
        .debug(debug),
        .O_tmds_clk_p(O_tmds_clk_p),
        .O_tmds_clk_n(O_tmds_clk_n),
        .O_tmds_data_p(O_tmds_data_p),
        .O_tmds_data_n(O_tmds_data_n)
    );

    assign led = ~debug;
endmodule
