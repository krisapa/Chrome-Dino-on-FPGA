`timescale 1ns / 1ps
`default_nettype none
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/05/2024 11:07:05 AM
// Design Name: 
// Module Name: ALU
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module ALU #(parameter N=32) (
    input wire [N-1:0] A, B,
    output wire [N-1:0] R,
    input wire [4:0] ALUfn,
//    output wire FlagN, FlagC, FlagV, FlagZ 
    output wire FlagZ
    );
    wire FlagN, FlagC, FlagV;
    wire subtract, bool1, bool0, shft, math;
    assign {subtract, bool1, bool0, shft, math} = ALUfn[4:0];
    
    wire [N-1:0] addSubResult, shiftResult, logicalResult;
    wire compResult;
    
    addsub #N AS(.A, .B, .Subtract(subtract), .Result(addSubResult), .FlagN, .FlagC, .FlagV);
    shifter #N S(.IN(B), .shamt(A[$clog2(N)-1:0]), .left(bool1 == 1'b0), .logical(bool0 == 1'b0), .OUT(shiftResult));
    logical #N L(.A, .B, .op({bool1, bool0}), .R(logicalResult));
    comparator C(.FlagN, .FlagV, .FlagC, .bool0, .comparison(compResult));
    
    assign R = (~shft & math) ? addSubResult :
               (shft & ~math) ? shiftResult :
               (~shft & ~math) ? logicalResult : 
               (shft & math) ? {{(N-1){1'b0}}, compResult} : 0;
    assign FlagZ = ~|R;
    
    
endmodule




