module HDMI (
    input wire sys_clk_27m,          // Physical Pin 52 (27 MHz Oscillator)
    
    // HDMI Output Interface (Mapped to your ELVDS pins in the .cst file)
    output wire O_tmds_clk_p,        // HDMI pins
    output wire [2:0] O_tmds_data_p, // HDMI pins

    // frame buffer data read interface
    output wire [13:0] hdmi_read_addr,  // Address requested by HDMI driver
    input  wire [7:0] hdmi_read_data   // 16-bit word output to HDMI driver

);


    // --- Clock and Internal Reset Generation ---
    wire serial_clk_126m;
    wire pixel_clk_25_2m;
    wire pll_lock;
    wire hdmi_reset_n;

    // Instantiate your working clock module
    TangNano_HDMI_Clock_Gen hdmi_clock (
        .sys_clk_27m(sys_clk_27m),
        .serial_clk_126m(serial_clk_126m),
        .pixel_clk_25_2m(pixel_clk_25_2m),
        .pll_lock(pll_lock)
    );

    // Use the PLL lock signal as our automatic internal active-low reset
    assign hdmi_reset_n = pll_lock;

    // --- Video Timing & Address Generation ---
    wire h_sync;
    wire v_sync;
    wire video_active;
    wire [13:0] hdmi_ram_addr;
    

    // hdmi_timing now also provides the byte-local X/Y coordinates
    // delayed to align with BRAM read latency (one cycle).
    wire [8:0] fb_x_del;
    wire [7:0] fb_y_del;

    hdmi_timing timing_inst (
        .pixel_clk(pixel_clk_25_2m),
        .rst_n(hdmi_reset_n),
        .h_sync(h_sync),
        .v_sync(v_sync),
        .video_active(video_active),
        .ram_addr(hdmi_ram_addr),
        .fb_x_del(fb_x_del),
        .fb_y_del(fb_y_del)
    );

    // --- Pipeline Delay Adjustments for BRAM Latency ---
    // Because BRAM takes 1 clock cycle to return data after receiving an address,
    // we must delay our video sync signals by 1 cycle so they line up with the incoming pixel data.
    reg h_sync_d;
    reg v_sync_d;
    reg video_active_d;

    always @(posedge pixel_clk_25_2m or negedge hdmi_reset_n) begin
        if (!hdmi_reset_n) begin
            h_sync_d       <= 1'b0;
            v_sync_d       <= 1'b0;
            video_active_d <= 1'b0;
        end else begin
            h_sync_d       <= h_sync;
            v_sync_d       <= v_sync;
            video_active_d <= video_active;
        end
    end

    // --- Monochrome Pixel Extraction & Bus Routing ---
    // Map the 8 packed monochrome pixels returned from BRAM (`hdmi_read_data`)
    // into individual pixel bits. The `hdmi_timing` module presents a byte
    // address (`hdmi_ram_addr`) and the corresponding byte-local X coordinate
    // (`fb_x_del[2:0]`) delayed by one cycle to match BRAM read latency.

    // Drive the external read interface so the Screen/BRAM can return the byte.
    assign hdmi_read_addr = hdmi_ram_addr;

    // Sample the returned byte from BRAM and pick the correct bit. We treat
    // bit 7 as the left-most pixel within the byte; adjust `7 - fb_x_del[2:0]`
    // if your CPU writes pixels LSB-first instead.
    reg [7:0] fb_byte;

    always @(posedge pixel_clk_25_2m or negedge hdmi_reset_n) begin
        if (!hdmi_reset_n) begin
            fb_byte <= 8'h00;
        end else begin
            fb_byte <= hdmi_read_data; // sample the byte that was requested
        end
    end

    // Select the pixel bit inside the sampled byte. Use the delayed X coordinate
    // (`fb_x_del[2:0]`) which aligns with `fb_byte` timing.
    wire pixel_bit = fb_byte[7 - fb_x_del[2:0]];
    wire pixel_out = video_active_d ? pixel_bit : 1'b0;

    wire [7:0] rgb_r = pixel_out ? 8'hFF : 8'h00;
    wire [7:0] rgb_g = pixel_out ? 8'hFF : 8'h00;
    wire [7:0] rgb_b = pixel_out ? 8'hFF : 8'h00;

    // --- DVI Core Instance (With explicit ELVDS configuration) ---
    DVI_TX_Top u_dvi_tx (
        .I_rst_n(hdmi_reset_n),
        .I_rgb_clk(pixel_clk_25_2m),
        .I_ser_clk(serial_clk_126m),
        .I_vdis(video_active_d),       // Pipeline delayed
        .I_hsync(h_sync_d),             // Pipeline delayed
        .I_vsync(v_sync_d),             // Pipeline delayed
        .I_rgb_r(rgb_r),
        .I_rgb_g(rgb_g),
        .I_rgb_b(rgb_b),
        .O_tmds_clk_p(O_tmds_clk_p),
        .O_tmds_clk_n(),                // Unconnected: ELVDS primitive manages the negative line automatically
        .O_tmds_data_p(O_tmds_data_p),
        .O_tmds_data_n()                // Unconnected
    );

