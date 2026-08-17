`timescale 1ns / 1ps

module tb_ram16k;

    reg         clk;
    reg  [15:0] in;
    reg         load;
    reg  [13:0] address;
    wire [15:0] out;

    integer error_count = 0;

    // Instantiate Unit Under Test (UUT)
    RAM16K uut (
        .clk(clk),
        .in(in),
        .load(load),
        .address(address),
        .out(out)
    );

    // Clock generator: 10ns period (5ns HIGH, 5ns LOW)
    always #5 clk = ~clk;

    // Task 1: Drive a write operation on posedge clk
    task write_mem;
        input [13:0] target_addr;
        input [15:0] data;
        begin
            @(posedge clk);
            address = target_addr;
            in      = data;
            load    = 1'b1;
        end
    endtask

    // Task 2: Drive a read operation on posedge clk and check output after negedge clk
    task check_read;
        input [359:0] desc;
        input [13:0]  target_addr;
        input [15:0]  expected;
        begin
            @(posedge clk);
            address = target_addr;
            in      = 16'sd0;
            load    = 1'b0;

            @(negedge clk);
            #1;

            if (out === expected) begin
                $display("[PASS] %-42s | Addr: %5d | Out: %6d | Exp: %6d", 
                         desc, address, $signed(out), $signed(expected));
            end else begin
                $display("[FAIL] %-42s | Addr: %5d | Out: %6d | Exp: %6d", 
                         desc, address, $signed(out), $signed(expected));
                error_count = error_count + 1;
            end
        end
    endtask

    initial begin
        $display("=========================================================================================");
        $display("STATUS | TEST DESCRIPTION                           | ADDRESS| ACTUAL | EXPECTED");
        $display("-----------------------------------------------------------------------------------------");

        clk = 0;
        in  = 16'sd0;
        load = 0;
        address = 14'd0;

        // Test 1: Read default state at address 0
        check_read("1. Read Addr 0 (Default Reset)", 14'd0, 16'sd0);

        // Test 2: Write -1 to address 0, then read back
        write_mem(14'd0, -16'sd1);
        check_read("2. Read Addr 0 (After Write -1)", 14'd0, -16'sd1);

        // Test 3: Write 12345 to address 4096, then read back
        write_mem(14'd4096, 16'sd12345);
        check_read("3. Read Addr 4096 (After Write 12345)", 14'd4096, 16'sd12345);

        // Test 4: Verify address 0 was not overwritten
        check_read("4. Read Addr 0 (Persistence Check)", 14'd0, -16'sd1);

        // Test 5: Boundary test at max address (16383)
        write_mem(14'd16383, 16'sd32767);
        check_read("5. Read Addr 16383 (Max Boundary Check)", 14'd16383, 16'sd32767);

        $display("=========================================================================================");
        if (error_count == 0) begin
            $display("OVERALL RESULT: PASSED ALL TESTS");
        end else begin
            $display("OVERALL RESULT: FAILED (%0d ERRORS)", error_count);
        end
        $display("=========================================================================================");
        $finish;
    end

endmodule