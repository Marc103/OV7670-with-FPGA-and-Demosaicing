/*
 * Small FSM, deserializes (every two bytes) to produce 
 * rgb 565.
 * also produces the appropriate address to write to video memory.
 * RGB 565 expected in format xR GB
 * see Figure 13, RGB 565 Output Timing Diagram, in the ov7670 datasheet
 */

  module RGB_565
    (input  logic  [7:0] D,
     input  logic  HREF,
     input  logic  VSYNC,
     input  logic  PCLK,
     output logic  [15:0] o_RGB_565);

    parameter s_RUN = 1'b0;
    parameter s_STOP = 1'b1;

    parameter s_BYTE_0 = 1'b0;
    parameter s_BYTE_1 = 1'b1;
    
    logic       s_href = 0;
    logic [8:0] s_row_idx = 0;
    logic       s_vsync = 0;;


    always@(posedge PCLK)
        begin
            // Posedge detection of HREF
            if( (HREF == 1'b1) && (s_href == 1'b0) )
                begin

                    s_href <= HREF;
                end
            else
                begin
                    s_href <= HREF;
                end
            
            // Negedge detection of VSYNC
            if( (VSYNC == 1'b0) && (s_vsync == 1'b1) )
                begin

                    s_vsync <= VSYNC;
                end
            else
                begin
                
                    s_vsync <= VSYNC;
                end

        end
endmodule