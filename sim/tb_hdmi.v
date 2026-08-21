`timescale 1ns / 1ps

module tb_hdmi;

	// Simulation parameters
	localparam real PIXEL_FREQ = 25.2e6; // 25.2 MHz
	localparam real PIXEL_PERIOD_NS = 1e9 / PIXEL_FREQ; // ns period

	reg pixel_clk = 0;
	reg rst_n = 0;

	// HDMI interface wires from hdmi_timing
	wire h_sync;
	wire v_sync;
	wire video_active;
	wire [13:0] ram_addr;
	wire [8:0] fb_x_del;
	wire [7:0] fb_y_del;

	// Simulated BRAM output (one-cycle latency)
	reg [7:0] hdmi_read_data = 8'h00;

	// Simple frame buffer memory (16K bytes)
	reg [7:0] fb_mem [0:16383];

	integer i;

	// Clock generator for pixel clock
	initial begin
		forever begin
			#(PIXEL_PERIOD_NS/2.0) pixel_clk = ~pixel_clk;
		end
	end

	// Initialize memory with a test pattern
	initial begin
		for (i = 0; i < 16384; i = i + 1) begin
			// simple vertical stripes pattern: rotate bits by row
			fb_mem[i] = (i[7:0] ^ (i>>6));
		end
	end

	// Instantiate the full HDMI wrapper so we can observe TMDS outputs and use its internal timing
	wire O_tmds_clk_p;
	wire [2:0] O_tmds_data_p;

	HDMI hdmi_inst (
		.sys_clk_27m(pixel_clk), // use pixel_clk as a simple source for all clocks in sim
		.O_tmds_clk_p(O_tmds_clk_p),
		.O_tmds_data_p(O_tmds_data_p),
		.hdmi_read_addr(ram_addr),
		.hdmi_read_data(hdmi_read_data)
	);

	// Emulate BRAM read latency: sample ram_addr and provide data next cycle
	reg [13:0] sampled_addr;
	reg [13:0] prev_sampled_addr;
	// cycle counter and max-run constraint (frames)
	localparam integer H_TOTAL = 800;
	localparam integer V_TOTAL = 525;
	localparam integer MAX_FRAMES = 3;
	localparam integer MAX_CYCLES = H_TOTAL * V_TOTAL * MAX_FRAMES;
	reg [31:0] cycle_count = 0;

	// Sync/frame trackers
	reg prev_h_sync = 0;
	reg prev_v_sync = 0;
	integer cycles_since_h = 0;
	integer cycles_since_v = 0;
	integer h_pulses_in_frame = 0;

	initial begin
		$dumpfile("tb_hdmi.vcd");
		$dumpvars(0, tb_hdmi);
		// release reset after a few cycles
		#(PIXEL_PERIOD_NS*10);
		rst_n = 1;
	end

	always @(posedge pixel_clk) begin
		if (!rst_n) begin
			sampled_addr <= 14'd0;
			prev_sampled_addr <= 14'd0;
			hdmi_read_data <= 8'h00;
			cycle_count <= 0;
			prev_h_sync <= 0;
			prev_v_sync <= 0;
			cycles_since_h <= 0;
			cycles_since_v <= 0;
			h_pulses_in_frame <= 0;
		end else begin
			prev_sampled_addr <= sampled_addr;
			sampled_addr <= ram_addr;
			// read uses previous sampled_addr to model 1-cycle BRAM latency
			hdmi_read_data <= fb_mem[sampled_addr];
			cycle_count <= cycle_count + 1;

			// update sync trackers
			cycles_since_h = cycles_since_h + 1;
			cycles_since_v = cycles_since_v + 1;

			// detect rising edge of h_sync inside hdmi_inst
			if (hdmi_inst.timing_inst.h_sync && !prev_h_sync) begin
				if (cycles_since_h !== H_TOTAL) begin
					$fatal(1, "h_sync period mismatch: saw %0d expected %0d", cycles_since_h, H_TOTAL);
				end
				cycles_since_h = 0;
				h_pulses_in_frame = h_pulses_in_frame + 1;
			end

			// detect rising edge of v_sync inside hdmi_inst
			if (hdmi_inst.timing_inst.v_sync && !prev_v_sync) begin
				if (h_pulses_in_frame !== V_TOTAL) begin
					$fatal(1, "v_sync frame height mismatch: saw %0d expected %0d", h_pulses_in_frame, V_TOTAL);
				end
				if (cycles_since_v !== (H_TOTAL * V_TOTAL)) begin
					$fatal(1, "v_sync period mismatch: saw %0d expected %0d", cycles_since_v, H_TOTAL * V_TOTAL);
				end
				cycles_since_v = 0;
				h_pulses_in_frame = 0;
			end

			prev_h_sync <= hdmi_inst.timing_inst.h_sync;
			prev_v_sync <= hdmi_inst.timing_inst.v_sync;

			// time constraint: finish after MAX_CYCLES
			if (cycle_count >= MAX_CYCLES) begin
				$display("HDMI test passed (%0d frames) — ending simulation.", MAX_FRAMES);
				$finish;
			end
		end
	end

	// Monitor and assertions for pixel/data mapping. Print only the first few checks.
	integer disp_count = 0;
	integer bit_pos;
	reg expected_pixel;
	reg prev_pixel;

	always @(posedge pixel_clk) begin
		if (rst_n) begin
			if (hdmi_inst.timing_inst.video_active && (hdmi_inst.timing_inst.fb_x_del[2:0] == 3'b000)) begin
				if (disp_count < 10) begin
					$display("%0t ns: ram_addr=%0d fb_x=%0d fb_y=%0d sampled_data=%02x tmds=%b", $time, hdmi_inst.timing_inst.ram_addr, hdmi_inst.timing_inst.fb_x_del, hdmi_inst.timing_inst.fb_y_del, hdmi_read_data, O_tmds_data_p[0]);
					disp_count = disp_count + 1;
				end
				// basic range checks
				if (hdmi_inst.timing_inst.ram_addr >= 14'd16384) begin
					$fatal(1, "ram_addr out of range: %0d", hdmi_inst.timing_inst.ram_addr);
				end
				if (hdmi_inst.timing_inst.fb_y_del >= 8'd256) begin
					$fatal(1, "fb_y_del out of range: %0d", hdmi_inst.timing_inst.fb_y_del);
				end
				// data integrity: sampled BRAM data must equal expected memory
				if (hdmi_read_data !== fb_mem[prev_sampled_addr]) begin
					$fatal(1, "Data mismatch at sampled addr %0d: got %02x expected %02x", prev_sampled_addr, hdmi_read_data, fb_mem[prev_sampled_addr]);
				end
				// pixel mapping assertion
				bit_pos = 7 - hdmi_inst.timing_inst.fb_x_del[2:0];
				expected_pixel = (fb_mem[prev_sampled_addr] >> bit_pos) & 1;
				if (O_tmds_data_p[0] !== expected_pixel) begin
					$fatal(1, "Pixel mismatch: expected %b got %b at addr %0d bit %0d", expected_pixel, O_tmds_data_p[0], prev_sampled_addr, bit_pos);
				end
				prev_pixel <= O_tmds_data_p[0];
			end
		end
	end

endmodule