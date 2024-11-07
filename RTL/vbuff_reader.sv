/*
 * Streams image from memory with
 * appropriate pixel_y, pixel_x and dv value
 * Also has a pipe full mechanism so that what's
 * being driven out is in sync with whats needed
 *
 * This is meant to work withe vga_controller_parameterized.sv
 * module, specifically with 'sync_dv'. This only works because
 * the pipe becomes full within V_FP + V_SYNC + V_BP lines.
 *
 */

 module VBUFF_READER #(
    parameter WIDTH = 640,
    parameter HEIGHT = 480,
    parameter PIPE_PIXEL_X = WIDTH - 2,
    parameter PIPE_PIXEL_Y = HEIGHT - 1
 ) (
    input pclk,

    // Vbuff ports
    input [3:0] data_i,
    output [$clog2(WIDTH * HEIGHT)-1:0] r_addr_o,
    output r_en_o,

    // Sync ports
    input sync_dv_i,

    // Conv_net ports
    output [15:0] row_o,
    output [15:0] col_o,
    output valid_o,
    output [3:0] pixel_o,

    input [15:0] row_i,
    input [15:0] col_i
 );
    logic [$clog2(WIDTH * HEIGHT):0]  r_r_addr = 0;
    logic [$clog2(WIDTH * HEIGHT):0]  r_r_addr_next;

    logic [15:0] r_row = HEIGHT - 1;
    logic [15:0] r_col = WIDTH - 1;
    logic r_valid = 0;

    logic [15:0] r_row_next;
    logic [15:0] r_col_next;
    logic r_valid_next;

    logic ispipefull = 0;
    logic ispipefull_next;

    always_comb begin
        r_row_next = r_row;
        r_col_next = r_col;
        r_r_addr_next = r_r_addr;
        r_valid_next = 0;
        ispipefull_next = 0;


        if((row_i == PIPE_PIXEL_Y) && (col_i == PIPE_PIXEL_X)) begin
            ispipefull_next = 1;
        end
        if(ispipefull == 1) begin
            ispipefull_next = 1;
        end

        if((ispipefull == 0) || (sync_dv_i == 1)) begin
            r_valid_next = 1;
            
            if(r_r_addr == ((WIDTH * HEIGHT)-1)) begin
                r_r_addr_next = 0;
            end else begin
                r_r_addr_next = r_r_addr + 1;
            end

            if(r_col == (WIDTH - 1)) begin
                r_col_next = 0;
                if(r_row == (HEIGHT - 1)) begin
                    r_row_next = 0;
                end else begin
                    r_row_next = r_row + 1;
                end
            end else begin
                r_col_next = r_col + 1;
            end
        end
    end

    always@(posedge pclk) begin
        r_r_addr <= r_r_addr_next;
        r_row <= r_row_next;
        r_col <= r_col_next;
        r_valid <= r_valid_next;
        ispipefull <= ispipefull_next;
    end
    
    assign r_en_o = 1;
    assign r_addr_o = r_r_addr;
    assign pixel_o = data_i;
    assign row_o = r_row;
    assign col_o = r_col;
    assign valid_o = r_valid;
    
 endmodule