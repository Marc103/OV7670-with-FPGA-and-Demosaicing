/*
 * QVGA Timing Circuit: 
 * 320 x 240
 * 60 Hz vertical frequency
 * 6.25 MHz pixel clock
 * RGB 444 (since the basys 3 vga port supports 4 bits per color channel)
 * 
 * See VGA timing calculations to see how the numbers were derived.
 */

module QVGA 
    (input         pclk,

     /*
      * Video buffer ports
      */
     input  [15:0] r_data,
     input         r_dv,
     output        r_clk,
     output [15:0] r_addr,
     output [15:0] r_en,

     /*
      * VGA ports
      */
     output [3:0]  red_bits,
     output [3:0]  green_bits,
     output [3:0]  blue_bits,
     output        hsync,
     output        vsync
     );


    parameter [1:0] FP   = 2'b00;
    parameter [1:0] SYNC = 2'b01;
    parameter [1:0] BP   = 2'b10;
    parameter [1:0] ACTV = 2'b11; // ACTV stands for active
    
    // address state
    logic [16:0]  r_r_addr;
    logic [16:0]  r_r_addr_next;

    // hsync state
    logic [1:0]   s_hsync            = FP;
    logic [8:0]   r_hsync_count      = 0;
    logic         r_hsync            = 0;
    
    logic [1:0]   s_hsync_next       = FP;
    logic [8:0]   r_hsync_count_next = 0;
    logic         r_hsync_next       = 0;

    // vsync state
    logic [1:0]   s_vsync            = FP;
    logic [17:0]  r_vsync_count      = 0; 
    logic         r_vsync            = 0;
    
    logic [1:0]   s_vsync_next       = FP;
    logic         r_vsync_count_next = 0;
    logic         r_vsync_next       = 0;

    // Hsync 
    always_comb
        begin
            
            case(s_hsync)
                FP:
                    begin
                        r_hsync_next = 1'b0;
                        r_hsync_count_next = r_hsync_count + 1;

                        if(r_hsync_count == 9'd22) begin
                        s_hsync_next = BP;
                        r_hsync_next = 1'b1;
                        end else s_hsync_next = SYNC;
                    end
                SYNC:
                    begin
                        r_hsync_next = 1'b1;
                        r_hsync_count_next = r_hsync_count + 1;

                        if(r_hsync_count == 9'd45) begin
                        s_hsync_next = BP;
                        r_hsync_next = 1'b0;
                        end else s_hsync_next = SYNC;
                    end
                BP:
                    begin
                        r_r_addr_next = r_r_addr + 1;

                        r_hsync_next = 1'b1;
                        r_hsync_count_next = r_hsync_count + 1;

                        if(r_hsync_count == 9'd92) begin
                        s_hsync_next = ACTV;
                        r_hsync_next = 1'b0;
                        end else s_hsync_next = BP;
                    end
                
                ACTV:
                    begin
                        r_r_addr_next = r_r_addr + 1;

                        r_hsync_next = 1'b0;
                        r_hsync_count_next = r_hsync_count + 1;

                        if(r_hsync_count == 9'd412) begin
                        s_hsync_next = BP;
                        r_hsync_next = 1'b0;
                        r_hsync_count_next = 0;
                        end else s_hsync_next = SYNC;
                    end
            endcase
        end

    // Vsync 
    always_comb
        begin
            case(s_vsync)
                FP:
                    begin
                    end
                SYNC:
                    begin
                    end
                BP:
                    begin
                    end
            endcase
        end

    always@(posedge pclk)
        begin
            // address state update
            r_r_addr = r_r_addr_next;
            
            // hsync state update
            s_hsync       <= s_hsync_next;
            r_hsync_count <= r_hsync_count_next;
            r_hsync       <= r_hsync_next;

            // vsync state update
            s_vsync       <= s_vsync_next;
            r_vsync_count <= r_vsync_count;
            r_vsync       <= r_vsync_next;
        end

    
    

endmodule