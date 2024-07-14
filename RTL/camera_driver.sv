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

     input  logic        busy,
     input  logic        bus_control,
     input  logic        bus_active,
     input  logic        missed_ack,

     output logic [15:0] prescale;
     output logic        stop_on_idle;

     /*
      * Camera interface (except SIO_C and SIO_D since i2c_master takes care of that)
      */
     output logic XCLK,

     // video timing generator signals
     input  logic STROBE,
     input  logic HREF,
     input  logic PCLK,
     input  logic VSYNC,
     output logic RESET_,
     output logic PWDN,

     input logic [7:0] D
     );

    /* 
     * I2C (output) state
     * 0x42 for read, 0x43 for write
     * meaning, address looks like 1000 001 | W/R
     */
    logic [6:0]  s_s_axis_cmd_address        = 7'b1000001;
    logic        s_s_axis_cmd_start          = 1'b0;
    logic        s_s_axis_cmd_read           = 1'b0;
    logic        s_s_axis_cmd_write          = 1'b0;
    logic        s_s_axis_cmd_write_multiple = 1'b0;
    logic        s_s_axis_cmd_stop           = 1'b1;
    logic        s_s_axis_cmd_valid          = 1'b0;
    logic        s_s_axus_cmd_ready          = 1'b0;

    logic [7:0]  s_s_axis_data_tdata         = 1'h00;
    logic        s_s_axis_data_tvalid;       = 1'b0;
    logic        s_s_axis_data_tlast         = 1'b0;

    logic        s_m_axis_data_tready        = 1'b0;

    // 100 MHz / 400Khz * 4 = 62.5 so 63
    logic [15:0] s_prescale                  = 16'h003F;
    logic        s_stop_on_idle              = 1'b1;           

    assign s_axis_cmd_address        = s_s_axis_cmd_address;
    assign s_axis_cmd_start          = s_s_axis_cmd_start;
    assign s_axis_cmd_read           = s_s_axis_cmd_read;
    assign s_axis_cmd_write          = s_s_axis_cmd_write;
    assign s_axis_cmd_write_multiple = s_s_axis_cmd_write_multiple;
    assign s_axis_cmd_stop           = s_s_axis_cmd_stop;
    assign s_axis_cmd_valid          = s_s_axis_cmd_valid;

    assign s_axis_data_tdata         = s_s_axis_data_tdata;
    assign s_axis_data_tvalid        = s_s_axis_data_tvalid;
    assign s_axis_data_tlast         = s_s_axis_data_tlast;

    assign m_axis_data_tready        = s_m_axis_data_tready;

    assign prescale                  = s_prescale;
    assign stop_on_idle              = s_stop_on_idle;



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
            
            if((state_c_btn == 1'b1 && dbncd_c_btn == 1'b0))
                begin
                    // Center button pressed, send command
                    state_c_btn <= 1'b0;

                    s_s_axis_cmd_start <= 1'b1;
                    s_s_axis_cmd_write <= 1'b1;
                    s_s_axis_cmd_valid <= 1'b1;
                    s_s_axis_cmd_ready <= 1'b1;
                    s_s_axis_data_tdata <= binary_num;
                    s_s_axis_data_tvalid <= 1'b1;


                end
            else
                begin
                    s_s_axis_cmd_start <= 1'b0;
                    state_c_btn <= dbncd_l_btn;
                end

        end

    

    




endmodule