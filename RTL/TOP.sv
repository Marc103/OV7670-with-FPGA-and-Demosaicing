/*
 * Top module wiring
 * *_PIN is what the naming will be in the constraints file of
 * the physical wire / pin
 *
 */

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
     output logic [3:0] VGA_B_PIN,
     output logic [3:0] VGA_G_PIN,
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
    
    assign PWDN_PIN = 1'b0;
    assign RST_PIN = 1'b1;
    assign LED[15] = VSYNC_PIN;
    assign LED[14:0] = 0;
    
    //logic clk = 0;
    //initial 
    //    begin
    //        clk = 0; 
    //        forever 
    //           begin
    //            #10 clk = ~clk;
    //            end 
    //     end
    
    /*
     * Clock wiring, to produce 25 MHz clock and 400 KHz (max 400Khz for i2c)
     * from 100 MHz
     */
     logic w_clk_100MHz_to_25MHz;
     logic w_clk_100Mhz_to_400KHz;

    // 100MHz/25MHz = 4, so we use 4/2 = 2
    CLK_DIV #(.div_by_x2(2)) clk_x2_2 (.clk(clk), .o_clk(w_clk_100MHz_to_25MHz));
    assign MCLK = w_clk_100MHz_to_25MHz;
    // 100MHz/400Khz = 250, so we use 250/2 = 125
    CLK_DIV #(.div_by_x2(125)) clk_x2_125 (.clk(clk), .o_clk(w_clk_100Mhz_to_400KHz));

    /*
     * RGB deserializer wiring (and VGA port wiring)
     */
    logic [11:0] w_rgb_444;
    RGB_444 Rgb_444 (.D(D_PIN),
                     .HREF(HREF_PIN),
                     .PCLK(PCLK_PIN),
                     .o_RGB_444(w_rgb_444));

    assign VGA_R_PIN  = w_rgb_444[11:8];
    assign VGA_G_PIN  = w_rgb_444[7:4];
    assign VGA_B_PIN  = w_rgb_444[3:0];
    assign VGA_HS_PIN = HREF_PIN;
    assign VGA_VS_PIN = VSYNC_PIN;


    /*
     * HCI wiring
     */
    
    logic w_dbncd_l_btn;
    logic w_dbncd_r_btn;
    logic w_dbncd_u_btn;
    logic w_dbncd_d_btn;
    logic w_dbncd_c_btn;

    logic [7:0] w_binary_num;

    Debounce_Switch L_btn(.i_Clk(clk),
                          .i_Switch(l_btn_PIN),
                          .o_Switch(w_dbncd_l_btn));
    
    Debounce_Switch R_btn(.i_Clk(clk),
                          .i_Switch(r_btn_PIN),
                          .o_Switch(w_dbncd_r_btn));

    Debounce_Switch U_btn(.i_Clk(clk),
                          .i_Switch(u_btn_PIN),
                          .o_Switch(w_dbncd_u_btn));
    
    Debounce_Switch D_btn(.i_Clk(clk),
                          .i_Switch(d_btn_PIN),
                          .o_Switch(w_dbncd_d_btn));

    Debounce_Switch C_btn(.i_Clk(clk),
                          .i_Switch(d_btn_PIN),
                          .o_Switch(w_dbncd_c_btn));
                        

    /*
     * i2c host interface wires
     */
    
    logic [6:0]  w_s_axis_cmd_address;
    logic        w_s_axis_cmd_start;
    logic        w_s_axis_cmd_read;
    logic        w_s_axis_cmd_write;
    logic        w_s_axis_cmd_write_multiple;
    logic        w_s_axis_cmd_stop;
    logic        w_s_axis_cmd_valid;
    logic        w_s_axis_cmd_ready;

    logic [7:0]  w_s_axis_data_tdata;
    logic        w_s_axis_data_tvalid;
    logic        w_s_axis_data_tready;
    logic        w_s_axis_data_tlast;

    logic [7:0]  w_m_axis_data_tdata;
    logic        w_m_axis_data_tvalid;
    logic        w_m_axis_data_tready;
    logic        w_m_axis_data_tlast;
    

    OV7670_CAMERA_DRIVER Cam (.clk(clk),
                              .reset_(reset_),
                              
                              .dbncd_l_btn(w_dbncd_l_btn),
                              .dbncd_r_btn(w_dbncd_r_btn),
                              .dbncd_u_btn(w_dbncd_u_btn),
                              .dbncd_d_btn(w_dbncd_d_btn),
                              .dbncd_c_btn(w_dbncd_c_btn),
                              .switches(switches_PIN),
                              .binary_num(w_binary_num),
                              
                              .s_axis_cmd_address(w_s_axis_cmd_address),
                              .s_axis_cmd_start(w_s_axis_cmd_start),
                              .s_axis_cmd_read(w_s_axis_cmd_read),
                              .s_axis_cmd_write(w_s_axis_cmd_write),
                              .s_axis_cmd_write_multiple(w_s_axis_cmd_write_multiple),
                              .s_axis_cmd_stop(w_s_axis_cmd_stop),
                              .s_axis_cmd_valid(w_s_axis_cmd_valid),
                              .s_axis_cmd_ready(w_s_axis_cmd_ready),
                              
                              .s_axis_data_tdata(w_s_axis_data_tdata),
                              .s_axis_data_tvalid(w_s_axis_data_tvalid),
                              .s_axis_data_tready(w_s_axis_data_tready),
                              .s_axis_data_tlast(w_s_axis_data_tlast),
                              
                              .m_axis_data_tdata(w_m_axis_data_tdata),
                              .m_axis_data_tvalid(w_m_axis_data_tvalid),
                              .m_axis_data_tlast(w_m_axis_data_tlast));

    /*
     * I2C interface
     */
    logic w_scl_i;
    logic w_scl_o;
    logic w_scl_t;
    logic w_sda_i;
    logic w_sda_o;
    logic w_sda_t;
    logic w_scl_pin;
    logic w_sda_pin;

    i2c_master I2c_m (.clk(w_clk_100Mhz_to_400KHz), // the SCCB clock has maximum value of 400 KHz, need to use clock divider
                      .rst(0), // Active HIGH

                     /*
                      * Host interface
                      */
                     .s_axis_cmd_address(w_s_axis_cmd_address),
                     .s_axis_cmd_start(w_s_axis_cmd_start),
                     .s_axis_cmd_read(w_s_axis_cmd_read),
                     .s_axis_cmd_write(w_s_axis_cmd_write),
                     .s_axis_cmd_write_multiple(w_s_axis_cmd_write_multiple),
                     .s_axis_cmd_stop(w_s_axis_cmd_stop),
                     .s_axis_cmd_valid(w_s_axis_cmd_valid),
                     .s_axis_cmd_ready(w_s_axis_cmd_ready),

                     .s_axis_data_tdata(w_s_axis_data_tdata),
                     .s_axis_data_tvalid(w_s_axis_data_tvalid),
                     .s_axis_data_tready(w_s_axis_data_tready),
                     .s_axis_data_tlast(w_s_axis_data_tlast),

                     .m_axis_data_tdata(w_m_axis_data_tdata),
                     .m_axis_data_tvalid(w_m_axis_data_tvalid),
                     .m_axis_data_tready(w_m_axis_data_tready),
                     .m_axis_data_tlast(w_m_axis_data_tlast),

                    /*
                     * I2C interface
                     */
                     .scl_i(), // Turns out, you can assign module ports within the module itself
                     .scl_o(), // So, we just leave these blank.
                     .scl_t(),
                     .sda_i(),
                     .sda_o(),
                     .sda_t(),
                     .scl_pin(SCL_PIN),
                     .sda_pin(SDA_PIN),

                    /*
                     * Status
                     */
                     .busy(),
                     .bus_control(),
                     .bus_active(),
                     .missed_ack(),

                    /*
                     * Configuration
                     */
                     .prescale(),
                     .stop_on_idle()
);

    
    SEGMENT_DRIVER_4_7 Sd4_7(.clk(clk),
                             .binary_num({8'b0000,w_binary_num}),
                             .AN3(AN3_PIN),
                             .AN2(AN2_PIN),
                             .AN1(AN1_PIN),
                             .AN0(AN0_PIN),
                             .CA(CA_PIN),
                             .CB(CB_PIN),
                             .CC(CC_PIN),
                             .CD(CD_PIN),
                             .CE(CE_PIN),
                             .CF(CF_PIN),
                             .CG(CG_PIN),
                             .DP(DP_PIN));
                             
    
    initial $display("%b", Sd4_7.counter);

    
endmodule