`timescale 1ns / 1ps

module accelerometer(
    input wire clk,     //use 100MHz clock
    
    //Accelerometer signals
    output wire aclSCK,
    output wire aclMOSI,
    input wire aclMISO,
    output wire aclSS,
    
    //Accelerometer data
    output wire [8:0] accelX, accelY,
    output wire [11:0] accelTmp
    );
    
    AccelerometerCtl accel(clk, 0, aclSCK, aclMOSI, aclMISO, aclSS, accelX, accelY, accelTmp);
    
endmodule
