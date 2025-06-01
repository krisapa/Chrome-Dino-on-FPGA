`timescale 1ns / 1ps
`default_nettype none

module fulladder(
    input wire A,
    input wire B,
    input wire Cin,
    output wire Sum,
    output wire Cout
    );
    
    wire t1, t2, t3;
    xor x1(t1, A, B);
    xor x2(Sum, Cin, t1);
    and a1(t2, t1, Cin);
    and a2(t3, A, B);
    or o1(Cout, t2, t3);
    
endmodule
