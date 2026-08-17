`timescale 1ns / 1ps

module tb_keyboard;

    // Testbench signals
    reg  [4:0] btn;
    wire [15:0] out;

    // Instantiate Unit Under Test (UUT)
    Keyboard uut (
        .btn(btn),
        .out(out)
    );

    initial begin
        // Step 1: Idle state (all active-low buttons unpressed)
        btn = 5'b11111;
        #20;
        $display("[Time %0t] TEST 1: Idle state. Output = %d (Expected: 0)", $time, out);

        // Step 2: Press btn[0] (Space)
        btn = 5'b11110;
        #20;
        $display("[Time %0t] TEST 2: btn[0] (Space). Output = %d (Expected: 32)", $time, out);

        // Step 3: Release all buttons
        btn = 5'b11111;
        #20;
        $display("[Time %0t] TEST 3: Released. Output = %d (Expected: 0)", $time, out);

        // Step 4: Press btn[1] (Enter)
        btn = 5'b11101;
        #20;
        $display("[Time %0t] TEST 4: btn[1] (Enter). Output = %d (Expected: 128)", $time, out);

        // Step 5: Press btn[2] (Backspace)
        btn = 5'b11011;
        #20;
        $display("[Time %0t] TEST 5: btn[2] (Backspace). Output = %d (Expected: 129)", $time, out);

        // Step 6: Press btn[3] (Left)
        btn = 5'b10111;
        #20;
        $display("[Time %0t] TEST 6: btn[3] (Left). Output = %d (Expected: 130)", $time, out);

        // Step 7: Press btn[4] (Up)
        btn = 5'b01111;
        #20;
        $display("[Time %0t] TEST 7: btn[4] (Up). Output = %d (Expected: 131)", $time, out);

        // Step 8: Multiple buttons pressed simultaneously (Priority check)
        btn = 5'b11100;
        #20;
        $display("[Time %0t] TEST 8: Simultaneous Press. Output = %d", $time, out);

        // Step 9: Return to Idle
        btn = 5'b11111;
        #20;
        $display("[Time %0t] TEST 9: Return to Idle. Output = %d (Expected: 0)", $time, out);

        $finish;
    end

endmodule