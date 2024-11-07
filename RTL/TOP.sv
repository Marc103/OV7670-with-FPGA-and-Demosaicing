/*
 * Top module wiring
 * *_PIN is what the naming will be in the constraints file of
 * the physical wire / pin
 *
 */
`include "pixel_data_interface.svh"
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
    localparam IMAGE_WIDTH = 640;
    localparam IMAGE_HEIGHT = 480;
    localparam KERNEL_WIDTH = 3;
    localparam KERNEL_HEIGHT = 3;

    // Fixed Point Arithmetic params
    localparam FP_M_IMAGE = 4;
    localparam FP_N_IMAGE = 0;
    localparam FP_S_IMAGE = 0;

    localparam FP_M_KERNEL = 1;
    localparam FP_N_KERNEL = 8;
    localparam FP_S_KERNEL = 0;
    localparam KERNEL_BIT_DEPTH = FP_M_KERNEL + FP_N_KERNEL + FP_S_KERNEL;

    localparam FP_M_IMAGE_OUT = 4;
    localparam FP_N_IMAGE_OUT = 0;
    localparam FP_S_IMAGE_OUT = 0;
    
    localparam CONSTANT = 0;
    localparam CLKS_PER_PIXEL = 1;
        
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
    */
     
    
    /*
     * Clock wiring, to produce 25 MHz clock and 400 KHz (max 400Khz for i2c)
     * from 100 MHz
     */
     logic w_clk_100MHz_to_25MHz;
     logic w_clk_100Mhz_to_400KHz;

    // 100MHz/25MHz = 4, so we use 4/2 = 2
    CLK_DIV #(.div_by_x2(2)) clk_x2_2 (.clk(clk), .o_clk(w_clk_100MHz_to_25MHz));
      
    assign MCLK = w_clk_100MHz_to_25MHz;
   
    /*
     * RGB deserializer wiring (and VGA port wiring)
     * 
     */
    logic [7:0] w_raw_bayer;
    logic [$clog2(640 * 480)-1:0]  w_Wr_Addr;
    logic w_Wr_DV;
    
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
    logic [$clog2(IMAGE_WIDTH * IMAGE_HEIGHT)-1:0]  w_Rd_Addr;
    logic                          w_Rd_En;
    logic                          w_Rd_DV;
    logic [3:0]                    w_Rd_Data;
    
    assign w_Wr_Data = w_raw_bayer[7:4];
    
    assign w_Wr_Clk = PCLK_PIN;

    RAM_2Port #(.WIDTH(4), .DEPTH(IMAGE_WIDTH * IMAGE_HEIGHT)) Vbuff
               (.i_Wr_Clk(w_Wr_Clk),
                .i_Wr_Addr(w_Wr_Addr),
                .i_Wr_DV(w_Wr_DV),
                .i_Wr_Data(w_Wr_Data),
                
                .i_Rd_Clk(w_Rd_Clk),
                .i_Rd_Addr(w_Rd_Addr),
                .i_Rd_En(w_Rd_En),
                .o_Rd_DV(w_Rd_DV),
                .o_Rd_Data(w_Rd_Data));
    
    assign w_Rd_Clk = w_clk_100MHz_to_25MHz;         
    
    
    logic [$clog2(IMAGE_WIDTH * IMAGE_HEIGHT)-1:0] w_r_addr;
    logic w_r_en;
    logic w_sync_dv;
    logic [15:0] w_vbuff_row;
    logic [15:0] w_vbuff_col;
    logic w_vbuff_valid;
    logic [3:0] w_vbuff_pixel;

    assign w_Rd_Addr = w_r_addr;
    assign w_Rd_En = w_r_en;

    pixel_data_interface #(
        .FP_M(FP_M_IMAGE),
        .FP_N(FP_N_IMAGE),
        .FP_S(FP_S_IMAGE)
    ) conv_net_if_i (w_clk_100MHz_to_25MHz);

    pixel_data_interface #(
        .FP_M(FP_M_IMAGE_OUT),
        .FP_N(FP_N_IMAGE_OUT),
        .FP_S(FP_S_IMAGE_OUT)
    ) conv_net_red_if_o(w_clk_100MHz_to_25MHz);
    
    pixel_data_interface #(
        .FP_M(FP_M_IMAGE_OUT),
        .FP_N(FP_N_IMAGE_OUT),
        .FP_S(FP_S_IMAGE_OUT)
    ) conv_net_green_if_o(w_clk_100MHz_to_25MHz);
    
    pixel_data_interface #(
        .FP_M(FP_M_IMAGE_OUT),
        .FP_N(FP_N_IMAGE_OUT),
        .FP_S(FP_S_IMAGE_OUT)
    ) conv_net_blue_if_o(w_clk_100MHz_to_25MHz);

    ////////////////////////////////////////////////////////////////
    // vbuff reader
    
    VBUFF_READER vbuff_reader (
        .pclk(w_clk_100MHz_to_25MHz),
        
        .data_i(w_Rd_Data),
        .r_addr_o(w_r_addr),
        .r_en_o(w_r_en),

        .sync_dv_i(w_sync_dv),

        .row_o(w_vbuff_row),
        .col_o(w_vbuff_col),
        .valid_o(w_vbuff_valid),
        .pixel_o(w_vbuff_pixel),

        .row_i(conv_net_red_if_o.row),
        .col_i(conv_net_red_if_o.col)
    );

    ////////////////////////////////////////////////////////////////
    // conv setup
    logic kernel_status_o;
    logic rst_n_i;
    logic r;
    logic c;
    assign r = conv_net_red_if_o.row[0];
    assign c = conv_net_red_if_o.col[0];
    assign rst_n_i = 1;

    logic [(KERNEL_BIT_DEPTH-1):0] kernel_coeffs_i [3][KERNEL_HEIGHT][KERNEL_WIDTH];
    always_comb begin
        for(int c = 0; c < 3; c+= 1) begin
            for(int y = 0; y < 3; y += 1) begin
                for(int x = 0; x < 3; x += 1) begin
                    kernel_coeffs_i[c][y][x] = 0;
                end
            end
        end
        
        // decimal to binary mappings - uq1.8
        // 0    - 9'b0_0000_0000;
        // 0.2  - 9'b0_0011_0011;
        // 0.25 - 9'b0_0100_0000;
        // 0.5  - 9'b0_1000_0000;
        // 1    - 9'b1_0000_0000;
        
        ////////////////////////////////////
        // red kernel
        /*
        if((r == 0) && (c == 0)) begin
            kernel_coeffs_i[0][0][0] = 9'b0_0000_0000;
            kernel_coeffs_i[0][0][1] = 9'b0_0000_0000;
            kernel_coeffs_i[0][0][2] = 9'b0_0000_0000;
            kernel_coeffs_i[0][1][0] = 9'b0_0000_0000;
            kernel_coeffs_i[0][1][1] = 9'b1_0000_0000;
            kernel_coeffs_i[0][1][2] = 9'b0_0000_0000;
            kernel_coeffs_i[0][2][0] = 9'b0_0000_0000;
            kernel_coeffs_i[0][2][1] = 9'b0_0000_0000;
            kernel_coeffs_i[0][2][2] = 9'b0_0000_0000;
        end
        if((r == 0) && (c == 1)) begin
            kernel_coeffs_i[0][0][0] = 9'b0_0000_0000;
            kernel_coeffs_i[0][0][1] = 9'b0_0000_0000;
            kernel_coeffs_i[0][0][2] = 9'b0_0000_0000;
            kernel_coeffs_i[0][1][0] = 9'b0_1000_0000;
            kernel_coeffs_i[0][1][1] = 9'b0_0000_0000;
            kernel_coeffs_i[0][1][2] = 9'b0_1000_0000;
            kernel_coeffs_i[0][2][0] = 9'b0_0000_0000;
            kernel_coeffs_i[0][2][1] = 9'b0_0000_0000;
            kernel_coeffs_i[0][2][2] = 9'b0_0000_0000;
        end
        if((r == 1) && (c == 0)) begin
            kernel_coeffs_i[0][0][0] = 9'b0_0000_0000;
            kernel_coeffs_i[0][0][1] = 9'b0_1000_0000;
            kernel_coeffs_i[0][0][2] = 9'b0_0000_0000;
            kernel_coeffs_i[0][1][0] = 9'b0_0000_0000;
            kernel_coeffs_i[0][1][1] = 9'b0_0000_0000;
            kernel_coeffs_i[0][1][2] = 9'b0_0000_0000;
            kernel_coeffs_i[0][2][0] = 9'b0_0000_0000;
            kernel_coeffs_i[0][2][1] = 9'b0_1000_0000;
            kernel_coeffs_i[0][2][2] = 9'b0_0000_0000;
        end
        if((r == 1) && (c == 1)) begin
            kernel_coeffs_i[0][0][0] = 9'b0_0100_0000;
            kernel_coeffs_i[0][0][1] = 9'b0_0000_0000;
            kernel_coeffs_i[0][0][2] = 9'b0_0100_0000;
            kernel_coeffs_i[0][1][0] = 9'b0_0000_0000;
            kernel_coeffs_i[0][1][1] = 9'b0_0000_0000;
            kernel_coeffs_i[0][1][2] = 9'b0_0000_0000;
            kernel_coeffs_i[0][2][0] = 9'b0_0100_0000;
            kernel_coeffs_i[0][2][1] = 9'b0_0000_0000;
            kernel_coeffs_i[0][2][2] = 9'b0_0100_0000;
        end
        */
        
        ////////////////////////////////////
        // green kernel
        if((r == 0) && (c == 1)) begin
            kernel_coeffs_i[1][0][0] = 9'b0_0000_0000;
            kernel_coeffs_i[1][0][1] = 9'b0_0100_0000;
            kernel_coeffs_i[1][0][2] = 9'b0_0000_0000;
            kernel_coeffs_i[1][1][0] = 9'b0_0100_0000;
            kernel_coeffs_i[1][1][1] = 9'b0_0000_0000;
            kernel_coeffs_i[1][1][2] = 9'b0_0100_0000;
            kernel_coeffs_i[1][2][0] = 9'b0_0000_0000;
            kernel_coeffs_i[1][2][1] = 9'b0_0100_0000;
            kernel_coeffs_i[1][2][2] = 9'b0_0000_0000;
        end
        if((r == 0) && (c == 0)) begin
            kernel_coeffs_i[1][0][0] = 9'b0_0011_0011;
            kernel_coeffs_i[1][0][1] = 9'b0_0000_0000;
            kernel_coeffs_i[1][0][2] = 9'b0_0011_0011;
            kernel_coeffs_i[1][1][0] = 9'b0_0000_0000;
            kernel_coeffs_i[1][1][1] = 9'b0_0011_0011;
            kernel_coeffs_i[1][1][2] = 9'b0_0000_0000;
            kernel_coeffs_i[1][2][0] = 9'b0_0011_0011;
            kernel_coeffs_i[1][2][1] = 9'b0_0000_0000;
            kernel_coeffs_i[1][2][2] = 9'b0_0011_0011;
        end 
        if((r == 1) && (c == 1)) begin
            kernel_coeffs_i[1][0][0] = 9'b0_0011_0011;
            kernel_coeffs_i[1][0][1] = 9'b0_0000_0000;
            kernel_coeffs_i[1][0][2] = 9'b0_0011_0011;
            kernel_coeffs_i[1][1][0] = 9'b0_0000_0000;
            kernel_coeffs_i[1][1][1] = 9'b0_0011_0011;
            kernel_coeffs_i[1][1][2] = 9'b0_0000_0000;
            kernel_coeffs_i[1][2][0] = 9'b0_0011_0011;
            kernel_coeffs_i[1][2][1] = 9'b0_0000_0000;
            kernel_coeffs_i[1][2][2] = 9'b0_0011_0011;
        end
        if((r == 1) && (c == 0)) begin
            kernel_coeffs_i[1][0][0] = 9'b0_0000_0000;
            kernel_coeffs_i[1][0][1] = 9'b0_0100_0000;
            kernel_coeffs_i[1][0][2] = 9'b0_0000_0000;
            kernel_coeffs_i[1][1][0] = 9'b0_0100_0000;
            kernel_coeffs_i[1][1][1] = 9'b0_0000_0000;
            kernel_coeffs_i[1][1][2] = 9'b0_0100_0000;
            kernel_coeffs_i[1][2][0] = 9'b0_0000_0000;
            kernel_coeffs_i[1][2][1] = 9'b0_0100_0000;
            kernel_coeffs_i[1][2][2] = 9'b0_0000_0000;
        end
        
        for(int y = 0; y < 3; y += 1) begin
            for(int x = 0; x < 3; x += 1) begin
                    kernel_coeffs_i[1][y][x] = 0;
            end
        end
        kernel_coeffs_i[1][1][1] = 9'b1_0000_0000;
        /*
        // blue kernel
        if((r == 0) && (c == 0)) begin
            kernel_coeffs_i[2][0][0] = 9'b0_0100_0000;
            kernel_coeffs_i[2][0][1] = 9'b0_0000_0000;
            kernel_coeffs_i[2][0][2] = 9'b0_0100_0000;
            kernel_coeffs_i[2][1][0] = 9'b0_0000_0000;
            kernel_coeffs_i[2][1][1] = 9'b0_0000_0000;
            kernel_coeffs_i[2][1][2] = 9'b0_0000_0000;
            kernel_coeffs_i[2][2][0] = 9'b0_0100_0000;
            kernel_coeffs_i[2][2][1] = 9'b0_0000_0000;
            kernel_coeffs_i[2][2][2] = 9'b0_0100_0000;
        end
        if((r == 0) && (c == 1)) begin
            kernel_coeffs_i[2][0][0] = 9'b0_0000_0000;
            kernel_coeffs_i[2][0][1] = 9'b0_1000_0000;
            kernel_coeffs_i[2][0][2] = 9'b0_0000_0000;
            kernel_coeffs_i[2][1][0] = 9'b0_0000_0000;
            kernel_coeffs_i[2][1][1] = 9'b0_0000_0000;
            kernel_coeffs_i[2][1][2] = 9'b0_0000_0000;
            kernel_coeffs_i[2][2][0] = 9'b0_0000_0000;
            kernel_coeffs_i[2][2][1] = 9'b0_1000_0000;
            kernel_coeffs_i[2][2][2] = 9'b0_0000_0000;
        end
        if((r == 1) && (c == 0)) begin
            kernel_coeffs_i[2][0][0] = 9'b0_0000_0000;
            kernel_coeffs_i[2][0][1] = 9'b0_0000_0000;
            kernel_coeffs_i[2][0][2] = 9'b0_0000_0000;
            kernel_coeffs_i[2][1][0] = 9'b0_1000_0000;
            kernel_coeffs_i[2][1][1] = 9'b0_0000_0000;
            kernel_coeffs_i[2][1][2] = 9'b0_1000_0000;
            kernel_coeffs_i[2][2][0] = 9'b0_0000_0000;
            kernel_coeffs_i[2][2][1] = 9'b0_0000_0000;
            kernel_coeffs_i[2][2][2] = 9'b0_0000_0000;
        end
        if((r == 1) && (c == 1)) begin
            kernel_coeffs_i[2][0][0] = 9'b0_0000_0000;
            kernel_coeffs_i[2][0][1] = 9'b0_0000_0000;
            kernel_coeffs_i[2][0][2] = 9'b0_0000_0000;
            kernel_coeffs_i[2][1][0] = 9'b0_0000_0000;
            kernel_coeffs_i[2][1][1] = 9'b1_0000_0000;
            kernel_coeffs_i[2][1][2] = 9'b0_0000_0000;
            kernel_coeffs_i[2][2][0] = 9'b0_0000_0000;
            kernel_coeffs_i[2][2][1] = 9'b0_0000_0000;
            kernel_coeffs_i[2][2][2] = 9'b0_0000_0000;
        end
        */
        
        // The problem is doing this all in one
        // conv_net will cause trailing decimal values to
        // 'bleed' into the lower bits. Hence a conv net
        // per channel.
        
    end
    
    assign conv_net_if_i.row = w_vbuff_row;
    assign conv_net_if_i.col = w_vbuff_col;
    assign conv_net_if_i.valid = w_vbuff_valid;
    assign conv_net_if_i.pixel = w_vbuff_pixel;
    
    conv_net #(
        // Kernel FP params
        .FP_M_KERNEL(FP_M_KERNEL),
        .FP_N_KERNEL(FP_N_KERNEL),
        .FP_S_KERNEL(FP_S_KERNEL),

        .WIDTH(IMAGE_WIDTH),
        .HEIGHT(IMAGE_HEIGHT),

        .K_WIDTH(KERNEL_WIDTH),
        .K_HEIGHT(KERNEL_HEIGHT),

        .CONSTANT(CONSTANT),
        .CLKS_PER_PIXEL(CLKS_PER_PIXEL)
    ) conv_net_red (
        .in(conv_net_if_i),
        .out(conv_net_red_if_o),

        // external wires
        .rst_n_i(rst_n_i),
        .kernel_coeffs_i(kernel_coeffs_i[0]),
        .kernel_status_o(kernel_status_o)
    );
    
    conv_net #(
        // Kernel FP params
        .FP_M_KERNEL(FP_M_KERNEL),
        .FP_N_KERNEL(FP_N_KERNEL),
        .FP_S_KERNEL(FP_S_KERNEL),

        .WIDTH(IMAGE_WIDTH),
        .HEIGHT(IMAGE_HEIGHT),

        .K_WIDTH(KERNEL_WIDTH),
        .K_HEIGHT(KERNEL_HEIGHT),

        .CONSTANT(CONSTANT),
        .CLKS_PER_PIXEL(CLKS_PER_PIXEL)
    ) conv_net_green (
        .in(conv_net_if_i),
        .out(conv_net_green_if_o),

        // external wires
        .rst_n_i(rst_n_i),
        .kernel_coeffs_i(kernel_coeffs_i[1]),
        .kernel_status_o(kernel_status_o)
    );
    
    conv_net #(
        // Kernel FP params
        .FP_M_KERNEL(FP_M_KERNEL),
        .FP_N_KERNEL(FP_N_KERNEL),
        .FP_S_KERNEL(FP_S_KERNEL),

        .WIDTH(IMAGE_WIDTH),
        .HEIGHT(IMAGE_HEIGHT),

        .K_WIDTH(KERNEL_WIDTH),
        .K_HEIGHT(KERNEL_HEIGHT),

        .CONSTANT(CONSTANT),
        .CLKS_PER_PIXEL(CLKS_PER_PIXEL)
    ) conv_net_blue (
        .in(conv_net_if_i),
        .out(conv_net_blue_if_o),

        // external wires
        .rst_n_i(rst_n_i),
        .kernel_coeffs_i(kernel_coeffs_i[2]),
        .kernel_status_o(kernel_status_o)
    );
    
    /*
     * VGA controller wiring
     *
     */
     logic [11:0] data;
     assign data = {conv_net_green_if_o.pixel, conv_net_green_if_o.pixel, conv_net_green_if_o.pixel};

    VGA_PARAM vga_param (
        .pclk(w_clk_100MHz_to_25MHz),
        .r_data(data),
        .r_dv(conv_net_red_if_o.valid),
        .r_clk(),
        .r_addr(),
        .r_en(),
        .pixel_x(),
        .pixel_y(),
        .sync_dv_o(w_sync_dv),

        .red_bits(VGA_R_PIN),
        .green_bits(VGA_G_PIN),
        .blue_bits(VGA_B_PIN),
        .hsync(VGA_HS_PIN),
        .vsync(VGA_VS_PIN)
    );


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