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
    
    assign PWDN_PIN = 1'b0;
    assign RST_PIN = 1'b1;
    
    /*
    logic clk = 0;
    initial 
        begin
            clk = 0; 
            forever 
               begin
                #1 clk = ~clk;
                end 
         end
    */
     
    
    /*
     * Clock wiring, to produce 25 MHz clock and 400 KHz (max 400Khz for i2c)
     * from 100 MHz
     */
     logic w_clk_100MHz_to_25MHz;
     logic w_clk_100Mhz_to_400KHz;

    // 100MHz/25MHz = 4, so we use 4/2 = 2
    CLK_DIV #(.div_by_x2(2)) clk_x2_2 (.clk(clk), .o_clk(w_clk_100MHz_to_25MHz));
    
    // 100MHz/6.25Mhz = 16, so we use 16/2 = 8
    CLK_DIV #(.div_by_x2(8)) clk_x2_8 (.clk(clk), .o_clk(w_clk_100MHz_to_6_25MHz));
    
    assign MCLK = w_clk_100MHz_to_25MHz;
   
    /*
     * RGB deserializer wiring (and VGA port wiring)
     * this will be changed to RGB565
     */
    logic [7:0] w_raw_bayer;
    logic [$clog2(640 * 480)-1:0]  w_Wr_Addr;
    
    RAW_BAYER raw_bayer (.D(D_PIN),
                         .HREF(HREF_PIN),
                         .VSYNC(VSYNC_PIN),
                         .PCLK(PCLK_PIN),
                         .raw_bayer(w_raw_bayer),
                         .dv(w_Wr_DV),
                         .w_addr(w_Wr_Addr));

    /*
     * Video buffer (dual port ram)
     */
    // VGA (640 X 480) at 4 bits per pixel (RGB 444)
    // 1899Kb of BRAM
    // 640 x 480 x 4 = 1228Kb 

    logic                      w_Wr_Clk;
    logic [3:0]                w_Wr_Data;

    logic                          w_Rd_Clk;
    logic [$clog2(640 * 480)-1:0]  w_Rd_Addr;
    logic                          w_Rd_En;
    logic                          w_Rd_DV;
    logic [3:0]                    w_Rd_Data;
    
    assign w_Wr_Data = w_raw_bayer[7:4];
    
    assign w_Wr_Clk = PCLK_PIN;

    RAM_2Port #(.WIDTH(4), .DEPTH(640*480)) Vbuff
               (.i_Wr_Clk(w_Wr_Clk),
                .i_Wr_Addr(w_Wr_Addr),
                .i_Wr_DV(w_Wr_DV),
                .i_Wr_Data(w_Wr_Data),
                
                .i_Rd_Clk(w_Rd_Clk),
                .i_Rd_Addr(w_Rd_Addr),
                .i_Rd_En(w_Rd_En),
                .o_Rd_DV(w_Rd_DV),
                .o_Rd_Data(w_Rd_Data));

    /*
     * VGA controller wiring
     *
     */

    logic [$clog2(640)-1:0]     w_vga_to_vbuff_pixel_x;
    logic [$clog2(480)-1:0]     w_vga_to_vbuff_pixel_y;

    VGA_PARAM vga ( .pclk(w_clk_100MHz_to_25MHz),
                    .r_data(w_Rd_Data),
                    .r_dv(w_Rd_DV),

                    .r_clk(w_Rd_Clk), 
                    .r_addr(w_Rd_Addr),
                    .r_en(w_Rd_En),
                    .pixel_x(w_vga_to_vbuff_pixel_x),
                    .pixel_y(w_vga_to_vbuff_pixel_y),
                    
                    .red_bits(VGA_R_PIN),
                    .green_bits(VGA_G_PIN),
                    .blue_bits(VGA_B_PIN),
                    
                    .hsync(VGA_HS_PIN),
                    .vsync(VGA_VS_PIN));

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
                          .i_Switch(c_btn_PIN),
                          .o_Switch(w_dbncd_c_btn));
                        

    /*
     * i2c host interface wires
     */
    
    logic       w_usher;
    logic [7:0] w_address;
    logic [7:0] w_subaddress;
    logic [7:0] w_data;
    logic [1:0] w_mode;

    logic w_busy;
    

    OV7670_CAMERA_DRIVER Cam (.clk(clk),
                              .reset_(reset_),
                              
                              .dbncd_l_btn(w_dbncd_l_btn),
                              .dbncd_r_btn(w_dbncd_r_btn),
                              .dbncd_u_btn(w_dbncd_u_btn),
                              .dbncd_d_btn(w_dbncd_d_btn),
                              .dbncd_c_btn(w_dbncd_c_btn),
                              .switches(switches_PIN),
                              .binary_num(w_binary_num),

                              .o_usher(w_usher),
                              .o_address(w_address),
                              .o_subaddress(w_subaddress),
                              .o_data(w_data),
                              .o_mode(w_mode),

                              .i_busy(w_busy)

                              );
                               
    assign LED[15:8] = w_subaddress;
    assign LED[7:0]  = w_data;

    SCCB sccb (.clk(clk),
               .i_usher(w_usher),
               .i_address(w_address),
               .i_subaddress(w_subaddress),
               .i_data(w_data),
               .i_mode(w_mode),
               .o_busy(w_busy),
               .io_sda(SDA_PIN),
               .o_scl(SCL_PIN));

    
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

    
endmodule