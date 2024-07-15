/*
 * Small FSM, deserializes (every two bytes) to produce 
 * rgb 565.
 * also produces the appropriate address to write to video memory.
 * RGB 565 expected in format xR GB
 * see Figure 13, RGB 565 Output Timing Diagram, in the ov7670 datasheet
 */

  module RGB_565 #(DEPTH = 256)
    (input  logic  [7:0] D,
     input  logic  HREF,
     input  logic  VSYNC,
     input  logic  PCLK,
     output logic  [15:0] RGB_565,
     output logic  DV,
     output logic  [$clog2(DEPTH)-1:0] w_addr );

    parameter s_RUNNING = 1'b0;
    parameter s_STOPPED = 1'b1;

    parameter s_BYTE_0 = 1'b0;
    parameter s_BYTE_1 = 1'b1;
    
    logic        s_href = 1'b0;
    logic        s_href_next = 1'b0;

    logic        s_vsync = 1'b0;
    logic        s_vsync_next = 1'b0;

    logic s_status = s_STOP;
    logic s_status_next = s_STOP;

    logic s_byte = s_BYTE_1;
    logic s_byte_next = s_BYTE_1;

    logic [15:0] r_pixel_data;
    logic [15:0] r_pixel_data_next;

    logic r_DV = 1'b0;
    logic r_DV_next = 1'b0;

    logic [$clog2(DEPTH)-1:0] r_w_addr = 0;
    logic [$clog2(DEPTH)-1:0] r_w_addr_next = 0;

    assign RGB_565 = r_pixel_data;
    assign DV      = r_DV;


    always_comb
        begin
            s_href_next       = 1'b0;
            s_vsync_next      = 1'b0;
            s_status_next     = s_STOP;
            s_byte_next       = s_BYTE_1;
            r_pixel_data_next = 16'h00;
            r_DV_next         = 1'b0;
            r_w_addr_next     = 1'b0;

            // Posedge detection of HREF (Start)
            if( (s_href == 1'b0) && (HREF == 1'b1) )
                begin
                    // consume byte 0
                    r_pixel_data_next[15:8] = D;
                    // since byte 0 will be consumed, we set state to second byte
                    s_byte_next = s_BYTE_1:

                    // set to running state
                    s_status_next = s_RUNNING;

                    s_href_next = HREF;
                end
            // Negedge detection of HREF (Reset)
            else if ( (s_href == 1'b1) && (HREF == 1'b0) ) 
                begin
                    
                    
                    // set to stop state
                    s_status_next  = s_STOPPED;

                    s_href_next    = HREF;
                end
            else
                begin
                    if(s_status == RUNNING)
                        begin
                            case(s_byte)
                                s_BYTE_0:
                                    r_pixel_data_next[15:8] = D;
                                    s_byte_next             = s_BYTE_1;
                                    r_w_addr_next           = r_w_addr + 1;
                                    r_DV_next               = 1'b0;
                                s_BYTE_1:
                                    r_pixel_data_next[7:0]  = D;
                                    s_byte_next             = s_BYTE_0;
                                    r_DV_next               = 1'b1;        
                            endcase
                        end

                    s_href_next = HREF;
                end


            // Posedge detection of VSYNC (Reset, frame complete)
            else if ( (s_vsync == 1'b1) && (VSYNC == 1'b0) )
                begin
                    r_w_addr_next = 0;
                    s_vsync_next  = VSYNC;
                end
            else 
                begin
                    s_vsync_next  = VSYNC;
                end

        end


    always@(posedge PCLK)
        begin
            s_href       <= s_href_next;
            s_vsync      <= s_vsync_next;
            s_status     <= s_status_next;
            s_byte       <= s_byte_next;
            r_pixel_data <= r_pixel_data_next;
            r_DV         <= r_DV_next;
            r_w_addr     <= r_w_addr_next;
        end

endmodule