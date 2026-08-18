
module tb_cpu;
    reg clk = 0;
    reg reset = 0;
    reg [15:0] inM = 0;
    reg [15:0] instruction = 0;

    wire [15:0] outM;
    wire writeM;
    wire [14:0] addressM;
    wire [14:0] pc;

    // Unit Under Test
    CPU uut (
        .clk(clk),
        .reset(reset),
        .enable(1'b1),
        .inM(inM),
        .instruction(instruction),
        .outM(outM),
        .writeM(writeM),
        .addressM(addressM),
        .pc(pc)
    );

    integer file, status, i;
    integer vectors_tested = 0;
    integer is_setup;

    reg [8*120:1] line_buf;
    reg [8*10:1]  time_str;
    reg [8*16:1]  outM_str;
    integer exp_writeM, exp_addr, exp_pc, exp_outM;

    initial begin
        file = $fopen("cmp/CPU.cmp", "r");
        if (!file) begin
            $display("[ERROR] Could not open CPU.cmp");
            $finish;
        end

        $display("=== STARTING CPU VERIFICATION WITH DEBUG LOGGING ===");

        while ($fgets(line_buf, file)) begin
            // 1. Detect setup phase lines (containing '+')
            is_setup = 0;
            for (i = 1; i <= 120; i = i + 1) begin
                if (line_buf[i*8 -: 8] == "+") is_setup = 1;
            end

            // 2. Replace '|' delimiters with spaces in memory
            for (i = 1; i <= 120; i = i + 1) begin
                if (line_buf[i*8 -: 8] == "|") line_buf[i*8 -: 8] = " ";
            end

            // 3. Parse standard columns
            status = $sscanf(line_buf, "%s %d %b %d %s %d %d %d",
                             time_str, inM, instruction, reset,
                             outM_str, exp_writeM, exp_addr, exp_pc);

            if (status == 8) begin
                if (is_setup) begin
                    // Phase 1 (e.g. 0+): Apply inputs while clock is LOW
                    clk = 0;
                    #1; // Combinational settling delay

                    $display("[SETUP t=%-4s] Applied -> inM=%-5d inst=%b reset=%b",
                             time_str, $signed(inM), instruction, reset);
                end else begin
                    // Phase 2 (e.g. 1): Pulse clock HIGH and verify sequential state
                    vectors_tested = vectors_tested + 1;
                    clk = 1;
                    #5; // Hold clock high

                    $display("[CHECK t=%-4s] GOT [pc=%-4d addr=%-5d wM=%b outM=%-5d] | EXP [pc=%-4d addr=%-5d wM=%b outM=%-5s]",
                             time_str, pc, addressM, writeM, $signed(outM),
                             exp_pc[14:0], exp_addr[14:0], exp_writeM[0], outM_str);

                    // Verify PC, AddressM, WriteM
                    if (pc != exp_pc[14:0] || addressM != exp_addr[14:0] || writeM != exp_writeM[0]) begin
                        $display("[FAIL  t=%-4s] Mismatch detected in control/address signals!", time_str);
                        $finish;
                    end

                    // Verify outM if non-wildcard
                    if ($sscanf(outM_str, "%d", exp_outM) == 1 && exp_outM != -99999) begin
                        if (outM != exp_outM[15:0]) begin
                            $display("[FAIL  t=%-4s] Mismatch detected in outM signal!", time_str);
                            $finish;
                        end
                    end

                    // Return clock LOW
                    clk = 0;
                    #4;
                end
            end
        end

        $fclose(file);

        if (vectors_tested == 0) begin
            $display("[ERROR] 0 vectors evaluated! Check file path/content.");
        end else begin
            $display("=== SUCCESS: Passed all %0d CPU test cycles! ===", vectors_tested);
        end
        $finish;
    end
endmodule