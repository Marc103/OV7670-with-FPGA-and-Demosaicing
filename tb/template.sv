/*
 * Basically the top module ports with clk added
 * The idea being to drive the relevant input ports and wire them for the DUT 
 * 
 *
 */


// timescale <time_unit>/<time_precision>
`timescale 1ns / 1ps 

module TOP
    (input clk,
     input logic reset_,

     /*
      * HCI Wiring
      */
     input  logic       l_btn_PIN,
     input  logic       r_btn_PIN,
     input  logic       u_btn_PIN,
     input  logic       d_btn_PIN,
     input  logic       c_btn_PIN,
     input  logic [7:0] switches_PIN,
     output logic AN3_PIN,
     output logic AN2_PIN,
     output logic AN1_PIN,
     output logic AN0_PIN,
     output logic CA_PIN,
     output logic CB_PIN,
     output logic CC_PIN,
     output logic CD_PIN,
     output logic CE_PIN,
     output logic CF_PIN,
     output logic CG_PIN,
     output logic DP_PIN,
     
     /*
      * Camera interface (except SIO_C and SIO_D since i2c_master takes care of that)
      */
     output logic MCLK,

     // video timing generator signals
     input  logic STROBE_PIN,
     input  logic HREF_PIN,
     input  logic PCLK_PIN,
     input  logic VSYNC_PIN,
     output logic RST_PIN,
     output logic PWDN_PIN,

     input  logic [7:0] D_PIN,

     /*
      * VGA Port Pins
      */
     output logic [3:0] VGA_R_PIN,
     output logic [3:0] VGA_G_PIN,
     output logic [3:0] VGA_B_PIN,
     output logic VGA_HS_PIN,
     output logic VGA_VS_PIN,

     /*
      * i2c wiring
      */
     inout logic SCL_PIN,
     inout logic SDA_PIN,
     
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
    
    initial begin
        // Write simulation code here 

        
    end
    

    
endmodule