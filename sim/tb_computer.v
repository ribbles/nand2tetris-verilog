`timescale 1ns / 1ps

module tb_computer;

    reg clk = 0;
    reg reset = 0;
    reg [4:0] btn = 5'b0;
    wire [5:0] debug;

    always #5 clk = ~clk;

    Computer uut (
        .clk(clk),
        .reset(reset),
        .btn(btn),
        .debug(debug)
    );

    // Helper task to write a 16-bit Hack instruction into the flash model
    task write_instruction(input [14:0] h_addr, input [15:0] inst);
        integer word_idx;
        begin
            word_idx = h_addr >> 1;
            if (h_addr[0] == 1'b0) begin
                uut.rom.reader.flash_inst.flash_inst.mem[word_idx][31:16] = inst;
            end else begin
                uut.rom.reader.flash_inst.flash_inst.mem[word_idx][15:0] = inst;
            end
        end
    endtask

    // Hack instruction definitions for test program
    // PC 0: @1234      -> A = 1234
    // PC 1: D=A        -> D = 1234
    // PC 2: @0         -> A = 0
    // PC 3: M=D        -> RAM[0] = 1234
    // PC 4: @10        -> A = 10
    // PC 5: 0;JMP      -> PC jumps to 10
    // PC 10: @999      -> A = 999
    // PC 11: D=A       -> D = 999
    // PC 12: @1        -> A = 1
    // PC 13: M=D       -> RAM[1] = 999
    // PC 14: @14       -> A = 14
    // PC 15: 0;JMP     -> Infinite loop
    initial begin
        integer i;
        $dumpfile("tb_computer.vcd");
        $dumpvars(0, tb_computer);

        // Initialize flash memory with NOPs / zeros
        for (i = 0; i < 19456; i = i + 1) begin
            uut.rom.reader.flash_inst.flash_inst.mem[i] = 32'h00000000;
        end

        // Load test program
        write_instruction(15'd0,  16'd1234);                 // @1234
        write_instruction(15'd1,  16'b111_0_110000_010_000); // D=A
        write_instruction(15'd2,  15'd0);                    // @0
        write_instruction(15'd3,  16'b111_0_001100_001_000); // M=D
        write_instruction(15'd4,  15'd10);                   // @10
        write_instruction(15'd5,  16'b111_0_101010_000_111); // 0;JMP
        write_instruction(15'd10, 15'd999);                  // @999
        write_instruction(15'd11, 16'b111_0_110000_010_000); // D=A
        write_instruction(15'd12, 15'd1);                    // @1
        write_instruction(15'd13, 16'b111_0_001100_001_000); // M=D
        write_instruction(15'd14, 15'd14);                   // @14
        write_instruction(15'd15, 16'b111_0_101010_000_111); // 0;JMP

        // Apply Reset
        reset = 1;
        #20;
        @(negedge clk);
        reset = 0;

        $display("=== STARTING COMPUTER FSM VERIFICATION ===");

        // Wait for execution to reach PC = 10 (after jump)
        // Each instruction takes 3-4 clock cycles (Fetch: ~2 cycles, Exec: 1 cycle)
        repeat (50) @(posedge clk);

        // Check RAM[0] was written with 1234
        if (uut.mem.ram.ram[0] !== 16'd1234) begin
            $display("[FAIL] RAM[0] expected 1234, got %0d", uut.mem.ram.ram[0]);
            $finish;
        end else begin
            $display("[PASS] Step 1: RAM[0] successfully written with 1234 (M=D)");
        end

        // Wait for execution to reach PC = 14/15
        repeat (50) @(posedge clk);

        // Check RAM[1] was written with 999
        if (uut.mem.ram.ram[1] !== 16'd999) begin
            $display("[FAIL] RAM[1] expected 999, got %0d", uut.mem.ram.ram[1]);
            $finish;
        end else begin
            $display("[PASS] Step 2: Jump to PC=10 succeeded and RAM[1] written with 999");
        end

        // Check PC is at 14 or 15 (infinite loop)
        if (uut.pc !== 15'd14 && uut.pc !== 15'd15) begin
            $display("[FAIL] Expected PC to be looping at 14/15, got %0d", uut.pc);
            $finish;
        end else begin
            $display("[PASS] Step 3: PC reached end loop at %0d", uut.pc);
        end

        $display("=== ALL COMPUTER FSM TESTS PASSED SUCCESSFULLY! ===");
        $dumpflush;
        $finish;
    end

endmodule
