module CPU (
    input  wire        clk,
    input  wire        reset,
    input  wire        enable,
    input  wire [15:0] inM,
    input  wire [15:0] instruction,
    output wire [15:0] outM,
    output wire        writeM,
    output wire [14:0] addressM,
    output wire [14:0] pc
);

    reg [15:0] a_reg = 16'd0;
    reg [15:0] d_reg = 16'd0;
    wire c_inst = instruction[15];
    wire a_inst = ~instruction[15];
    wire [2:0] dest = instruction[5:3];
    wire [15:0] alu_y = instruction[12] ? inM : a_reg;
    wire [15:0] alu_out;
    wire zr, ng;
    wire pos = ~zr & ~ng;
    wire jump = (instruction[2] & ng) | (instruction[1] & zr) |
                (instruction[0] & pos);

    assign outM = alu_out;
    assign writeM = enable & c_inst & dest[0];
    assign addressM = a_reg[14:0];

    PC pc1 (
        .clk(clk),
        .reset(reset),
        .load(enable & c_inst & jump),
        .inc(enable & ~(c_inst & jump)),
        .in(a_reg[14:0]),
        .out(pc)
    );

    HackALU alu1 (
        .x(d_reg), .y(alu_y),
        .zx(instruction[11]),
        .nx(instruction[10]),
        .zy(instruction[9]),
        .ny(instruction[8]),
        .f(instruction[7]),
        .no(instruction[6]),
        .out(alu_out),
        .zr(zr),
        .ng(ng)
    );

    always @(posedge clk) begin
        if (enable) begin
            if (a_inst)
                a_reg <= instruction;
            else if (dest[2])
                a_reg <= alu_out;

            if (c_inst & dest[1])
                d_reg <= alu_out;
        end
    end
endmodule