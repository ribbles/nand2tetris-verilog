// Minimal simulation stubs for HDMI primitives used only in testbenches
// These are behavioral placeholders for unit tests only; they are not used for synthesis.

module rPLL #(parameter FCLKIN="27.0", IDIV_SEL=0, FBDIV_SEL=0, ODIV_SEL=0, DEVICE="GW1N-9C") (
    input  wire CLKIN,
    output wire CLKOUT,
    output wire LOCK,
    output wire CLKOUTD, CLKOUTP, CLKOUTD3,
    input  wire RESET, RESET_P,
    input  wire CLKFB,
    input  wire [5:0] FBDSEL, IDSEL, ODSEL,
    input  wire [3:0] PSDA, DUTYDA, FDLY
);
    // For simulation, forward the input clock and assert lock.
    assign CLKOUT = CLKIN;
    assign LOCK = 1'b1;
    assign CLKOUTD = 1'b0;
    assign CLKOUTP = 1'b0;
    assign CLKOUTD3 = 1'b0;
endmodule

module CLKDIV #(parameter DIV_MODE="5", GSREN="false") (
    output wire CLKOUT,
    input  wire HCLKIN,
    input  wire RESETN,
    input  wire CALIB
);
    // Pass-through for simulation; not an actual divide.
    assign CLKOUT = HCLKIN;
endmodule

// Minimal DVI TX top stub for simulation: consumes parallel RGB and outputs nothing
module DVI_TX_Top (
    input  wire I_rst_n,
    input  wire I_rgb_clk,
    input  wire I_serial_clk,
    input  wire I_rgb_de,
    input  wire I_rgb_hs,
    input  wire I_rgb_vs,
    input  wire [7:0] I_rgb_r,
    input  wire [7:0] I_rgb_g,
    input  wire [7:0] I_rgb_b,
    output wire O_tmds_clk_p,
    output wire O_tmds_clk_n,
    output wire [2:0] O_tmds_data_p,
    output wire [2:0] O_tmds_data_n
);
    assign O_tmds_clk_p = 1'b0;
    assign O_tmds_clk_n = 1'b0;
    assign O_tmds_data_p = 3'b000;
    assign O_tmds_data_n = 3'b000;
endmodule
