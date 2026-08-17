`timescale 1ns / 1ps

module tb_rom32k;

    // Testbench Signals
    reg  [14:0] address;
    wire [15:0] out;

    // Instantiate Unit Under Test (UUT)
    ROM32K uut (
        .address(address),
        .out(out)
    );

    integer file_handle;
    integer i;
    reg [15:0] expected_data;
    integer errors;

    initial begin
        // ---------------------------------------------------------------------
        // 1. Generate a test .hack file for simulation
        // ---------------------------------------------------------------------
        file_handle = $fopen("Prog.hack", "w");
        
        // Write boundary and sample instruction patterns (16-bit binary)
        $fdisplay(file_handle, "0000000000000000"); // Addr 0: @0
        $fdisplay(file_handle, "1111110000010000"); // Addr 1: D=A
        $fdisplay(file_handle, "0000000000000101"); // Addr 2: @5
        $fdisplay(file_handle, "1110001100000001"); // Addr 3: D=D+A
        
        // Pad out to address 32767 to test boundary condition
        for (i = 4; i < 32767; i = i + 1) begin
            $fdisplay(file_handle, "0000000000000000");
        end
        $fdisplay(file_handle, "1111111111111111"); // Addr 32767: Max address test

        $fclose(file_handle);
        
        // Give file I/O time to finalize
        #10;

        // ---------------------------------------------------------------------
        // 2. Run Test Vectors
        // ---------------------------------------------------------------------
        $display("=== STARTING ROM32K TESTBENCH ===");
        errors = 0;

        // Test Address 0
        address = 15'd0; #10;
        check_output(15'd0, 16'b0000000000000000);

        // Test Address 1
        address = 15'd1; #10;
        check_output(15'd1, 16'b1111110000010000);

        // Test Address 2
        address = 15'd2; #10;
        check_output(15'd2, 16'b0000000000000101);

        // Test Address 3
        address = 15'd3; #10;
        check_output(15'd3, 16'b1110001100000001);

        // Test Boundary (Max Address 32767)
        address = 15'd32767; #10;
        check_output(15'd32767, 16'b1111111111111111);

        // Summary
        if (errors == 0) begin
            $display("=== TEST PASSED PERFECTLY ===");
        end else begin
            $display("=== TEST FAILED WITH %0d ERRORS ===", errors);
        end

        $finish;
    end

    // Task for verification
    task check_output(input [14:0] test_addr, input [15:0] expected);
        begin
            if (out !== expected) begin
                $display("[FAIL] Addr: %0d | Expected: %b (%h) | Got: %b (%h)", 
                          test_addr, expected, expected, out, out);
                errors = errors + 1;
            end else begin
                $display("[PASS] Addr: %0d | Output: %b (%h)", test_addr, out, out);
            end
        end
    endtask

endmodule