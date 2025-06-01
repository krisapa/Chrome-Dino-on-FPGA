`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/01/2024 11:59:46 PM
// Design Name: 
// Module Name: timer
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


module timer #(
    parameter wordsize=32
)(
    input wire clk12,
    output wire [wordsize-1:0] millisecond_time
    );
    logic [14:0] clk_count = '0;
    logic [wordsize-1:0] millisec_logic = '0;
    always_ff @(posedge clk12) begin
        if (clk_count == 12499) begin
            clk_count <= 0;
            millisec_logic <= millisec_logic + 1;
        end else begin
            clk_count <= clk_count + 1;
        end
   end
   
   assign millisecond_time = millisec_logic;
   
endmodule
