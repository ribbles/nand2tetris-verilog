create_clock -name clk -period 37.037 [get_ports {clk}]

create_clock -name serial_clk_126m -period 7.9365 [get_pins {computer/hdmi/hdmi_clock/u_rpll_126m/CLKOUT}]

create_clock -name pixel_clk_25_2m -period 39.6825 [get_pins {computer/hdmi/hdmi_clock/u_pixel_div5/CLKOUT}]
