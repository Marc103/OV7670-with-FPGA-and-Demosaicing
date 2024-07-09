/*
 * Small FSM, deserializes (every two bytes) to produce
 * rgb 444.
 * RGB 444 expected in format xR GB
 * see Figure 13, RGB 444 Output Timing Diagram, in the ov7670 datasheet
 */

 module RGB_444
    (logic input  [7:0] serial_byte,
     logic input  HREF,
     logic input PCLK,
     logic output [11:0] o_RGB_444);


    parameter s_IDLE = 3'b000;
    parameter s_START = 3'b110;
    parameter s_BYTE_0 = 3'b010;
    parameter s_BYTE_1 = 3'b100;
    parameter s_STOP = 3'b111;

    

    always@(posedge HREF)
        begin
        end
    
    always@(posedge PCLK)
        begin
        end
    



endmodule