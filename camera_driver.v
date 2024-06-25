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
    (input clk,
     input reset_,
     output XCLK,
     output RESET#,
     output PWDN,
     output SIO_C,
     inout SIO_D,
     input rx_d,
     output tx_d,
     input STROBE,
     input HREF,
     input PCLK,
     input VSYNC,
     input [7:0] D
     );

    // OE is active on LOW
    reg OE = 0;


    // Tri-state buffer
    // active LOW
    assign SIO_D = OE ? 1'bZ : TX_D;
    assign RX_D = SIO_D;

    always@(posedge CLK)
        begin
            if(~reset_) begin

            end
            else
            



endmodule