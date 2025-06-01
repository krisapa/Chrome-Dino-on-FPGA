`timescale 1ns / 1ps
`default_nettype none
`include "display640x480.vh"


module vgadisplaydriver #(
    parameter Nchars = 32,
    parameter smem_size = 1200,
    parameter bmem_init = "bitmapmem.mem"
)(
    input wire clk,
    output wire [$clog2(smem_size)-1:0] smem_addr,
    input wire [$clog2(Nchars)-1:0] charcode,
    
    output wire [3:0] red, green, blue,
    output wire hsync, vsync
    );

    wire [`xbits-1:0] x;
    wire [`ybits-1:0] y;
    wire activevideo;

    vgatimer myvgatimer(.*);
    
    wire[$clog2(Nchars*256) - 1 : 0] bmem_addr;
    assign bmem_addr = {charcode, y[3:0], x[3:0]};

    wire[11:0] bmem_color;
    rom_module #(Nchars*256, 12, bmem_init) bitmapmem (
        .addr(bmem_addr),
        .dout(bmem_color)
    );
    
    assign smem_addr = ((y >> 4) << 5) + ((y >> 4) << 3) + (x >> 4);

    assign red = activevideo ? bmem_color[11:8] : 4'b0;
    assign green = activevideo ? bmem_color[7:4] : 4'b0;
    assign blue = activevideo ? bmem_color[3:0] : 4'b0;
    
endmodule
