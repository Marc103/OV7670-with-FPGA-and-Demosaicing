/*
 * This works for Raw Bayer Format
 * Small FSM, reads each byte and
 * produces the appropriate address to write to video memory.
 */

  module RAW_BAYER #(RESOLUTION_WIDTH = 640, RESOLUTION_HEIGHT = 480)
    (input  logic  [7:0] D,
     input  logic  HREF,
     input  logic  VSYNC,
     input  logic  PCLK,
     output logic  [7:0] raw_bayer,
     output logic  dv,
     output logic  [$clog2(RESOLUTION_WIDTH * RESOLUTION_HEIGHT)-1:0] w_addr
    );

    logic [$clog2(RESOLUTION_WIDTH * RESOLUTION_HEIGHT)-1:0] r_w_addr = 0;
    logic [$clog2(RESOLUTION_WIDTH * RESOLUTION_HEIGHT)-1:0] r_w_addr_next;

    logic r_dv;
    logic r_vsync;
    logic r_href;
    logic r_vsync_next;
    logic r_href_next;
      
    always_comb begin
        r_w_addr_next = r_w_addr;
        
        if(r_vsync == 1) begin
            r_w_addr_next = 0;
        end else begin
            if(r_href == 1) begin
                r_w_addr_next = r_w_addr + 1;
            end
        end

        
    end
    always@(posedge PCLK) begin
        r_href <= HREF;
        r_vsync <= VSYNC;
        r_w_addr <= r_w_addr_next;
        r_dv <= HREF;
        
    end
    
    assign raw_bayer = D;
    assign dv      = r_dv;
    assign w_addr  = r_w_addr;

endmodule