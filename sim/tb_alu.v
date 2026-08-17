`timescale 1ns / 1ps

module tb_alu;
    reg [15:0] x, y;
    reg zx, nx, zy, ny, f, no;
    wire [15:0] out;
    wire zr, ng;

    ALU uut (
        .x(x), .y(y),
        .zx(zx), .nx(nx), .zy(zy), .ny(ny),
        .f(f), .no(no),
        .out(out), .zr(zr), .ng(ng)
    );
initial begin
    integer file, r;
    reg [15:0] exp_out;
    reg exp_zr, exp_ng;
    reg [8*256:1] line; // Fixed: Use a reg vector for string buffer

    file = $fopen("cmp/ALU.cmp", "r");
    if (file == 0) begin
        $display("Could not open ALU.cmp");
        $finish; // Fixed: Avoids simulator-specific $fatal syntax
    end

    // Skip header line
    r = $fgets(line, file);

    // Read lines formatted as "| x | y | zx | nx | zy | ny | f | no | out | zr | ng |"
    while (!$feof(file)) begin
        r = $fscanf(file, " | %b | %b | %b | %b | %b | %b | %b | %b | %b | %b | %b | \n",
                    x, y, zx, nx, zy, ny, f, no, exp_out, exp_zr, exp_ng);
        #10;
        if (out !== exp_out || zr !== exp_zr || ng !== exp_ng) begin
            $display("FAIL: x=%b y=%b | Got out=%b zr=%b ng=%b | Exp out=%b zr=%b ng=%b",
                     x, y, out, zr, ng, exp_out, exp_zr, exp_ng);
        end else begin
          $display("SUCCESS: x=%b y=%b | Got out=%b zr=%b ng=%b | Exp out=%b zr=%b ng=%b",
                     x, y, out, zr, ng, exp_out, exp_zr, exp_ng);          
        end
    end
    $fclose(file);
    $display("ALU.cmp verification complete.");
    $finish;
end  

//     initial begin
//         $display("--- Starting Cumulative ALU Tests ---");

//         // --- LESSON 1 TESTS (X Pre-processing) ---
//         // Pass x through (zx=0, nx=0, zy=1, ny=0, f=0, no=0) -> x & 0 = 0, so let's use f=1 (add 0)
//         x = 16'hAAAA; y = 16'h1234; zx = 0; nx = 0; zy = 1; ny = 0; f = 1; no = 0; #10;
//         if (out !== 16'hAAAA) $display("FAIL L1: Pass x through. Got %h", out);
//         else $display("PASS L1: Pass x through");

//         // Zero X (zx=1, nx=0, zy=1, ny=0, f=1, no=0) -> 0 + 0 = 0
//         x = 16'hAAAA; y = 16'h1234; zx = 1; nx = 0; zy = 1; ny = 0; f = 1; no = 0; #10;
//         if (out !== 16'h0000) $display("FAIL L1: Zero X. Got %h", out);
//         else $display("PASS L1: Zero X");

//         // --- LESSON 2 TESTS (Core AND / ADD) ---
//         // AND operation (x=00FF, y=0F0F, f=0)
//         x = 16'h00FF; y = 16'h0F0F; zx = 0; nx = 0; zy = 0; ny = 0; f = 0; no = 0; #10;
//         if (out !== 16'h000F) $display("FAIL L2: AND logic. Got %h", out);
//         else $display("PASS L2: AND logic");

//         // ADD operation (x=5, y=7, f=1)
//         x = 16'h0005; y = 16'h0007; zx = 0; nx = 0; zy = 0; ny = 0; f = 1; no = 0; #10;
//         if (out !== 16'h000C) $display("FAIL L2: Addition. Got %h", out);
//         else $display("PASS L2: Addition");

//         // --- LESSON 3 NEW TESTS (Full Hack ALU & Flags) ---
//         // Compute Constant 0: zx=1, nx=0, zy=1, ny=0, f=1, no=0 -> out=0, zr=1, ng=0
//         x = 16'h1234; y = 16'h5678; zx = 1; nx = 0; zy = 1; ny = 0; f = 1; no = 0; #10;
//         if (out !== 16'h0000 || zr !== 1'b1 || ng !== 1'b0) 
//             $display("FAIL L3: Constant 0 / zr flag. Got out=%h, zr=%b, ng=%b", out, zr, ng);
//         else $display("PASS L3: Constant 0 / zr flag");

//         // Compute Constant -1: zx=1, nx=1, zy=1, ny=0, f=1, no=0 -> (-1 + 0) = -1 (FFFF), zr=0, ng=1
//         x = 16'h1234; y = 16'h5678; zx = 1; nx = 1; zy = 1; ny = 0; f = 1; no = 0; #10;
//         if (out !== 16'hFFFF || zr !== 1'b0 || ng !== 1'b1) 
//             $display("FAIL L3: Constant -1 / ng flag. Got out=%h, zr=%b, ng=%b", out, zr, ng);
//         else $display("PASS L3: Constant -1 / ng flag");

//         // Compute x - y (10 - 3 = 7): zx=0, nx=1, zy=0, ny=1, f=1, no=1
//         x = 16'd10; y = 16'd3; zx=0; nx=1; zy=0; ny=0; f=1; no=1;
//       //x = 16'd10; y = 16'd3; zx=0, nx=1, zy=0, ny=0, f=1, no=1 with 
//       	// BUG x = 16'd10; y = 16'd3; zx = 0; nx = 1; zy = 0; ny = 0; f = 1; no = 1; 		
//       #10;
//       if (out !== 16'd7) $display("FAIL L3: Subtraction (x - y). Expected 7, got %d (%h)", out, out);
//         else $display("PASS L3: Subtraction (x - y)");
      
//       // Compute x - y (15 - 5 = 10)
// x = 16'd15; y = 16'd5; zx = 0; nx = 1; zy = 0; ny = 0; f = 1; no = 1; #10;
// if (out !== 16'd10) $display("FAIL: 15 - 5 expected 10, got %d", out);

// // Compute x - y (5 - 12 = -7 / 16'hFFF9)
// x = 16'd5; y = 16'd12; zx = 0; nx = 1; zy = 0; ny = 0; f = 1; no = 1; #10;
// if (out !== 16'shFFF9) $display("FAIL: 5 - 12 expected -7, got %d", $signed(out));
      
//         $display("--- All tests finished ---");
//         $finish;
//     end
endmodule