/*
 * This works for RGB formats that fit in two bytes
 * i.e RGB 444, RGB 565
 * Small FSM, deserializes (every two bytes) to produce 
 * rgb generic.
 * also produces the appropriate address to write to video memory.
 * including separate x and y position of pixel (for use in transformations)
 */

  module RGB_GENERIC #(RESOLUTION_WIDTH = 640, RESOLUTION_HEIGHT = 480)
    (input  logic  [7:0] D,
     input  logic  HREF,
     input  logic  VSYNC,
     input  logic  PCLK,
     output logic  [15:0] o_RGB_generic,
     output logic  DV,
     output logic  [$clog2(RESOLUTION_WIDTH * RESOLUTION_HEIGHT)-1:0] w_addr,
     output logic  [$clog2(RESOLUTION_WIDTH)-1:0] pixel_x,
     output logic  [$clog2(RESOLUTION_HEIGHT)-1:0] pixel_y
    );

    parameter s_BYTE_0 = 1'b0;
    parameter s_BYTE_1 = 1'b1;
    
    logic        s_href = 1'b0;
    logic        s_href_next = 1'b0;

    logic [$clog2(RESOLUTION_WIDTH)-1:0] r_href_count;
    logic [$clog2(RESOLUTION_WIDTH)-1:0] r_href_count_next;

    logic        s_vsync = 1'b0;
    logic        s_vsync_next = 1'b0;

    logic [$clog2(RESOLUTION_HEIGHT)-1:0] r_vsync_count;
    logic [$clog2(RESOLUTION_HEIGHT)-1:0] r_vsync_count_next;

    logic s_byte = s_BYTE_1;
    logic s_byte_next = s_BYTE_1;

    logic [15:0] r_pixel_data;
    logic [15:0] r_pixel_data_next;

    logic r_DV = 1'b0;
    logic r_DV_next = 1'b0;

    logic [$clog2(RESOLUTION_WIDTH * RESOLUTION_HEIGHT)-1:0] r_w_addr = 0;
    logic [$clog2(RESOLUTION_WIDTH * RESOLUTION_HEIGHT)-1:0] r_w_addr_next = 0;

    logic [$clog2(RESOLUTION_WIDTH)-1:0] pixel_x;
    logic [$clog2(RESOLUTION_HEIGHT)-1:0] pixel_y; 

    // HREF 
    always_comb
        begin
            s_href_next       = HREF;
            s_byte_next       = s_BYTE_0;
            r_pixel_data_next = 0;
            r_DV_next         = 1'b0;
            r_href_count_next = 0;

            // Posedge detection of HREF (Start)
            if((s_href == 1'b0) && (HREF == 1'b1))
                begin
                    r_pixel_data_next[15:8] = D;
                    s_byte_next             = s_BYTE_1;
                    r_DV_next               = 1'b0;
                    r_href_count_next       = 0;

                end

            // HREF high
            else if(s_href == 1'b1)
                begin
                    case(s_byte)
                        s_BYTE_0:
                            begin
                                r_pixel_data_next[15:8] = D;
                                s_byte_next             = s_BYTE_1;
                                r_DV_next               = 1'b0;
                                r_href_count_next       = r_href_count + 1;
                            end
                        s_BYTE_1:
                            begin
                                r_pixel_data_next[7:0]  = D;
                                s_byte_next             = s_BYTE_0;
                                r_DV_next               = 1'b1;
                                r_href_count_next       = r_href_count;   
                            end
                    endcase 
                end

            // Negedge detection of HREF or HREF low
            else if (((s_href == 1'b1) && (HREF == 1'b0)) || (s_href == 1'b0))
                begin
                    s_byte_next       = s_BYTE_0;
                    r_pixel_data_next = 0;
                    r_DV_next         = 1'b0;
                    r_href_count_next = 0;
                end
        end

    // VSYNC 
    always_comb
        begin
            s_vsync_next = VSYNC;
            r_w_addr_next = 0;
            r_vsync_count_next = 0;

            // Negedge detection of VSYNC
            if((s_vsync == 1'b1) && (VSYNC == 1'b0))
                begin
                    r_vsync_count_next = 0;
                    r_w_addr_next = 0;
                end

            // VSYNC low
            else if(s_vsync == 1'b0)
                begin
                    r_vsync_count_next = r_vsync_count;
                    r_w_addr_next = r_w_addr;

                    // Posedge detection of HREF (Start)
                    if((s_href == 1'b0) && (HREF == 1'b1))
                        begin
                            r_w_addr_next = r_w_addr;
                        end

                    // HREF high
                    else if(s_href == 1'b1)
                        begin
                            r_vsync_count_next = r_vsync_count;
                            
                            case(s_byte)
                                s_BYTE_0:
                                    begin
                                        r_w_addr_next = r_w_addr + 1;
                                    end
                                s_BYTE_1:
                                    begin
                                        r_w_addr_next = r_w_addr;
                                    end
                            endcase

                        end

                    // Negedge detection of HREF 
                    if ((s_href == 1'b1) && (HREF == 1'b0))
                        begin
                            r_w_addr_next = r_w_addr + 1;
                            r_vsync_count_next = r_vsync_count + 1;
                        end
                    // HREF low
                    else if(HREF == 1'b0)
                        begin
                            r_w_addr_next = r_w_addr;
                            r_vsync_count_next = r_vsync_count;
                        end
                    
                end

            // Posedge detection of VSYNC or VSYNC high
            else if (((s_vsync == 1'b0) && (VSYNC == 1'b1)) || (s_vsync == 1'b1))
                begin
                    r_w_addr_next = r_w_addr;
                    r_vsync_count_next = r_vsync_count;
                end
            

        end


    always@(posedge PCLK)
        begin
            s_href        <= s_href_next;
            r_href_count  <= r_href_count_next;
            s_vsync       <= s_vsync_next;
            r_vsync_count <= r_vsync_count_next;
            s_byte        <= s_byte_next;
            r_pixel_data  <= r_pixel_data_next;
            r_DV          <= r_DV_next;
            r_w_addr      <= r_w_addr_next;
        end
    
    assign o_RGB_generic = r_pixel_data;
    assign DV      = r_DV;
    assign w_addr  = r_w_addr;
    assign pixel_x = r_href_count;
    assign pixel_y = r_vsync_count;

endmodule