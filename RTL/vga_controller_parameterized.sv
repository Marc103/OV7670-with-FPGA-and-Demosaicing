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
     input logic  [11:0] r_data,
     input logic         r_dv,
     output logic        r_clk,
     output logic [$clog2(RESOLUTION_WIDTH * RESOLUTION_HEIGHT):0] r_addr,
     output logic        r_en,
     output logic [$clog2(RESOLUTION_WIDTH):0] pixel_x,
     output logic [$clog2(RESOLUTION_HEIGHT):0] pixel_y,


     /*
      * VGA ports
      */
     output logic [3:0]  red_bits,
     output logic [3:0]  green_bits,
     output logic [3:0]  blue_bits,
     output logic        hsync,
     output logic        vsync,
     
     output logic [$clog2(RESOLUTION_WIDTH * RESOLUTION_HEIGHT):0] d_r_addr
     
     );
    
    parameter [1:0] FP     = 2'b00;
    parameter [1:0] SYNC   = 2'b01;
    parameter [1:0] BP     = 2'b11;
    parameter [1:0] ACTV   = 2'b10; // active

    // rgb state
    logic [3:0] r_red_bits;
    logic [3:0] r_green_bits;
    logic [3:0] r_blue_bits;
    
    // address state
    logic [$clog2(RESOLUTION_WIDTH * RESOLUTION_HEIGHT):0]  r_r_addr;
    logic [$clog2(RESOLUTION_WIDTH * RESOLUTION_HEIGHT):0]  r_r_addr_next;

    // hsync state
    logic [1:0]                                                 s_hsync            = FP;
    logic                                                       r_hsync            = 1'b1;
    logic [$clog2(H_FP + H_SYNC + H_BP + RESOLUTION_WIDTH):0]   r_hsync_count      = 0;
    
    logic [2:0]                                                 s_hsync_next       = FP;
    logic                                                       r_hsync_next       = 1'b1;
    logic [$clog2(H_FP + H_SYNC + H_BP + RESOLUTION_WIDTH):0]   r_hsync_count_next = 0;

    // vsync state
    logic [1:0]                                                 s_vsync            = FP;
    logic                                                       r_vsync            = 1'b1;
    logic [$clog2(V_FP + V_SYNC + V_BP + RESOLUTION_HEIGHT):0]  r_vsync_count      = 0; 
    
    logic [2:0]                                                 s_vsync_next       = FP;
    logic                                                       r_vsync_next       = 1'b1;
    logic [$clog2(V_FP + V_SYNC + V_BP + RESOLUTION_HEIGHT):0]  r_vsync_count_next = 0;

    // Hsync 
    always_comb
        begin
            case(s_hsync)
                FP:
                    begin
                        r_hsync_next = 1'b1;
                        r_hsync_count_next = r_hsync_count + 1;
                        r_vsync_count_next = r_vsync_count;

                        if(r_hsync_count == (H_FP - 1)) begin
                        s_hsync_next = SYNC;
                        r_hsync_next = 1'b0;
                        end else s_hsync_next = FP;
                    end
                SYNC:
                    begin
                        r_hsync_next = 1'b0;
                        r_hsync_count_next = r_hsync_count + 1;
                        r_vsync_count_next = r_vsync_count;

                        if(r_hsync_count == (H_FP + H_SYNC - 1)) begin
                        s_hsync_next = BP;
                        r_hsync_next = 1'b1;
                        end else s_hsync_next = SYNC;
                    end
                BP:
                    begin
                        r_hsync_next = 1'b1;
                        r_hsync_count_next = r_hsync_count + 1;
                        r_vsync_count_next = r_vsync_count;

                        if(r_hsync_count == (H_FP + H_SYNC + H_BP - 1)) begin
                        s_hsync_next = ACTV;
                        r_hsync_next = 1'b1;
                        end else s_hsync_next = BP;

                        
                    end
                
                ACTV:
                    begin
                        r_hsync_next = 1'b1;
                        r_hsync_count_next = r_hsync_count + 1;
                        r_vsync_count_next = r_vsync_count;

                        if(r_hsync_count == (H_FP + H_SYNC + H_BP + RESOLUTION_WIDTH - 1)) 
                            begin

                                s_hsync_next = FP;
                                r_hsync_next = 1'b1;
                                r_hsync_count_next = 0;

                                if(r_vsync_count == (V_FP + V_SYNC + V_BP + RESOLUTION_HEIGHT - 1))
                                    r_vsync_count_next = 0;
                                else
                                    r_vsync_count_next = r_vsync_count + 1;
                            end 
                                else s_hsync_next = ACTV;
                    end
            endcase
           
        end

    // Vsync 
    always_comb
        begin
            case(s_vsync)
                FP:
                    begin
                        r_vsync_next = 1'b1;

                        if(r_vsync_count == (V_FP - 1)) begin
                        s_vsync_next = SYNC;
                        r_vsync_next = 1'b0;
                        end else s_vsync_next = FP;
                    end
                SYNC:
                    begin
                        r_vsync_next = 1'b0;

                        if(r_vsync_count == (V_FP + V_SYNC - 1)) begin
                        s_vsync_next = BP;
                        r_vsync_next = 1'b1;
                        end else s_vsync_next = SYNC;
                    end
                BP:
                    begin
                        r_vsync_next = 1'b1;

                        if(r_vsync_count == (V_FP + V_SYNC + V_BP - 1)) begin
                        s_vsync_next = ACTV;
                        r_vsync_next = 1'b1;
                        end else s_vsync_next = BP;
                    end
                
                ACTV:
                    begin
                        r_vsync_next = 1'b1;

                        if(r_vsync_count == V_FP + V_SYNC + V_BP + RESOLUTION_HEIGHT - 1) begin
                        s_vsync_next = FP;
                        r_vsync_next = 1'b1;
                        end else s_vsync_next = ACTV;
                    end

            endcase
            
            
        end

    // Address and RGB output
    always_comb begin
        if((s_vsync == ACTV) && (s_hsync == ACTV))
            begin
                r_r_addr_next = r_r_addr + 1;
            end
        else if (s_vsync != ACTV)
            begin
                r_r_addr_next = 0;
            end
        else
            begin
                r_r_addr_next = r_r_addr;
            end

        if((s_hsync == ACTV) && (s_vsync == ACTV))
            begin
                red_bits   = r_red_bits;
                green_bits = r_green_bits;
                blue_bits  = r_blue_bits;

            end
        else
            begin
                red_bits   = 4'h0;
                green_bits = 4'h0;
                blue_bits  = 4'h0;
            end
    end
        
    
    always@(posedge pclk)
        begin
            // address state update
            r_r_addr <= r_r_addr_next;
            
            // hsync state update
            s_hsync       <= s_hsync_next;
            r_hsync       <= r_hsync_next;
            r_hsync_count <= r_hsync_count_next;

            // vsync state update
            s_vsync       <= s_vsync_next;
            r_vsync       <= r_vsync_next;
            r_vsync_count <= r_vsync_count_next;

            // Grab data (doesn't actually matter if r_dv)
            r_red_bits      <= r_data[11:8];
            r_green_bits    <= r_data[7:4];
            r_blue_bits     <= r_data[3:0];
        end
        
    assign d_r_addr = r_r_addr;

    assign r_addr = r_r_addr;
    assign r_clk = pclk;
    assign r_en = 1'b1;
    
    // Hope this happens in one cycle
    assign pixel_x = r_hsync_count - (H_FP + H_SYNC + H_BP);
    assign pixel_y = r_vsync_count - (V_FP + V_SYNC + V_BP - 1); 

    assign hsync = r_hsync;
    assign vsync = r_vsync;

    

endmodule