endmodule

module hdmi_monochrome_display (
    // --- System Control Inputs ---
    input wire I_rst_n,             // Asynchronous active-low reset. 
                                    // Connect this to your system reset combined with your PLL lock signal 
                                    // (e.g., `assign hdmi_rst_n = sys_rst_n & pll_lock;`).

    // --- Clock Routing Inputs ---
    input wire I_rgb_clk,           // Pixel Clock (1x clock frequency). 
                                    // For a standard 640x480 @ 60Hz resolution, feed this with 25.2 MHz.
                                    // This drives the parallel video generation logic and pixel timing.

    input wire I_ser_clk,           // Serialization Clock (5x clock frequency). 
                                    // Must be exactly 5 times faster than I_rgb_clk and phase-aligned.
                                    // For 640x480, feed this with 126.0 MHz to shift out 10-bit TMDS data via DDR.

    // --- Video Timing Control Inputs ---
    input wire I_vdis,              // Video Display Enable / Active Video.
                                    // Must be driven HIGH when generating pixels inside the active window (e.g., 640x480).
                                    // Must be driven LOW during horizontal/vertical blanking front and back porches.

    input wire I_hsync,             // Horizontal Sync Pulse. 
                                    // Pass the active-high or active-low timing pulse directly from your VGA timing generator.

    input wire I_vsync,             // Vertical Sync Pulse. 
                                    // Pass the timing pulse directly from your VGA timing generator.

    // --- Parallel Color Data Inputs ---
    input wire [7:0] I_rgb_r,       // Red Color Bus. 
                                    // Parallel 8-bit red pixel data sampled on the rising edge of `I_rgb_clk`.
                                    // For monochrome, tie all bits to your single-bit pixel value (e.g., `{8{pixel}}`).

    input wire [7:0] I_rgb_g,       // Green Color Bus. 
                                    // Parallel 8-bit green pixel data. 
                                    // For monochrome, tie all bits to your single-bit pixel value.

    input wire [7:0] I_rgb_b,       // Blue Color Bus. 
                                    // Parallel 8-bit blue pixel data. 
                                    // For monochrome, tie all bits to your single-bit pixel value.

    // --- Physical Differential Serial Output Ports ---
    output wire O_tmds_clk_p,       // TMDS Positive Clock Channel.
    output wire O_tmds_clk_n,       // TMDS Negative Clock Channel.
                                    // This differential pair forwards the 1x Pixel Clock over the HDMI cable 
                                    // to the monitor for signal synchronization.

    output wire [2:0] O_tmds_data_p, // TMDS Positive Data Channels.
    output wire [2:0] O_tmds_data_n  // TMDS Negative Data Channels.
                                    // 3-lane differential bus carrying encoded serial video streams:
                                    // Channel 0: Transmits Blue data, HSYNC, and VSYNC pulses.
                                    // Channel 1: Transmits Green data and control packets.
                                    // Channel 2: Transmits Red data.
    );
    DVI_TX dvi_tx_inst (
        .I_rst_n(I_rst_n),
        .I_rgb_clk(I_rgb_clk),
        .I_ser_clk(I_ser_clk),
        .I_vdis(I_vdis),
        .I_hsync(I_hsync),
        .I_vsync(I_vsync),
        .I_rgb_r(I_rgb_r),
        .I_rgb_g(I_rgb_g),
        .I_rgb_b(I_rgb_b),
        .O_tmds_clk_p(O_tmds_clk_p),
        .O_tmds_clk_n(O_tmds_clk_n),
        .O_tmds_data_p(O_tmds_data_p),
        .O_tmds_data_n(O_tmds_data_n)
    );
endmodule

