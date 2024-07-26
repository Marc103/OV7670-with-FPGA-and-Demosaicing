// timescale <time_unit>/<time_precision>
`timescale 1ns / 1ps 

module TESTBENCH_FRAME
    ();
    
    
    logic clk;
    initial begin
        clk = 0; 
        forever 
            begin
                #10 clk = ~clk;
            end 
    end
    
    logic       w_hsync;
    logic       w_vsync;
    logic       w_href;
    logic [7:0] w_D;

    OV7670_SIM ov (.pclk(clk),
                   .hsync(w_hsync),
                   .vsync(w_vsync),
                   .href(w_href),
                   .D(w_D));

    
    logic [15:0]                  w_rgb;
    logic                         w_DV;
    logic [$clog2(640 * 480)-1:0] w_addr;
    logic  [$clog2(640)-1:0] w_pixel_x;
    logic  [$clog2(480)-1:0] w_pixel_y;


    RGB_GENERIC rgb (.D(w_D),
                     .HREF(w_href),
                     .VSYNC(w_vsync),
                     .PCLK(clk),
                     .o_RGB_generic(w_rgb),
                     .DV(w_DV),
                     .w_addr(w_addr),
                     .pixel_x(w_pixel_x),
                     .pixel_y(w_pixel_y));
    

    
endmodule