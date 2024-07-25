/*
 * This module is used to transform addresses 
 * VGA to QVGA only.
 * 
 */
 
module RES_ADDR_TRANSFORM
     (input logic [9:0] in_pixel_x,
      input logic [8:0] in_pixel_y,
      output logic [16:0] out_addr);

    // For multiplication and addition, I think the DSPs are capable of doing everything within
    // a cycle, but if not we would have to pipeline this operation
    // 320 by 240
    

    logic [8:0]    pixel_x_div;
    logic [7:0]    pixel_y_div;
    logic [8:0]    constant_320;
    logic [17:0]   multiply_result;
    logic [18:0]   addition_result;
    
    always_comb
        begin
            constant_320 = 9'd320;
            pixel_x_div = in_pixel_x >> 1;
            pixel_y_div = in_pixel_y >> 1;
            multiply_result = pixel_y_div * constant_320;
            addition_result = multiply_result + pixel_x_div;
        end
    
    // 320 x 240 = 76800, we should never get a result above 76800 so this is safe    
    assign out_addr = addition_result[16:0];

 endmodule