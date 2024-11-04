/*
 * driving clock to test qvga syn and address signals
 *
 */


// timescale <time_unit>/<time_precision>
`timescale 1ns / 1ps 

module TESTBENCH_FRAME ();
    
    logic clk;

    initial begin
        clk = 0; 
        forever 
            begin
                #1 clk = ~clk;
            end 
    end
    
    logic d_hsync;
    logic d_vsync;
    logic [$clog2(640 * 480):0] d_r_addr;
    logic [$clog2(640):0] d_pixel_x;
    logic [$clog2(480):0] d_pixel_y;
    
    VGA_PARAM dut (.pclk(clk),
                   .hsync(d_hsync),
                   .vsync(d_vsync),
                   .r_addr(d_r_addr),
                   .pixel_x(d_pixel_x),
                   .pixel_y(d_pixel_y));
    
    initial begin
        // Write simulation code here 
        //$dumpfile("dump.vcd");
        //$dumpvars();

        
    end  
endmodule