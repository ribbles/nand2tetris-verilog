`timescale 1ns / 1ps

module tb_screen;

    reg clk;
    reg [15:0] in;
    reg load;
    reg [12:0] address;
    wire [15:0] out;
    
    // Unused read port during CPU memory testing
    wire [15:0] read_data;

    Screen uut (
        .clk(clk),
        .in(in),
        .load(load),
        .address(address),
        .out(out),
        .read_addr(13'b0),
        .read_data(read_data)
    );

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk;

    integer file, scan_result, errors = 0, line_num = 1;
    reg [8*100:1] header;
    reg [15:0] expected_out;

    initial begin
        file = $fopen("Screen.cmp", "r");
        if (file == 0) begin
            $display("ERROR: Could not open Screen.cmp");
            $finish;
        end

        scan_result = $fgets(header, file); // Skip header

        while (!$feof(file)) begin
            scan_result = $fscanf(file, "| %b | %b | %b | %b |\n", in, load, address, expected_out);
            if (scan_result == 4) begin
                @(negedge clk);
                @(posedge clk);
                #1;
                if (out !== expected_out) begin
                    $display("Mismatch at line %0d: Addr=%b, In=%b, Load=%b | Exp=%b, Got=%b", 
                              line_num, address, in, load, expected_out, out);
                    errors = errors + 1;
                end
                line_num = line_num + 1;
            end
        end

        $fclose(file);
        if (errors == 0) $display("SUCCESS: All Screen RAM tests passed!");
        else             $display("FAILED: %0d errors found.", errors);
        $finish;
    end

endmodule