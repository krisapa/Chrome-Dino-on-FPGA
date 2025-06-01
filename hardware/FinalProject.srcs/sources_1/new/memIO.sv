`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/04/2024 12:25:23 PM
// Design Name: 
// Module Name: memIO
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


module memIO #(
    parameter wordsize = 32,
    parameter dmem_size = 1024,
    parameter dmem_init = "dmem_test.mem",
    parameter Nchars = 64,
    parameter smem_size = 1200,
    parameter smem_init = "smem_test.mem"
)(
    input wire clk, cpu_wr, 

    input wire [wordsize-1:0] cpu_addr, cpu_writedata, 
    output wire [wordsize-1:0] cpu_readdata,

    input wire [$clog2(smem_size)-1:0] vga_addr,
    output wire [$clog2(Nchars)-1:0] vga_readdata,

    input wire [wordsize-1:0] keyb_char, accel_val,
    output wire [wordsize-1:0] period,
    output wire [15:0] lights,
    input wire [wordsize-1:0] millisecond_time
    );
    
    wire[wordsize-1:2] cpu_addr_short = cpu_addr[wordsize-1:2];

    wire lights_wr, sound_wr, smem_wr, dmem_wr;

    wire [wordsize-1:0] smem_readdata, dmem_readdata;

    memory_mapper #(.wordsize(wordsize)) my_mm(.*);

    wire [$clog2(Nchars)-1:0] cpu_charcode;

    ram2port_module #(.Nloc(smem_size), .Dbits($clog2(Nchars)), .initfile(smem_init)) screenmem(
        .clock(clk),
        .wr(smem_wr),
        .addr1(cpu_addr_short),
        .addr2(vga_addr),
        .din(cpu_writedata),
        .dout1(cpu_charcode),
        .dout2(vga_readdata)
    );

    assign smem_readdata = {32'b0, cpu_charcode};

    ram_module #(.Nloc(dmem_size), .Dbits(wordsize), .initfile(dmem_init)) datamem(
        .clock(clk),
        .wr(dmem_wr),
        .addr(cpu_addr_short),
        .din(cpu_writedata),
        .dout(dmem_readdata)
    );

    logic [15:0] ledReg = '0;
    always_ff @(posedge clk) begin
        if (lights_wr)
            ledReg <= cpu_writedata;
    end
    assign lights = ledReg;

    logic [wordsize-1:0] soundReg = '0;
    always_ff @(posedge clk) begin
        if (sound_wr)
            soundReg <= cpu_writedata;
    end
    assign period = soundReg;


endmodule
