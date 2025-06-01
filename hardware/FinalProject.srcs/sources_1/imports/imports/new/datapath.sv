`timescale 1ns / 1ps
`default_nettype none


module datapath #(
    parameter Nreg = 32,
    parameter Dbits = 32
 )(
    input wire clk, reset, enable, sgnext, bsel, werf,
    output logic [31:0] pc = 32'h 0040_0000,
    input wire [31:0] instr,
    input wire [1:0] pcsel, wasel, wdsel, asel, 
    input wire [4:0] alufn, 
    output wire Z,
    output wire [31:0] mem_addr, mem_writedata, mem_readdata
    );

    wire [31:0] ReadData1, ReadData2, alu_result;
    assign mem_addr = alu_result;
    assign mem_writedata = ReadData2;

    wire [31:0] pcPlus4 = pc + 4;

    wire [31:0] reg_writedata = wdsel == 2'b00 ? pcPlus4
                : wdsel == 2'b01 ? alu_result 
                : wdsel == 2'b10 ? mem_readdata
                : 32'b x;
    
    wire [31:0] reg_writeaddr = wasel == 2'b00 ? instr[15:11]
                : wasel == 2'b01 ? instr[20:16]
                : wasel == 2'b10 ? 32'd 31
                : 32'b x;


    wire [15:0] imm = instr[15:0];
    wire [31:0] signImm = sgnext ? {{16{imm[15]}}, imm} : {{16{1'b0}}, imm};

    wire [31:0] aluA = asel == 2'b00 ? ReadData1 
                : asel == 2'b01 ? instr[10:6] 
                : asel == 2'b10 ? 32'd 16 :
                32'b x;
    
    wire [31:0] aluB = bsel == 1'b0 ? ReadData2 
                : bsel == 1'b1 ? signImm 
                : 32'b x;

    always_ff @(posedge clk) begin
        if (reset) 
            pc <= 32'h 0040_0000;
        else if (enable)
            case (pcsel)
                2'b00: pc <= pcPlus4;
                2'b01: pc <= ({signImm, 2'b00} + pcPlus4);
                2'b10: pc <= {pc[31:28], instr[25:0], 2'b00};
                2'b11: pc <= ReadData1;
                default: pc <= 32'b x;
            endcase
        end


    register_file rf(
        .clock(clk),
        .wr(werf),
        .ReadAddr1(instr[25:21]),
        .ReadAddr2(instr[20:16]),
        .WriteAddr(reg_writeaddr),
        .WriteData(reg_writedata),
        .ReadData1(ReadData1),
        .ReadData2(ReadData2)
    );


    ALU alu(
        .A(aluA),
        .B(aluB),
        .ALUfn(alufn),
        .R(alu_result),
        .FlagZ(Z)
    );
    
endmodule
