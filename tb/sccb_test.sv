/*
 * Basically the top module ports with clk added
 * The idea being to drive the relevant input ports and wire them for the DUT 
 * 
 *
 */


// timescale <time_unit>/<time_precision>
`timescale 1ns / 1ps 

module TESTBENCH_FRAME();
    
    logic clk;
    logic        w_usher = 1'b1;
    logic [7:0]  w_address = 8'h43;
    logic [7:0]  w_subaddress = 8'h21;
    logic [7:0]  w_data = 8'hab;
    logic [1:0]  w_mode = 2'b00;
    
    logic [3:0] w_state;
    logic [15:0] w_counter;

    logic w_busy;

    wire w_io_sda;
    
    logic w_o_scl;

    SCCB sccb_dut (.clk(clk),
                   .i_usher(w_usher),
                   .i_address(w_address),
                   .i_subaddress(w_subaddress),
                   .i_data(w_data),
                   .i_mode(w_mode),
                   
                   .o_busy(w_busy),
                   
                   .io_sda(w_io_sda),
                   .o_scl(w_o_scl),
                   .d_state(w_state));

    initial begin
        clk = 0; 
        forever 
            begin
                #1 clk = ~clk;
            end 
    end

    initial begin
        #10;
        w_usher = 1'b0;
        #20000;
        w_mode = 2'b01;
        #1;
        w_usher = 1'b1;
        #10;
        w_usher = 1'b0;
        #20000;
        w_mode = 2'b11;
        #1;
        w_usher = 1'b1;
        #10;
        w_usher = 1'b0;

    end

    
endmodule