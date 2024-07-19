/*
 * VGA Timing Circuit: 
 * 640 x 480
 * 60 Hz vertical frequency
 * 25 MHz pixel clock
 * RGB 444 (since the basys 3 vga port supports 4 bits per color channel)
 * 
 * See VGA timing calculations to see how the numbers were derived.
 */

module VGA 
    (input logic         pclk,

     /*
      * Video buffer ports
      */
     input logic  [15:0] r_data,
     input logic         r_dv,
     output logic        r_clk,
     output logic [18:0] r_addr,
     output logic        r_en,

     /*
      * VGA ports
      */
     output logic [3:0]  red_bits,
     output logic [3:0]  green_bits,
     output logic [3:0]  blue_bits,
     output logic        hsync,
     output logic        vsync,
     
     output logic [18:0] d_r_addr
     
     );
    
    assign d_r_addr = r_r_addr;
    
    parameter [1:0] FP   = 2'b00;
    parameter [1:0] SYNC = 2'b01;
    parameter [1:0] BP   = 2'b10;
    parameter [1:0] ACTV = 2'b11; // ACTV stands for active
    
    // address state
    logic [18:0]  r_r_addr;
    logic [18:0]  r_r_addr_next;

    // hsync state
    logic [1:0]   s_hsync            = FP;
    logic [9:0]   r_hsync_count      = 0;
    logic         r_hsync            = 0;
    
    logic [1:0]   s_hsync_next       = FP;
    logic [9:0]   r_hsync_count_next = 0;
    logic         r_hsync_next       = 0;

    // vsync state
    logic [1:0]   s_vsync            = FP;
    logic [18:0]  r_vsync_count      = 0; 
    logic         r_vsync            = 0;
    
    logic [1:0]   s_vsync_next       = FP;
    logic [18:0]  r_vsync_count_next = 0;
    logic         r_vsync_next       = 0;

    // Hsync 
    always_comb
        begin
            case(s_hsync)
                FP:
                    begin
                        r_r_addr_next = r_r_addr;

                        r_hsync_next = 1'b1;
                        r_hsync_count_next = r_hsync_count + 1;

                        if(r_hsync_count == 10'd18) begin
                        s_hsync_next = SYNC;
                        r_hsync_next = 1'b0;
                        end else s_hsync_next = FP;
                    end
                SYNC:
                    begin
                        r_r_addr_next = r_r_addr;

                        r_hsync_next = 1'b0;
                        r_hsync_count_next = r_hsync_count + 1;

                        if(r_hsync_count == 10'd111) begin
                        s_hsync_next = BP;
                        r_hsync_next = 1'b1;
                        end else s_hsync_next = SYNC;
                    end
                BP:
                    begin
                        r_r_addr_next = r_r_addr;

                        r_hsync_next = 1'b1;
                        r_hsync_count_next = r_hsync_count + 1;

                        if(r_hsync_count == 10'd159) begin
                        s_hsync_next = ACTV;
                        r_hsync_next = 1'b1;
                        end else s_hsync_next = BP;
                    end
                
                ACTV:
                    begin
                        if( (s_vsync != ACTV) || (s_vsync_next != ACTV))
                        r_r_addr_next = 0;
                        else
                        r_r_addr_next = r_r_addr + 1;

                        r_hsync_next = 1'b1;
                        r_hsync_count_next = r_hsync_count + 1;

                        if(r_hsync_count == 10'd799) begin
                        s_hsync_next = FP;
                        r_hsync_next = 1'b1;
                        r_hsync_count_next = 0;
                        end else s_hsync_next = ACTV;
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
                        r_vsync_count_next = r_vsync_count + 1;

                        if(r_vsync_count == 19'd7999) begin
                        s_vsync_next = SYNC;
                        r_vsync_next = 1'b0;
                        end else s_vsync_next = FP;
                    end
                SYNC:
                    begin
                        r_vsync_next = 1'b0;
                        r_vsync_count_next = r_vsync_count + 1;

                        if(r_vsync_count == 19'd9599) begin
                        s_vsync_next = BP;
                        r_vsync_next = 1'b1;
                        end else s_vsync_next = SYNC;
                    end
                BP:
                    begin
                        r_vsync_next = 1'b1;
                        r_vsync_count_next = r_vsync_count + 1;

                        if(r_vsync_count == 19'd32799) begin
                        s_vsync_next = ACTV;
                        r_vsync_next = 1'b1;
                        end else s_vsync_next = BP;
                    end
                
                ACTV:
                    begin
                        r_vsync_next = 1'b1;
                        r_vsync_count_next = r_vsync_count + 1;

                        if(r_vsync_count == 19'd416799) begin
                        s_vsync_next = FP;
                        r_vsync_next = 1'b1;
                        r_vsync_count_next = 0;
                        end else s_vsync_next = ACTV;
                    end
            endcase
            
            
        end

    always_comb
        begin
            if((s_hsync == ACTV) && (s_vsync == ACTV))
                begin
                    if(r_r_addr[2] == 0) 
                    blue_bits = 4'hf;
                    else blue_bits = 4'h0;
                    red_bits = 4'h0;
                    green_bits = 4'h0;
                end
            else
                begin
                    red_bits = 4'h0;
                    green_bits = 4'h0;
                    blue_bits = 4'h0;
                end
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
            r_vsync_count <= r_vsync_count_next;
            r_vsync       <= r_vsync_next;
        end
    
    
    assign hsync = r_hsync;
    assign vsync = r_vsync;

endmodule