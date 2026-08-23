`timescale 1ns / 1ps

module tb_memory;

    // Inputs
    reg clk;
    reg [15:0] in;
    reg load;
    reg [14:0] address;
    reg [4:0] btn;       // Hardware button input

    // Outputs
    wire [15:0] out;
    wire [7:0] hdmi_read_data;
    reg [13:0] hdmi_read_addr = 0;

    // Instantiate the Unit Under Test (UUT)
    Memory uut (
        .clk(clk), 
        .in(in), 
        .load(load), 
        .address(address), 
        .out(out), .btn(btn),
        .hdmi_read_addr(hdmi_read_addr), .hdmi_read_data(hdmi_read_data)
    );

    integer errors = 0;

    // Clock generation (10ns period)
    always #5 clk = ~clk;

    initial begin
        // Initialize Inputs
        clk = 0;
        in = 0;
        load = 0;
        address = 0;
        btn = 5'b11111;

        // Both memories are synchronous, read-old-data memories. RAM16K uses
        // the falling clock edge; Screen uses the rising edge for BRAM inference.
        // The old Nand2Tetris .cmp fixture assumes asynchronous RAM.
        @(posedge clk); address = 15'h0001; in = 16'h1234; load = 1;
        @(negedge clk); #1; check(16'h0000, "RAM write returns previous data");
        @(posedge clk); load = 0;
        @(negedge clk); #1; check(16'h1234, "RAM readback");

        @(negedge clk); address = 15'h4002; in = 16'hbeef; load = 1;
        @(posedge clk); #1; check(16'h0000, "Screen write returns previous data");
        @(negedge clk); load = 0;
        @(posedge clk); #1; check(16'hbeef, "Screen readback");

        @(negedge clk); address = 15'h6000; btn = 5'b11110;
        #1; check(16'd32, "Keyboard mapping");
        @(negedge clk); address = 15'h7000; btn = 5'b11111;
        #1; check(16'h0000, "Unmapped address");

        if (errors != 0) $fatal(1, "Memory test failed with %0d errors", errors);
        $display("Memory test passed.");
        $finish;
    end

    task check(input [15:0] expected, input [8*48:1] label);
        begin
            if (out !== expected) begin
                $display("FAIL: %0s: got %h, expected %h", label, out, expected);
                errors = errors + 1;
            end else
                $display("PASS: %0s", label);
        end
    endtask

endmodule
