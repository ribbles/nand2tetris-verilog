`timescale 1ns / 1ps

module tb_screen;
    reg clk = 0;
    reg [15:0] in = 0;
    reg load = 0;
    reg [12:0] address = 0;
    reg [13:0] read_addr = 0;
    wire [15:0] out;
    wire [7:0] read_data;
    integer errors = 0;

    Screen uut (
        .clk(clk), .in(in), .load(load), .address(address), .out(out),
        .read_addr(read_addr), .read_data(read_data)
    );

    always #5 clk = ~clk;

    task check_value;
        input [15:0] actual;
        input [15:0] wanted;
        input [8*32:1] label;
        begin
            if (actual !== wanted) begin
                $display("FAIL: %0s: got %h, expected %h", label, actual, wanted);
                errors = errors + 1;
            end else
                $display("PASS: %0s", label);
        end
    endtask

    initial begin
        // The CPU port is synchronous and returns the old word on a write.
        @(posedge clk); address = 13'd0; in = 16'h1234; load = 1;
        @(negedge clk); #1; check_value(out, 16'h0000, "write word zero returns old word");
        @(posedge clk); load = 0;
        @(negedge clk); #1; check_value(out, 16'h1234, "read back word zero");
        @(posedge clk); address = 13'd8191; in = 16'hbeef; load = 1;
        @(negedge clk); #1; check_value(out, 16'h0000, "write highest address returns old word");
        @(posedge clk); load = 0; read_addr = 14'd16382;
        @(negedge clk); #1; check_value(out, 16'hbeef, "read highest address");
        @(posedge clk); #1; check_value({8'h00, read_data}, 16'h00ef, "display read low byte");
        @(posedge clk); read_addr = 14'd16383;
        @(posedge clk); #1; check_value({8'h00, read_data}, 16'h00be, "display read high byte");

        if (errors != 0) $fatal(1, "Screen test failed with %0d errors", errors);
        $display("Screen test passed.");
        $finish;
    end
endmodule