/*
 * 
 * 
 *
 */


// timescale <time_unit>/<time_precision>
`timescale 1ns / 1ps 

module TESTBENCH_FRAME
    (//input clk,
     
     
    
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
    
    
    logic clk;

    initial begin
        clk = 0; 
        forever 
            begin
                #10 clk = ~clk;
            end 
    end
    
    
    
    
    
    
    logic w_clk_100MHz_to_6_25MHz;
    logic w_clk_100MHz_to_25MHz;

    
    

    CLK_DIV #(.div_by_x2(8)) clk_x2_8(.clk(clk), .o_clk(w_clk_100MHz_to_6_25MHz));
    CLK_DIV #(.div_by_x2(2)) clk_x2_4(.clk(clk), .o_clk(w_clk_100MHz_to_25MHz));

    /*
    QVGA Qvga_dut (.pclk(w_clk_100MHz_to_6_25_MHz),
                   .hsync(VGA_HS_PIN),
                   .vsync(VGA_VS_PIN),
                   .d_r_addr(w_r_addr));
    */
    

    
    logic                      w_Wr_Clk = 0;
    logic [$clog2(307200)-1:0]  w_Wr_Addr = 0;
    logic                      w_Wr_DV = 0;
    logic [11:0]               w_Wr_Data = 0;

    logic                      w_Rd_Clk;
    logic [$clog2(307200)-1:0] w_Rd_Addr;
    logic                      w_Rd_En;
    logic                      w_Rd_DV;
    logic [11:0] w_Rd_Data;
    
    logic [$clog2(307200)-3:0] w_Rd_Addr_shifted;
    
    assign w_Rd_Addr_shifted = w_Rd_Addr[$clog2(307200)-1:2];
    

    RAM_2Port #(.WIDTH(12), .DEPTH(76800)) Vbuff
               (.i_Wr_Clk(w_Wr_Clk),
                .i_Wr_Addr(w_Wr_Addr),
                .i_Wr_DV(w_Wr_DV),
                .i_Wr_Data(w_Wr_Data),
                
                .i_Rd_Clk(w_Rd_Clk),
                .i_Rd_Addr(w_Rd_Addr_shifted),
                .i_Rd_En(w_Rd_En),
                .o_Rd_DV(w_Rd_DV),
                .o_Rd_Data(w_Rd_Data));
    
        
    VGA_PARAM vga ( .pclk(w_clk_100MHz_to_25MHz),
                    .r_data(w_Rd_Data),
                    .r_dv(w_Rd_DV),

                    .r_clk(w_Rd_Clk), 
                    .r_addr(w_Rd_Addr),
                    .r_en(w_Rd_En),
                    
                    .red_bits(VGA_R_PIN),
                    .green_bits(VGA_G_PIN),
                    .blue_bits(VGA_B_PIN),
                    
                    .hsync(VGA_HS_PIN),
                    .vsync(VGA_VS_PIN));
    
    


    
    

    
endmodule