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

    // Instantiate the Unit Under Test (UUT)
    Memory uut (
        .clk(clk), 
        .in(in), 
        .load(load), 
        .address(address), 
        .out(out),
        .btn(btn)
    );

    // File I/O variables
    integer file_id, scan_count;
    reg [800:0] line;        // Buffer to read full string line
    reg [15:0]  exp_out;     // Expected output parsed from cmp file
    
    integer errors = 0;
    integer line_num = 0;
    integer test_count = 0;  // Track total executed comparisons

    // Clock generation (10ns period)
    always #5 clk = ~clk;

    initial begin
        // Initialize Inputs
        clk = 0;
        in = 0;
        load = 0;
        address = 0;
        btn = 5'b00000;

        // Open the compare file
        file_id = $fopen("Memory.cmp", "r");
        if (!file_id) begin
            $display("ERROR: Could not open Memory.cmp file.");
            $finish;
        end

        // Wait for global reset / clock setup
        #10;

        // Read file line by line
        while (!$feof(file_id)) begin
            scan_count = $fgets(line, file_id);
            line_num = line_num + 1;

            // Skip line 1 (header row)
            if (line_num > 1) begin
                
                // Parse 4 columns: | in (%d) | load (%d) | address (%b) | out (%d) |
                scan_count = $sscanf(line, "| %d | %d | %b | %d |", in, load, address, exp_out);

                if (scan_count == 4) begin
                    test_count = test_count + 1;

                    // 1. Drive CPU address/data on posedge clk
                    @(posedge clk);
                    #1; // Allow inputs to settle on Memory input pins

                    // 2. Wait for negedge clk where BRAM latches address & registers 'out'
                    @(negedge clk);
                    #1; // Allow BRAM read output register to settle

                    // 3. Evaluate output against expected value from cmp file
                    if (out !== exp_out) begin
                        $display("MISMATCH at line %0d: addr=%b, in=%0d, load=%0d | expected out=%0d, got out=%0d", 
                                  line_num, address, in, load, exp_out, out);
                        errors = errors + 1;
                    end
                end
            end
        end

        $fclose(file_id);
        
        $display("----------------------------------------");
        $display("Execution finished. Tested %0d vectors.", test_count);
        
        if (test_count == 0) begin
            $display("WARNING: 0 test vectors executed. Check Memory.cmp filename and format.");
        end else if (errors == 0) begin
            $display("TEST PASSED! All %0d vectors matched.", test_count);
        end else begin
            $display("TEST FAILED with %0d errors out of %0d tests.", errors, test_count);
        end
        $display("----------------------------------------");
            
        $finish;
    end

endmodule