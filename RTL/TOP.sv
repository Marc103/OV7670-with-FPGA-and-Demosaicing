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
     output logic XCLK,

     // video timing generator signals
     input  logic STROBE_PIN,
     input  logic HREF_PIN,
     input  logic PCLK_PIN,
     input  logic VSYNC_PIN,
     output logic RESET_PIN,
     output logic PWDN_PIN,

     input  logic [7:0] D_PIN,

     /*
      * i2c wiring
      */
     inout logic scl_PIN,
     inout logic sda_PIN
    );

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

    Debounce_Switch D_btn(.i_Clk(clk),
                          .i_Switch(d_btn_PIN),
                          .o_Switch(w_dbncd_c_btn));
                        


    OV7670_CAMERA_DRIVER Cam (.clk(clk),
                              .reset_(reset_),
                              
                              .dbncd_l_btn(w_dbncd_l_btn),
                              .dbncd_r_btn(w_dbncd_r_btn),
                              .dbncd_u_btn(w_dbncd_u_btn),
                              .dbncd_d_btn(w_dbncd_d_btn),
                              .dbncd_c_btn(w_dbncd_c_btn),
                              .switches(switches_PIN),
                              .binary_num(w_binary_num),
                              
                              .s_axis_cmd_address(),
                              .s_axis_cmd_start(),
                              .s_axis_cmd_read(),
                              .s_axis_cmd_write(),
                              .s_axis_cmd_write_multiple(),
                              .s_axis_cmd_stop(),
                              .s_axis_cmd_valid(),
                              .s_axis_cmd_ready(),
                              
                              .s_axis_data_tdata(),
                              .s_axis_data_tvalid(),
                              .s_axis_data_tready(),
                              .s_axis_data_tlast(),
                              
                              .m_axis_data_tdata(),
                              .m_axis_data_tvalid(),
                              .m_axis_data_tlast());
    
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