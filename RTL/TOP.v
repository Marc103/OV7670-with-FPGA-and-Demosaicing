/*
 * Top module wiring
 * *_PIN is what the naming will be in the constraints file of
 * the physical wire / pin
 *
 */

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


     /*
      * Camera interface (except SIO_C and SIO_D since i2c_master takes care of that)
      */
     output logic XCLK,

     // video timing generator signals
     input  logic STROBE_PIN,
     input  logic HREF_PIN,
     input  logic PCLK_PIN,
     input  logic VSYNC_PIN,
     output logic RESET#_PIN,
     output logic PWDN_PIN,

     input  logic [7:0] D_PIN,

     /*
      * i2c wiring
      */
    inout logic scl_PIN,
    inout logic sda_PIN,

     );
     
endmodule