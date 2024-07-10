/*
 * Divides clock by two times the number specified by 'div_by'
 * (defaults to 4)
 */

module CLK_DIV
    #(parameter div_by_x2 = 4)
     (input  logic clk,
      output logic o_clk);

    logic [$clog2(div_by_x2):0] counter = 0;
    logic s_clk = 0;

    always@(posedge clk)
        begin
            if(counter == div_by_x2)
                begin
                    s_clk <= ~s_clk;
                    counter <= 1;
                end
            else
                begin
                    counter <= counter + 1;
                end
        
        end

    assign o_clk = s_clk;

endmodule