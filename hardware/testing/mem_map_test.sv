`timescale 1ns / 1ps
`default_nettype none

module memIO_test;

  localparam wordsize = 32;

  logic cpu_wr;
  logic [wordsize-1:0] cpu_addr, cpu_writedata;
  wire [wordsize-1:0] cpu_readdata;
  wire lights_wr, sound_wr;
  logic [wordsize-1:0] accel_val, keyb_char;
  wire smem_wr;
  logic [wordsize-1:0] smem_readdata;
  wire dmem_wr;
  logic [wordsize-1:0] dmem_readdata;
    
  memory_mapper #(.wordsize(wordsize)) my_mm(.*);

  initial begin
    cpu_wr = 0; cpu_addr = 32'b 0; cpu_writedata = 32'h 1111_1111;
    accel_val = 32'h 2222_2222; keyb_char = 32'h 3333_3333;
    smem_readdata = 32'h 4444_4444; dmem_readdata = 32'h 5555_5555;
    
    // read data memory
    #1 dmem_readdata = 32'h 1234_5678;
    cpu_addr = 32'h 1001_0000;                 // 0th location in data memory
    #1 dmem_readdata = 32'h 5678_1234;
    cpu_addr = 32'h 1001_0ffc;                 // 1023rd (highest) location in data memory
    #1 dmem_readdata = 32'h 5555_5555;
    
    // write data memory
    #1 cpu_wr = 1;
    #1 cpu_addr = 32'h 1001_0000;              // 0th location in data memory
    #1 cpu_addr = 32'h 1001_0ffc;              // 1023rd (highest) location in data memory
    #1 cpu_wr = 0;

    // read screen memory
    #1 smem_readdata = 32'h abcd_1234;
    cpu_addr = 32'h 1002_0000;                 // 0th location in screen memory
    #1 smem_readdata = 32'h 1234_abcd;
    cpu_addr = 32'h 1002_12bc;                 // 1199th (highest) location in screen memory
    #1 smem_readdata = 32'h 4444_4444;
    
    // write screen memory
    #1 cpu_wr = 1;
    #1 cpu_addr = 32'h 1002_0000;              // 0th location in screen memory
    #1 cpu_addr = 32'h 1002_12bc;              // 1199th (highest) location in screen memory
    #1 cpu_wr = 0;

    // read keyboard
    #1 keyb_char = 32'h 2468_1234;
    cpu_addr = 32'h 1003_0000;                 // keyboard address
    #1 keyb_char = 32'h 3333_3333;
    
    // read accelerometer
    #1 accel_val = 32'h 1357_2468;
    cpu_addr = 32'h 1003_0004;                 // accelerometer address
    #1 accel_val = 32'h 2222_2222;
    
    // write sound register
    #1 cpu_wr = 1;
    #1 cpu_addr = 32'h 1003_0008;              // sound register address
    #1 cpu_wr = 0;

    // write LED register
    #1 cpu_wr = 1;
    #1 cpu_addr = 32'h 1003_000C;              // LED register address
    #1 cpu_wr = 0;
    
    #5 $finish;
  end


  selfcheck_memIO c();
  
  wire [wordsize-1:0] c_cpu_readdata = c.cpu_readdata;
  wire c_lights_wr = c.lights_wr;
  wire c_sound_wr = c.sound_wr;
  wire c_smem_wr = c.smem_wr;
  wire c_dmem_wr = c.dmem_wr;

  function mismatch;  // some trickery needed to match two values with don't cares
    input p, q;      // mismatch in a bit position is ignored if q has an 'x' in that bit
    integer p, q;
    mismatch = (((p ^ q) ^ q) !== q) ? 1'bx : 1'b0;
  endfunction

  wire ERROR;
  wire ERROR_cpu_readdata = mismatch(cpu_readdata, c.cpu_readdata);
  wire ERROR_lights_wr = mismatch(lights_wr, c.lights_wr);
  wire ERROR_sound_wr = mismatch(sound_wr, c.sound_wr);
  wire ERROR_smem_wr = mismatch(smem_wr, c.smem_wr);
  wire ERROR_dmem_wr = mismatch(dmem_wr, c.dmem_wr);
  
  assign ERROR = ERROR_cpu_readdata | ERROR_lights_wr | ERROR_sound_wr | ERROR_smem_wr | ERROR_dmem_wr;

  initial begin
    $monitor("#%02d {cpu_readdata, lights_wr, sound_wr, smem_wr, dmem_wr} <= {32'h%h, 1'b%b, 1'b%b, 1'b%b, 1'b%b};",
              $time, cpu_readdata, lights_wr, sound_wr, smem_wr, dmem_wr);
        
  end
