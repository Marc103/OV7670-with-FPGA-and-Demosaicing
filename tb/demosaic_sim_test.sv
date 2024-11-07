/*
 * Basically the top module ports with clk added
 * The idea being to drive the relevant input ports and wire them for the DUT 
 * 
 *
 */


// timescale <time_unit>/<time_precision>
`timescale 1ns / 1ps 

module TESTBENCH_FRAME();
    localparam IMAGE_WIDTH = 640;
    localparam IMAGE_HEIGHT = 480;
    localparam KERNEL_WIDTH = 3;
    localparam KERNEL_HEIGHT = 3;

    // Fixed Point Arithmetic params
    localparam FP_M_IMAGE = 4;
    localparam FP_N_IMAGE = 0;
    localparam FP_S_IMAGE = 0;

    localparam FP_M_KERNEL = 4;
    localparam FP_N_KERNEL = 8;
    localparam FP_S_KERNEL = 0;
    localparam KERNEL_BIT_DEPTH = FP_M_KERNEL + FP_N_KERNEL + FP_S_KERNEL;

    localparam FP_M_IMAGE_OUT = 12;
    localparam FP_N_IMAGE_OUT = 0;
    localparam FP_S_IMAGE_OUT = 0;
    
    localparam CONSTANT = 0;
    localparam CLKS_PER_PIXEL = 1;

    logic clk;
    initial begin
        clk = 0; 
        forever 
            begin
                #1 clk = ~clk;
            end 
    end

    logic [$clog2(IMAGE_WIDTH * IMAGE_HEIGHT)-1:0] w_r_addr;
    logic w_sync_dv;
    logic [15:0] w_vbuff_row;
    logic [15:0] w_vbuff_col;
    logic w_vbuff_valid;
    logic w_vbuff_pixel;

    pixel_data_interface #(
        .FP_M(FP_M_IMAGE),
        .FP_N(FP_N_IMAGE),
        .FP_S(FP_S_IMAGE)
    ) conv_net_if_i (clk);

    pixel_data_interface #(
        .FP_M(FP_M_IMAGE_OUT),
        .FP_N(FP_N_IMAGE_OUT),
        .FP_S(FP_S_IMAGE_OUT)
    ) conv_net_if_o(clk);


    VBUFF_READER vbuff_reader (
        .pclk(clk),
        
        .data_i(),
        .r_addr_o(w_r_addr),
        .r_en_o(),

        .sync_dv_i(w_sync_dv),

        .row_o(w_vbuff_row),
        .col_o(w_vbuff_col),
        .valid_o(w_vbuff_valid),
        .pixel_o(w_vbuff_pixel),

        .row_i(conv_net_if_o.row),
        .col_i(conv_net_if_o.col)
    );

    ////////////////////////////////////////////////////////////////
    // DUT setup
    logic kernel_status_o;
    logic rst_n_i;
    assign rst_n_i = 1;

    logic [(KERNEL_BIT_DEPTH-1):0] kernel_coeffs_i [KERNEL_HEIGHT][KERNEL_WIDTH];
    always_comb begin
        for(int y = 0; y < 3; y += 1) begin
            for(int x = 0; x < 3; x += 1) begin
                kernel_coeffs_i[y][x] = 0;
            end
        end
        kernel_coeffs_i[1][1] = 12'b000100000000;
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
    ) conv_net (
        .in(conv_net_if_i),
        .out(conv_net_if_o),

        // external wires
        .rst_n_i(rst_n_i),
        .kernel_coeffs_i(kernel_coeffs_i),
        .kernel_status_o(kernel_status_o)
    );

    VGA_PARAM vga_param (
        .pclk(clk),
        .r_data(conv_net_if_o.pixel),
        .r_dv(conv_net_if_o.valid),
        .r_clk(),
        .r_addr(),
        .r_en(),
        .pixel_x(),
        .pixel_y(),
        .sync_dv_o(w_sync_dv),

        .red_bits(),
        .green_bits(),
        .blue_bits(),
        .hsync(),
        .vsync()
    );
    
    initial begin
        // Write simulation code here 
        
    end
    

    
endmodule