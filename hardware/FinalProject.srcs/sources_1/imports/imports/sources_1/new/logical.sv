`timescale 1ns / 1ps
`default_nettype none
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/05/2024 10:43:18 AM
// Design Name: 
// Module Name: logical
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


module logical #(parameter N =32) (
    input wire [N-1:0] A, B,
    input wire [1:0] op,
    output wire [N-1: 0] R 
    );
    
    assign R = (op == 2'b00) ? A & B :
               (op == 2'b01) ? A | B :
               (op == 2'b10) ? A ^ B :
               (op == 2'b11) ? ~(A | B) : 2'bxx ;
            
endmodule
