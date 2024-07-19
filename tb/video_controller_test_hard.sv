/*
 * 
 * 
 *
 */


// timescale <time_unit>/<time_precision>
`timescale 1ns / 1ps 

module TESTBENCH_FRAME
    (input clk,
     
     
    
     output logic [3:0] VGA_R_PIN,
     output logic [3:0] VGA_G_PIN,
     output logic [3:0] VGA_B_PIN,
     output logic VGA_HS_PIN,
     output logic VGA_VS_PIN,
     
     /*
      * Debug LEDS
      */
      output logic [15:0] LED
      
    );
    
    /*
    logic clk;

    initial begin
        clk = 0; 
        forever 
            begin
                #10 clk = ~clk;
            end 
    end
    */
    
    logic w_clk_100MHz_to_6_25_MHz;
    logic w_clk_100MHz_to_25MHz;
    
    logic [18:0] w_r_addr;
    logic [3:0] r_red;
    logic [3:0] r_green;
    logic [3:0] r_blue;

    
    

    CLK_DIV #(.div_by_x2(8)) clk_x2_8(.clk(clk), .o_clk(w_clk_100MHz_to_6_25_MHz));
    CLK_DIV #(.div_by_x2(2)) clk_x2_4(.clk(clk), .o_clk(w_clk_100MHz_to_25MHz));

    /*
    QVGA Qvga_dut (.pclk(w_clk_100MHz_to_6_25_MHz),
                   .hsync(VGA_HS_PIN),
                   .vsync(VGA_VS_PIN),
                   .d_r_addr(w_r_addr));
    */
    logic [3:0] w_r_bits;
    logic [3:0] w_g_bits;
    logic [3:0] w_b_bits;
        
    VGA Vga_dut (.pclk(w_clk_100MHz_to_25MHz),
                   .hsync(VGA_HS_PIN),
                   .vsync(VGA_VS_PIN),
                   .d_r_addr(w_r_addr),
                   .red_bits(w_r_bits),
                   .green_bits(w_g_bits),
                   .blue_bits(w_b_bits));
    
    assign VGA_R_PIN = w_r_bits;
    assign VGA_G_PIN = w_g_bits;
    assign VGA_B_PIN = w_b_bits;


    
    

    
endmodule