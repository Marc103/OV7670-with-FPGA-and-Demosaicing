/*
 * Parameterized VGA controller
 * H_FP  , horizontal front porch, unit is pixels
 * H_SYNC, horizontal sync pulse , unit is pixels
 * H_BP  , horizontal back porch , unit is pixels
 * V_FP  , vertical front porch  , unit is lines
 * V_SYNC, vertical sync pulse   , unit is lines
 * V_BP  , vertical sync pulse   , unit is lines
 *
 * The default values are set to VGA 640x480 @60hz with a 25 MHz pixel clock
 */

module VGA_PARAM 
    #(parameter RESOLUTION_WIDTH  = 640,
      parameter RESOLUTION_HEIGHT = 480,
      parameter H_FP   = 16,
      parameter H_SYNC = 96,
      parameter H_BP   = 48,
      parameter V_FP   = 10,
      parameter V_SYNC = 2,
      parameter V_BP   = 29)

    (input logic         pclk,

     /*
      * Video buffer ports
      */
     input logic  [11:0]  r_data,
     input logic         r_dv,
     output logic        r_clk,
     output logic [$clog2(RESOLUTION_WIDTH * RESOLUTION_HEIGHT):0] r_addr,
     output logic        r_en,
     output logic [$clog2(RESOLUTION_WIDTH):0] pixel_x,
     output logic [$clog2(RESOLUTION_HEIGHT):0] pixel_y,
     output logic sync_dv_o,


     /*
      * VGA ports
      */
     output logic [3:0]  red_bits,
     output logic [3:0]  green_bits,
     output logic [3:0]  blue_bits,
     output logic        hsync,
     output logic        vsync
     
     );
    
    // address state
    logic [$clog2(RESOLUTION_WIDTH * RESOLUTION_HEIGHT):0]  r_r_addr = 0;
    logic [$clog2(RESOLUTION_WIDTH * RESOLUTION_HEIGHT):0]  r_r_addr_next;

    // sync state
    logic r_vsync = 1;
    logic r_hsync = 1;

    logic r_vsync_next;
    logic r_hsync_next;

    logic r_sync_dv;

    // Line and column state
    logic [15:0] col  = 0; 
    logic [15:0] line = 0; 

    logic [15:0] col_next = 0; 
    logic [15:0] line_next = 0;

    always_comb begin
        line_next = line;
        col_next = col;
        r_vsync_next = 1;
        r_hsync_next = 1;
        r_r_addr_next = r_r_addr;
        r_sync_dv = 0;

        // Counting logic
        if(col == (H_FP + H_SYNC + H_BP + RESOLUTION_WIDTH - 1)) begin
            col_next = 0;
            if(line == (V_FP + V_SYNC + V_BP + RESOLUTION_HEIGHT - 1)) begin
                line_next = 0;
            end else begin
                line_next = line + 1;
            end
        end else begin
            col_next = col +  1;
        end
        
        // Vsync logic 
        if(line < V_FP) begin
            r_vsync_next = 1;
            if(line == (V_FP - 1)) begin
                r_vsync_next = 0;
            end 
        end else if (line < (V_FP + V_SYNC)) begin
            r_vsync_next = 0;
            if(line == (V_FP + V_SYNC - 1)) begin
                r_vsync_next = 1;
            end 
        end 

        // Hsync logic
        if(col < H_FP) begin
            r_hsync_next = 1;
            if(col == (H_FP - 1)) begin
                r_hsync_next = 0;
            end 
        end else if (col < (H_FP + H_SYNC)) begin
            r_hsync_next = 0;
            if(col == (H_FP + H_SYNC - 1)) begin
                r_hsync_next = 1;
            end 
        end 

        // Address logic and sync_dv
        if(line > (V_FP + V_SYNC + V_BP - 1)) begin
            if((col > (H_FP + H_SYNC + H_BP - 2)) && (col < (H_FP + H_SYNC + H_BP + RESOLUTION_WIDTH - 1))) begin
                r_sync_dv = 1;
                r_r_addr_next = r_r_addr + 1;
            end
        end else begin
            r_r_addr_next = 0;
            r_sync_dv = 0;
        end
    end
 

    
    always@(posedge pclk)
        begin
            // address state update
            r_r_addr <= r_r_addr_next;
            
            // sync state update
            r_hsync <= r_hsync_next;
            r_vsync <= r_vsync_next;
            line <= line_next;
            col <= col_next;
            
        end
    
    assign red_bits = r_data[11:8];
    assign green_bits = r_data[7:4];
    assign blue_bits = r_data[3:0];
    
    assign r_addr = r_r_addr;
    assign r_clk = pclk;
    assign r_en = 1'b1;
    
    assign pixel_x = col - (H_FP + H_SYNC + H_BP);
    assign pixel_y = line - (V_FP + V_SYNC + V_BP); 

    assign hsync = r_hsync;
    assign vsync = r_vsync;
    assign sync_dv_o = r_sync_dv;

    

endmodule