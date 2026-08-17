`timescale 1ns / 1ps

module tb_pc;
    reg        clk;
    reg        reset;
    reg        load;
    reg        inc;
    reg [14:0] in;
    wire [14:0] out;

    // Instantiate PC module under test
    PC uut (
        .clk(clk),
        .reset(reset),
        .load(load),
        .inc(inc),
        .in(in),
        .out(out)
    );

    // 10ns clock generator
    always #5 clk = ~clk;


    integer i;
    reg [14:0] exp;
    reg [14:0] prev_out;

    initial begin
        clk = 0;
        reset = 0;
        load = 0;
        inc = 0;
        in = 15'h0000;

        // Initial power-on pulse
        reset = 1; #10; reset = 0; #10;

        $display("=== STARTING PC PERMUTATION TESTS ===");

        // Iterate through all 8 control signal combinations {reset, load, inc}
        for (i = 0; i < 8; i = i + 1) begin
            prev_out = out;
            {reset, load, inc} = i[2:0];
            in = 15'd1000 + (i * 10); // Dynamic input value for load tests

            exp = get_expected(prev_out, in, reset, load, inc);

            // Execute positive clock edge
            #10;

            if (out !== exp) begin
                $display("FAIL | Permutation %0d {rst:%b, ld:%b, inc:%b} | in=%0d | GOT out=%0d | EXP out=%0d",
                         i, reset, load, inc, in, out, exp);
            end else begin
                $display("PASS | Permutation %0d {rst:%b, ld:%b, inc:%b} | in=%0d | out=%0d",
                         i, reset, load, inc, in, out);
            end
        end

        $display("=== PC TESTING COMPLETE ===");
        $finish;
    end
endmodule


    // Golden model to derive expected state
    function automatic [15:0] get_expected(
        input [15:0] current_out,
        input [15:0] in_val,
        input rst, ld, increment
    );
        if (rst) begin            return 16'd0;
        end else if (ld) begin        return in_val;
        end else if (increment) begin return current_out + 1'b1;
        end else begin                return current_out;
        end 
    endfunction