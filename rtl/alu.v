module ALU (
    input wire [15:0] x,
    input wire [15:0] y,
    input wire zx,
    input wire nx,
    input wire zy,
    input wire ny,
    input wire f,
    input wire no,
    output wire [15:0] out,
    output wire zr,
    output wire ng
);

  wire [15:0] x1, y1, x2, y2, out1, out2;
  
  // z[x/y] zero
  assign x1 = zx ? 16'b0 : x;
  assign y1 = zy ? 16'b0 : y;

  // n[x/y] negate
  assign x2 = nx ? ~x1 : x1;
  assign y2 = ny ? ~y1 : y1;
  
  // f: add
  assign out1 = f ? x2 + y2 : x2 & y2;
  
  // no: not
  assign out = no ? ~out1 : out1;
  
 // post-computer flags:

  // zr: is zero
  assign zr = ~|out; 
  
  // ng: is negative
  assign ng = out[15]; 
  
endmodule