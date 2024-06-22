/*
This is the OV7670 Camera driver module and follows "Figure 2 Functional Block Diagram"
in the OV7670 datasheet. The physical pins on the camera may differ:
SCL  <-> SIO_C
SDA  <-> SIO_D
HS   <-> HREF
VS   <-> VREF
MCLK <-> XCLK
*/

module OV7670_CAMERA_DRIVER
    (output XCLK,
     output RESET#,
     output PWDN,
     output SIO_C,
     output SIO_D,
     input STROBE,
     input HREF,
     input PCLK,
     input VSYNC,
     input [7:0] D
     );

endmodule