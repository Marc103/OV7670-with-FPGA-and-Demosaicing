/*
 * Small FSM, deserializes (every two bytes) to produce
 * rgb 444.
 * RGB 444 expected in format xR GB
 * see Figure 13, RGB 444 Output Timing Diagram, in the ov7670 datasheet
 */

 module RGB_444
    (logic input  [7:0] D,
     logic input  HREF,
     logic input PCLK,
     logic output [11:0] o_RGB_444);

    parameter s_RUN = 1'b0;
    parameter s_STOP = 1'b1;

    parameter s_BYTE_0 = 1'b0;
    parameter s_BYTE_1 = 1'b1;
    
    logic s_href = s_STOP;
    logic s_byte = s_BYTE_0;

    logic [3:0] R = 4'h0;
    logic [7:0] GB = 8'h00;

    logic [7:0] temp_R = 4'b0000;

    assign o_RGB_444 = {R,GB} 

    always@(posedge HREF)
        begin
            s_href <= s_RUN;
        end

    always@(negedge HREF)
        begin
            s_href <= s_STOP;
        end

    always@(posedge PCLK)
        begin
            if(s_href == s_RUN)
                begin
                    case(s_byte)
                        s_BYTE_0:
                            begin
                                temp_R <= D[3:0];
                                s_byte <= s_BYTE_1;
                            end
                        s_BYTE_1:
                            begin
                                R <= temp_R;
                                GB <= D;
                                s_byte <= s_BYTE_0;
                            end
                        default:
                            begin
                                R = 4'h0;
                                GB = 8'h00;
                            end
                    endcase
                end
            else
                begin
                    s_byte <= s_BYTE_0;
                end
        end
endmodule