endmodule



// CHECKER MODULE

module selfcheck_memIO();
  logic [31:0] cpu_readdata;
  logic lights_wr, sound_wr, smem_wr, dmem_wr;
  
  initial begin
  fork

#00 {cpu_readdata, lights_wr, sound_wr, smem_wr, dmem_wr} <= {32'hxxxxxxxx, 1'b0, 1'b0, 1'b0, 1'b0};
#01 {cpu_readdata, lights_wr, sound_wr, smem_wr, dmem_wr} <= {32'h12345678, 1'b0, 1'b0, 1'b0, 1'b0};
#02 {cpu_readdata, lights_wr, sound_wr, smem_wr, dmem_wr} <= {32'h56781234, 1'b0, 1'b0, 1'b0, 1'b0};
#03 {cpu_readdata, lights_wr, sound_wr, smem_wr, dmem_wr} <= {32'h55555555, 1'b0, 1'b0, 1'b0, 1'b0};
#04 {cpu_readdata, lights_wr, sound_wr, smem_wr, dmem_wr} <= {32'h55555555, 1'b0, 1'b0, 1'b0, 1'b1};
#07 {cpu_readdata, lights_wr, sound_wr, smem_wr, dmem_wr} <= {32'h55555555, 1'b0, 1'b0, 1'b0, 1'b0};
#08 {cpu_readdata, lights_wr, sound_wr, smem_wr, dmem_wr} <= {32'habcd1234, 1'b0, 1'b0, 1'b0, 1'b0};
#09 {cpu_readdata, lights_wr, sound_wr, smem_wr, dmem_wr} <= {32'h1234abcd, 1'b0, 1'b0, 1'b0, 1'b0};
#10 {cpu_readdata, lights_wr, sound_wr, smem_wr, dmem_wr} <= {32'h44444444, 1'b0, 1'b0, 1'b0, 1'b0};
#11 {cpu_readdata, lights_wr, sound_wr, smem_wr, dmem_wr} <= {32'h44444444, 1'b0, 1'b0, 1'b1, 1'b0};
#14 {cpu_readdata, lights_wr, sound_wr, smem_wr, dmem_wr} <= {32'h44444444, 1'b0, 1'b0, 1'b0, 1'b0};
#15 {cpu_readdata, lights_wr, sound_wr, smem_wr, dmem_wr} <= {32'h24681234, 1'b0, 1'b0, 1'b0, 1'b0};
#16 {cpu_readdata, lights_wr, sound_wr, smem_wr, dmem_wr} <= {32'h33333333, 1'b0, 1'b0, 1'b0, 1'b0};
#17 {cpu_readdata, lights_wr, sound_wr, smem_wr, dmem_wr} <= {32'h13572468, 1'b0, 1'b0, 1'b0, 1'b0};
#18 {cpu_readdata, lights_wr, sound_wr, smem_wr, dmem_wr} <= {32'h22222222, 1'b0, 1'b0, 1'b0, 1'b0};
#20 {cpu_readdata, lights_wr, sound_wr, smem_wr, dmem_wr} <= {32'hxxxxxxxx, 1'b0, 1'b1, 1'b0, 1'b0};
#21 {cpu_readdata, lights_wr, sound_wr, smem_wr, dmem_wr} <= {32'hxxxxxxxx, 1'b0, 1'b0, 1'b0, 1'b0};
#22 {cpu_readdata, lights_wr, sound_wr, smem_wr, dmem_wr} <= {32'hxxxxxxxx, 1'b0, 1'b1, 1'b0, 1'b0};
#23 {cpu_readdata, lights_wr, sound_wr, smem_wr, dmem_wr} <= {32'hxxxxxxxx, 1'b1, 1'b0, 1'b0, 1'b0};
#24 {cpu_readdata, lights_wr, sound_wr, smem_wr, dmem_wr} <= {32'hxxxxxxxx, 1'b0, 1'b0, 1'b0, 1'b0};

  join
  end

endmodule
