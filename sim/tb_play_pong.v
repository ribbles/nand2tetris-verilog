`timescale 1ns / 1ns

module tb_play_pong;

    /*
     * tb_computer_screen:
     * Overhauled testbench to run the Hack Pong game on the Computer top-level module,
     * capturing the 512x256 monochrome frame buffer every 1 second of clock time.
     * Screen frames are saved as PBM (Portable BitMap) image files in 'frames/'
     * and can be assembled into an animated GIF/movie using scripts/make_movie.py.
     */

    // System Clock: 27 MHz (Tang Nano 9K target frequency: ~37.037 ns period)
    reg clk = 0;
    reg reset = 0;
    reg [4:0] btn = 5'b11111; // Active-low buttons (5'b11111 = all released/idle)
    wire [15:0] instruction;
    wire [15:0] inM;
    wire [15:0] outM;
    wire        writeM;
    wire [14:0] addressM;
    wire [14:0] pc;
    wire [15:0] rom_data;
    wire        rom_valid;
    wire        rom_req;
    wire        cpu_enable;

    // Frame capture configuration (default: 1 simulated second at 27 MHz)
    integer cycles_per_frame = 27000000;
    integer total_frames = 10; // default capture duration: 10 seconds
    integer frame_count = 0;
    integer active_pixels = 0;
    integer fd;
    string filename;

    always #1 clk = ~clk; 

    fetch_fsm fsm (
        .clk(clk),
        .reset(reset),
        .rom_data(rom_data),
        .rom_valid(rom_valid),
        .rom_req(rom_req),
        .cpu_enable(cpu_enable),
        .instruction(instruction)
    );

    CPU cpu (
        .clk(clk),
        .reset(reset),
        .enable(cpu_enable),
        .inM(inM),
        .instruction(instruction),
        .outM(outM),
        .writeM(writeM),
        .addressM(addressM),
        .pc(pc)
    );

    rom_flash rom (
        .clk(clk),
        .reset(reset),
        .addr(pc),
        .req(rom_req),
        .data(rom_data),
        .valid(rom_valid)
    );

    Memory mem (
        .clk(clk),
        .address(addressM),
        .in(outM),
        .load(writeM),
        .out(inM),
        .btn(btn)
    );


    // Array to load the compiled Hack program
    reg [15:0] hack_rom [0:32767];

    // Task to export the current 512x256 frame buffer as a binary PBM (P4) file
    task dump_screen_pbm(input integer f_idx, output integer act_pix);
        integer r, w, b;
        reg [15:0] word_val;
        begin
            act_pix = 0;
            $sformat(filename, "frames/frame_%04d.pbm", f_idx);
            fd = $fopen(filename, "w");
            if (fd == 0) begin
                $display("[ERROR] Could not open '%s' for writing.", filename);
            end else begin
                        // Use Netpbm P4 (binary) for faster frame output: header then packed bytes.
                        $fwrite(fd, "P4\n512 256\n");

                        // Nand2Tetris Hack screen mapping: 256 rows, 32 16-bit words per row.
                        for (r = 0; r < 256; r = r + 1) begin
                            for (w = 0; w < 32; w = w + 1) begin
                                word_val = mem.scr.frame_buffer[r * 32 + w];
                                // Count active bits in this word.
                                for (b = 0; b < 16; b = b + 1) begin
                                    if (word_val[b] == 1'b1) act_pix = act_pix + 1;
                                end
                                // Emit two bytes for the 16-bit word (MSB then LSB).
                                $fwrite(fd, "%c", word_val[15:8]);
                                $fwrite(fd, "%c", word_val[7:0]);
                            end
                        end
                $fclose(fd);
            end
        end
    endtask

    integer cycle_count;

    initial begin
        integer i;
        cycle_count = 0;

        $display("=========================================================");
        $display("   HACK COMPUTER SCREEN SIMULATION & MOVIE CAPTURE       ");
        $display("=========================================================");

        for (i = 0; i < 32768; i = i + 1) hack_rom[i] = 16'h0000;
        $display("[INFO] Loading 'hack/Pong.hack' into Flash memory...");
        $readmemb("hack/Pong.hack", hack_rom);
        for (i = 0; i < 16384; i = i + 1) begin
            rom.reader.flash_inst.flash_inst.mem[i] = {hack_rom[2*i], hack_rom[2*i+1]};
        end
        $display("[INFO] Pong.hack loaded into Flash model.");

        // Apply Reset
        reset = 1;
        btn = 5'b11111; // All buttons idle
        repeat (10) @(posedge clk);
        @(negedge clk);
        reset = 0;
        $display("[INFO] Reset released. Starting CPU execution at 27 MHz...");
        $display("[INFO] Capture plan: interval_cycles=%0d frames=%0d", cycles_per_frame, total_frames);
        
         while (frame_count < total_frames) begin
            if (cycle_count >= 27000000) begin
                dump_screen_pbm(frame_count, active_pixels);
                frame_count = frame_count + 1;
                $display("[FRAME %02d] Time=%0t | Active pixels=%0d", frame_count, $time, active_pixels);
                cycle_count = 0;
            end
        end

        $display("=========================================================");
        $display("[SUCCESS] Completed capture of %0d screen frames.", frame_count);
        $display("Run 'python ../scripts/make_movie.py' to generate 'pong_movie.gif'.");
        $display("=========================================================");
        $finish;
    end


endmodule