// Structural wrapper for Yosys combining rPLL and CLKDIV using working repo parameters
module TangNano_HDMI_Clock_Gen (
    input wire sys_clk_27m,      // Pin connected to the physical 27 MHz crystal oscillator
    output wire serial_clk_126m, // 126.0 MHz (5x serial clock routed to DVI_TX)
    output wire pixel_clk_25_2m, // 25.2 MHz (1x pixel clock routed to DVI_TX & Video Timing)
    output wire pll_lock        // High when clocks are stable and ready
);

    // 1. Instantiating the raw rPLL primitive utilizing the exact repository fractions
    // Math: (27 MHz / (2 + 1)) * (13 + 1) = 126.0 MHz Output
    rPLL #(
        .FCLKIN("27.0"),
        .IDIV_SEL(2),            // Input Divider: 2
        .FBDIV_SEL(13),          // Feedback Multiplier: 13
        .ODIV_SEL(4),            // Output Divider: 4
        .DEVICE("GW1NR-9C")      // Set to match your target Tang Nano 9K/20K silicon properties
    ) u_rpll_126m (
        .CLKIN(sys_clk_27m),
        .CLKOUT(serial_clk_126m),// Outputs clean 126.0 MHz line
        .LOCK(pll_lock),
        
        // Unused configuration attributes tied down
        .CLKOUTD(), .CLKOUTP(), .CLKOUTD3(), .RESET(1'b0), .RESET_P(1'b0),
        .CLKFB(1'b0), .FBDSEL(6'b0), .IDSEL(6'b0), .ODSEL(6'b0), .PSDA(4'b0),
        .DUTYDA(4'b0), .FDLY(4'b0)
    );

    // 2. Hardware Clock Divider Primitive used in the reference code
    CLKDIV #(
        .DIV_MODE("5"),          // Explicit Divide-By-5 parameter for Yosys/Apicula
        .GSREN("false")
    ) u_pixel_div5 (
        .CLKOUT(pixel_clk_25_2m),// Clean, phase-aligned 25.2 MHz line
        .HCLKIN(serial_clk_126m),// Inputs the 126.0 MHz line from rPLL
        .RESETN(pll_lock),       // Held safely in reset until rPLL achieves lock
        .CALIB(1'b1)             // Keep calibration line forced high
    );

endmodule


module hdmi_timing (
    input wire pixel_clk,           // 25.2 MHz clock from CLKDIV
    input wire rst_n,               // System reset (sys_rst_n & pll_lock)
    
    // Video Timing Signals for DVI_TX
    output wire h_sync,             // Horizontal sync pulse
    output wire v_sync,             // Vertical sync pulse
    output wire video_active,       // High only during active screen region
    
    // Shared Memory Map Address Interface
    output reg [13:0] ram_addr,     // 512 * 256 = 131,072 bits / 8 = 16,384 bytes

    // Delayed byte-local framebuffer coordinates (align with BRAM read data)
    output reg [8:0] fb_x_del,
    output reg [7:0] fb_y_del
);

    // Standard 640x480 @ 60Hz VGA Timing Parameters
    localparam H_ACTIVE = 640;
    localparam H_FRONT  = 16;
    localparam H_SYNC   = 96;
    localparam H_BACK   = 48;
    localparam H_TOTAL  = 800;

    localparam V_ACTIVE = 480;
    localparam V_FRONT  = 10;
    localparam V_SYNC   = 2;
    localparam V_BACK   = 33;
    localparam V_TOTAL  = 525;

    // Centering offsets for your 512x256 window inside 640x480 boundary
    localparam X_START  = (H_ACTIVE - 512) / 2; // 64
    localparam X_END    = X_START + 512;        // 576
    localparam Y_START  = (V_ACTIVE - 256) / 2; // 112
    localparam Y_END    = Y_START + 256;        // 368

    reg [9:0] h_cnt;
    reg [9:0] v_cnt;

    // Timing Counter Registers
    always @(posedge pixel_clk or negedge rst_n) begin
        if (!rst_n) begin
            h_cnt <= 0;
            v_cnt <= 0;
        end else begin
            if (h_cnt == H_TOTAL - 1) begin
                h_cnt <= 0;
                if (v_cnt == V_TOTAL - 1)
                    v_cnt <= 0;
                else
                    v_cnt <= v_cnt + 1;
            end else begin
                h_cnt <= h_cnt + 1;
            end
        end
    end

    // Direct Signal Assignments
    assign h_sync = (h_cnt >= (H_ACTIVE + H_FRONT)) && (h_cnt < (H_ACTIVE + H_FRONT + H_SYNC));
    assign v_sync = (v_cnt >= (V_ACTIVE + V_FRONT)) && (v_cnt < (V_ACTIVE + V_FRONT + V_SYNC));
    assign video_active = (h_cnt < H_ACTIVE) && (v_cnt < V_ACTIVE);

    // Track frame bounds
    wire inside_buffer = (h_cnt >= X_START && h_cnt < X_END) && 
                         (v_cnt >= Y_START && v_cnt < Y_END);

    wire [8:0] fb_x = inside_buffer ? (h_cnt - X_START) : 9'd0;
    wire [7:0] fb_y = inside_buffer ? (v_cnt - Y_START) : 8'd0;

    // Compute Address pointer (assuming 8-bit packed memory bytes: 512 / 8 = 64 bytes/row)
    // Address = (Y * 64) + (X / 8)
    wire [13:0] next_ram_addr = (fb_y * 64) + (fb_x >> 3);

    // Register address output to account for BRAM read sync latency
    always @(posedge pixel_clk or negedge rst_n) begin
        if (!rst_n) begin
            ram_addr <= 0;
            fb_x_del <= 9'd0;
            fb_y_del <= 8'd0;
        end else begin
            ram_addr <= next_ram_addr;
            // snapshot the local byte X/Y so they align with the read data
            fb_x_del <= fb_x;
            fb_y_del <= fb_y;
        end
    end

endmodule
