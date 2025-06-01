`timescale 1ns / 1ps 
`default_nettype none

//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/04/2024 03:27:33 PM
// Design Name: 
// Module Name: memory_mapper
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


module memory_mapper #(
    parameter wordsize = 32
)(
    input wire cpu_wr,
    input wire [wordsize-1:0] cpu_addr,
    output wire [wordsize-1:0] cpu_readdata,
    output wire lights_wr,
    sound_wr,
    smem_wr,
    dmem_wr,
    input wire [wordsize-1:0] accel_val,
    keyb_char,
    smem_readdata,
    dmem_readdata,
    millisecond_time
);
    assign lights_wr = cpu_wr && (cpu_addr[17:16] == 2'b11) && (cpu_addr[3:2] == 2'b11);
    assign sound_wr = cpu_wr && (cpu_addr[17:16] == 2'b11) && (cpu_addr[3:2] == 2'b10);
    assign smem_wr = cpu_wr && (cpu_addr[17:16] == 2'b10);
    assign dmem_wr = cpu_wr && (cpu_addr[17:16] == 2'b01);

    assign cpu_readdata = (cpu_addr[17:16] == 2'b11) && (cpu_addr[4:2] == 3'b111) ? millisecond_time :
                        (cpu_addr[17:16] == 2'b11) && (cpu_addr[3:2] == 2'b01) ? accel_val :
                        (cpu_addr[17:16] == 2'b11) && (cpu_addr[3:2] == 2'b00) ? keyb_char :
                        (cpu_addr[17:16] == 2'b10) ? smem_readdata : 
                        (cpu_addr[17:16] == 2'b01) ? dmem_readdata :
                        {wordsize{'x}};

endmodule
