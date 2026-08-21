// DVI_TX_Top wrapper using SVO TMDS encoder and Gowin serializers
// Maps the existing parallel RGB + sync interface to 3 TMDS lanes

module DVI_TX_Top (
    input  wire I_rst_n,
    input  wire I_rgb_clk,
    input  wire I_ser_clk,
    input  wire I_vdis,
    input  wire I_hsync,
    input  wire I_vsync,
    input  wire [7:0] I_rgb_r,
    input  wire [7:0] I_rgb_g,
    input  wire [7:0] I_rgb_b,
    output wire O_tmds_clk_p,
    output wire O_tmds_clk_n,
    output wire [2:0] O_tmds_data_p,
    output wire [2:0] O_tmds_data_n
);

    // TMDS encoding: use the open-source `svo_tmds` encoder from the
    // Sipeed TangNano example. It produces a 10-bit word per color channel.
    wire [9:0] dout_r;
    wire [9:0] dout_g;
    wire [9:0] dout_b;

    wire [1:0] ctrl; // {vsync, hsync}
    assign ctrl = {I_vsync, I_hsync};

    svo_tmds tmds_r (
        .clk(I_rgb_clk),
        .resetn(I_rst_n),
        .de(I_vdis),
        .ctrl(ctrl),
        .din(I_rgb_r),
        .dout(dout_r)
    );

    svo_tmds tmds_g (
        .clk(I_rgb_clk),
        .resetn(I_rst_n),
        .de(I_vdis),
        .ctrl(ctrl),
        .din(I_rgb_g),
        .dout(dout_g)
    );

    svo_tmds tmds_b (
        .clk(I_rgb_clk),
        .resetn(I_rst_n),
        .de(I_vdis),
        .ctrl(ctrl),
        .din(I_rgb_b),
        .dout(dout_b)
    );

    // Pack per-bit lanes for the OSER10 array: D0..D9 are 3-bit vectors
    wire [2:0] tmds_d0;
    wire [2:0] tmds_d1;
    wire [2:0] tmds_d2;
    wire [2:0] tmds_d3;
    wire [2:0] tmds_d4;
    wire [2:0] tmds_d5;
    wire [2:0] tmds_d6;
    wire [2:0] tmds_d7;
    wire [2:0] tmds_d8;
    wire [2:0] tmds_d9;

    assign tmds_d0 = {dout_r[0], dout_g[0], dout_b[0]};
    assign tmds_d1 = {dout_r[1], dout_g[1], dout_b[1]};
    assign tmds_d2 = {dout_r[2], dout_g[2], dout_b[2]};
    assign tmds_d3 = {dout_r[3], dout_g[3], dout_b[3]};
    assign tmds_d4 = {dout_r[4], dout_g[4], dout_b[4]};
    assign tmds_d5 = {dout_r[5], dout_g[5], dout_b[5]};
    assign tmds_d6 = {dout_r[6], dout_g[6], dout_b[6]};
    assign tmds_d7 = {dout_r[7], dout_g[7], dout_b[7]};
    assign tmds_d8 = {dout_r[8], dout_g[8], dout_b[8]};
    assign tmds_d9 = {dout_r[9], dout_g[9], dout_b[9]};

    // OSER10 array serializes the 10-bit words using pixel clock (PCLK)
    // and 5x pixel clock (FCLK). RESET is active-high in this primitive.
    OSER10 tmds_serdes [2:0] (
        .Q(), // unused; we will read via the aggregate ports below
        .D0(tmds_d0),
        .D1(tmds_d1),
        .D2(tmds_d2),
        .D3(tmds_d3),
        .D4(tmds_d4),
        .D5(tmds_d5),
        .D6(tmds_d6),
        .D7(tmds_d7),
        .D8(tmds_d8),
        .D9(tmds_d9),
        .PCLK(I_rgb_clk),
        .FCLK(I_ser_clk),
        .RESET(~I_rst_n)
    );

    // The OSER10 array drives a 3-bit bus `tmds_d` we can wire through
    wire [2:0] tmds_d;
    // Yosys / cells_sim provides the `ELVDS_OBUF` primitive used below.

    // ELVDS_OBUF drives the differential outputs; first element is the
    // clock lane (we forward the pixel clock as the TMDS clock source).
    ELVDS_OBUF tmds_bufds [3:0] (
        .I({I_rgb_clk, tmds_d}),
        .O({O_tmds_clk_p, O_tmds_data_p}),
        .OB({O_tmds_clk_n, O_tmds_data_n})
    );

endmodule
