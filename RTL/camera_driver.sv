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

Probably should add a way to read and display a value stored at a register.

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
     output logic [7:0] binary_num,
     // todo add seven seg

     /*
      * i2c host interface
      */
     output logic       o_usher,
     output logic [7:0] o_address,
     output logic [7:0] o_subaddress,
     output logic [7:0] o_data,
     output logic [1:0] o_mode,

     input  logic       i_busy,
     input  logic [7:0] i_data

     );

    /* 
     * I2C (output) state
     * 0x42 for read, 0x43 for write
     * meaning, address looks like 1000 001 | W/R
     */
    
    // i2c, as of now, just writes will happen
    logic       r_usher;
    logic [7:0] r_address;
    logic [7:0] r_subaddress;
    logic [7:0] r_data;
    logic [1:0] r_mode;

    // HCI State
    logic state_l_btn;
    logic state_r_btn;
    logic state_u_btn;
    logic state_d_btn;
    logic state_c_btn;

    logic [7:0] state_binary_num = 8'h23;

    assign binary_num = state_binary_num;


    always@(posedge clk)
        begin
            if((state_l_btn == 1'b1) && (dbncd_l_btn == 1'b0))
                begin
                    // Left button pressed, -1
                    state_binary_num <= state_binary_num - 1;
                    state_l_btn <= 1'b0;
                end
            else
                begin
                    state_l_btn <= dbncd_l_btn;
                end
            
            if((state_r_btn == 1'b1) && (dbncd_r_btn == 1'b0))
                begin
                    // Right button pressed, +1
                    state_binary_num <= state_binary_num + 1;
                    state_r_btn <= 1'b0;
                end
            else
                begin
                    state_r_btn <= dbncd_r_btn;
                end

            if((state_u_btn == 1'b1) && (dbncd_u_btn == 1'b0))
                begin
                    // Up button pressed, +16
                    state_binary_num <= state_binary_num + 16;
                    state_u_btn <= 1'b0;
                end
            else
                begin
                    state_u_btn <= dbncd_u_btn;
                end

            if((state_d_btn == 1'b1) && (dbncd_d_btn == 1'b0))
                begin
                    // Down button pressed, -16
                    state_binary_num <= state_binary_num - 16;
                    state_d_btn <= 1'b0;
                end
            else
                begin
                    state_d_btn <= dbncd_d_btn;
                end
            
            if((state_c_btn == 1'b1) && (dbncd_c_btn == 1'b0))
                begin
                    // Center button pressed, send command
                    state_c_btn <= 1'b0;
                    
                    if(!i_busy)
                        r_usher <= 1'b1;
                    else
                        r_usher <= 1'b0;   
                            
                end
            else
                begin
                    state_c_btn  <= dbncd_c_btn;
                    r_usher      <= 1'b0;
                end
            
            r_address    <= 8'h42;
            r_subaddress <= binary_num;
            r_data       <= switches;
            r_mode       <= 1'b00;

        end

    assign o_usher = r_usher;
    assign o_address = r_address;
    assign o_subaddress = r_subaddress;
    assign o_data = r_data;
    assign o_mode = r_mode;

endmodule