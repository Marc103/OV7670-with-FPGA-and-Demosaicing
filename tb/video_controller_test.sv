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
                #10 clk = ~clk;
            end 
    end
    
    logic d_hsync;
    logic d_vsync;
    logic [16:0] d_r_addr;
    
    QVGA qvga_dut (.pclk(clk),
                   .hsync(d_hsync),
                   .vsync(d_vsync),
                   .d_r_addr(d_r_addr));
    
    initial begin
        // Write simulation code here 
        //$dumpfile("dump.vcd");
        //$dumpvars();

        
    end
    

    
endmodule