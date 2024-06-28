/*
This is the OV7670 Camera driver module and follows "Figure 2 Functional Block Diagram"
in the OV7670 datasheet. The physical pins on the camera may differ:
SCL  <-> SIO_C
SDA  <-> SIO_D
HS   <-> HREF
VS   <-> VREF
MCLK <-> XCLK

This file will most likely be abandonded in favor of a pre-made i2c block
so that more time can be focused on the debayering logic. But, its good to use as
a way to familiarize better with System verilog.

To be repurposed to usher commands to the i2c pre-made module. 

Final form, the camera driver usher commands to the i2c module, which then communicates to the
SCCB interface. The other i/o from the camera is still connected to this module. 

This module's job is to take in configuration inputs via HCI and set those configurations by
controlling i2c module. The basys3 board has 5 buttons and 16 switches. The simplest HCI would
be set some value via the switches, press a button to set a particular parameter. (we should definitely
debounced the buttons).

Okay, it turns out there is a ridiculous number of device control registers.
- Use the seven seg display to show the currently chosen register address (1 byte -> 2 hex values -> 2 7 seg displays)
- left/right buttons decrement/increment the address by 1
- down/up buttons decrement/increment the address by 16
- 8 switches (1 byte) to set the value
- center button sends command

*/

module OV7670_CAMERA_DRIVER
    (input  logic clk,
     input  logic  reset_,

     /*
      * HCI 
      */
     input  logic       dbncd_l_btn,
     input  logic       dbncd_r_btn,
     input  logic       dbncd_u_btn,
     input  logic       dbncd_d_btn,
     input  logic       dbncd_c_btn,
     input  logic [7:0] switches,
     // todo add seven seg
     
     /*
      * i2c master interface
      */
     output logic [6:0]  s_axis_cmd_address,
     output logic        s_axis_cmd_start,
     output logic        s_axis_cmd_read,
     output logic        s_axis_cmd_write,
     output logic        s_axis_cmd_write_multiple,
     output logic        s_axis_cmd_stop,
     output logic        s_axis_cmd_valid,
     input  logic        s_axis_cmd_ready,

     output logic [7:0]  s_axis_data_tdata,
     output logic        s_axis_data_tvalid,
     input  logic        s_axis_data_tready,
     output logic        s_axis_data_tlast,

     input  logic [7:0]  m_axis_data_tdata,
     input  logic        m_axis_data_tvalid,
     output logic        m_axis_data_tready,
     input  logic        m_axis_data_tlast,

     /*
      * Camera interface (except SIO_C and SIO_D since i2c_master takes care of that)
      */
     output logic XCLK,

     // video timing generator signals
     input  logic STROBE,
     input  logic HREF,
     input  logic PCLK,
     input  logic VSYNC,
     output logic RESET#,
     output logic PWDN,

     input logic [7:0] D
     );

    

    




endmodule