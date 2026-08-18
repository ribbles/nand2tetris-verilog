`timescale 1ns / 1ps

module tb_rom_flash;

    reg         clk = 0;
    reg         reset = 0;
    reg [14:0]  addr = 15'b0;   // flash-word address: 0..16383
    reg         req = 0;         // request a fetch
    wire [15:0] data;        // requested Hack instruction
    wire        valid;       // one clock pulse: data is valid now

    integer i;
    wire [15:0] expected;
    assign expected = addr[0] 
                        ? { 2'b00, addr[14:1] }
                        : { 2'b11, ~addr[14:1] };
    
    always #2 clk = ~clk;

    rom_flash uut (
        .clk(clk),
        .reset(reset),
        .addr(addr),
        .req(req),
        .data(data),
        .valid(valid)
    );

    // Helper task to read and verify any address cleanly
    task check_read(input [14:0] word_addr);
    begin
        // 1. Setup address and assert req on falling edge (clean setup before rising edge)
        @(negedge clk);
        addr = word_addr;
        req = 1'b1;

        // 2. Wait for rising edge 1 (UUT samples req and goes busy)
        @(posedge clk);
        @(negedge clk);
        req = 1'b0;

        // 3. Wait for rising edge 2 (UUT finishes fetch and publishes valid data)
        @(posedge clk);
        @(negedge clk);
        if (!valid || data != expected) begin
            $display("[Time %0t] FAIL:    READ [addr=%0d data=%h expected=%h valid=%b]", $time, addr, data, expected, valid);
            $fatal(i, "Missing read signal");
        end

        // 4. Wait for rising edge 3 (UUT clears valid back to idle)
        @(posedge clk);
    end
    endtask

    initial begin
        $dumpfile("tb_rom_flash.vcd");
        $dumpvars(0, tb_rom_flash);

        // wait to settle in
        #10;

        // apply identification pattern to memory, e.g. ffff0000, fffe0001
        for (i = 0; i < 19456; i = i + 1) begin
            uut.reader.flash_inst.flash_inst.mem[i] = {~i[15:0], i[15:0]};
        end

        #2;

        // sweep the full memory
        for (i = 0; i < 19456 * 2; i = i + 1) begin
            check_read(i[14:0]);
        end

        $display("[Time %0t] ---------------- SUCCESS ----------------", $time);
        $dumpflush;
        $finish;
    end
endmodule
