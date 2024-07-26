module OV7670_SIM 
    #(parameter RESOLUTION_WIDTH  = 640,
      parameter RESOLUTION_HEIGHT = 480,
      parameter BYTES_PER_PIXEL = 2,
      parameter H_FP   = 16,
      parameter H_SYNC = 96,
      parameter H_BP   = 48,
      parameter V_FP   = 10,
      parameter V_SYNC = 2,
      parameter V_BP   = 29)

    (input logic         pclk,
     output logic        hsync,
     output logic        vsync,
     output logic        href,
     output logic [7:0]  D
     
     );
    
    parameter [1:0] FP     = 2'b00;
    parameter [1:0] SYNC   = 2'b01;
    parameter [1:0] BP     = 2'b11;
    parameter [1:0] ACTV   = 2'b10; // active

    // Image, to be initialized with readmem
    logic [7:0] image [$clog2(RESOLUTION_WIDTH * BYTES_PER_PIXEL * RESOLUTION_HEIGHT):0];

    // address state 
    logic [$clog2(RESOLUTION_WIDTH * BYTES_PER_PIXEL * RESOLUTION_HEIGHT):0]  r_r_addr;
    logic [$clog2(RESOLUTION_WIDTH * BYTES_PER_PIXEL * RESOLUTION_HEIGHT):0]  r_r_addr_next;

    // hsync state
    logic [1:0]                                                                     s_hsync            = FP;
    logic                                                                           r_hsync            = 1'b1;
    logic [$clog2(H_FP + H_SYNC + H_BP + (RESOLUTION_WIDTH * BYTES_PER_PIXEL)):0]   r_hsync_count      = 0;
    
    logic [2:0]                                                                     s_hsync_next       = FP;
    logic                                                                           r_hsync_next       = 1'b1;
    logic [$clog2(H_FP + H_SYNC + H_BP + (RESOLUTION_WIDTH * BYTES_PER_PIXEL)):0]   r_hsync_count_next = 0;

    // href state
    logic r_href;
    logic r_href_next;

    // D state
    logic [7:0] r_D;

    // vsync state
    logic [1:0]                                                 s_vsync            = FP;
    logic                                                       r_vsync            = 1'b1;
    logic [$clog2(V_FP + V_SYNC + V_BP + RESOLUTION_HEIGHT):0]  r_vsync_count      = 0; 
    
    logic [2:0]                                                 s_vsync_next       = FP;
    logic                                                       r_vsync_next       = 1'b1;
    logic [$clog2(V_FP + V_SYNC + V_BP + RESOLUTION_HEIGHT):0]  r_vsync_count_next = 0;

    // Hsync and Href
    always_comb
        begin
            case(s_hsync)
                FP:
                    begin
                        r_hsync_next = 1'b1;
                        r_hsync_count_next = r_hsync_count + 1;
                        r_vsync_count_next = r_vsync_count;
                        r_href_next = 1'b0;

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
                        r_href_next = 1'b0;

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
                        r_href_next = 1'b0;

                        if(r_hsync_count == (H_FP + H_SYNC + H_BP - 1)) begin
                        s_hsync_next = ACTV;
                        r_hsync_next = 1'b1;
                        
                        if(s_vsync == ACTV)r_href_next = 1'b1;
                        else r_href_next = 1'b0;
                        
                        end else s_hsync_next = BP;

                        
                    end
                
                ACTV:
                    begin
                        r_hsync_next = 1'b1;
                        r_hsync_count_next = r_hsync_count + 1;
                        r_vsync_count_next = r_vsync_count;
                        
                        if(s_vsync == ACTV)r_href_next = 1'b1;
                        else r_href_next = 1'b0;

                        if(r_hsync_count == (H_FP + H_SYNC + H_BP + (RESOLUTION_WIDTH * BYTES_PER_PIXEL) - 1)) 
                            begin

                                s_hsync_next = FP;
                                r_hsync_next = 1'b1;
                                r_hsync_count_next = 0;
                                r_href_next = 1'b0;

                                if(r_vsync_count == (V_FP + V_SYNC + V_BP + (RESOLUTION_HEIGHT * BYTES_PER_PIXEL) - 1))
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

    // Address
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
    end
        
    
    always@(negedge pclk)
        begin
            // address state update
            r_r_addr = r_r_addr_next;

            // D state update
            r_D           <= image[r_r_addr];

            // hsync and href state update
            s_hsync       <= s_hsync_next;
            r_hsync       <= r_hsync_next;
            r_hsync_count <= r_hsync_count_next;
            r_href        <= r_href_next;     

            // vsync state update
            s_vsync       <= s_vsync_next;
            r_vsync       <= r_vsync_next;
            r_vsync_count <= r_vsync_count_next;

        end
        
    assign hsync = r_hsync;
    assign href  = r_href;
    assign vsync = ~r_vsync;
    assign D     = r_D;

endmodule