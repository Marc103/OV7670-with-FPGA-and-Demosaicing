/*
 * SCCB for two wire model, see SCCB documentation
 *
 * 'i_mode':
 * 00 - 3 phase Write
 * 01 - 2 phase Write
 * 11 - 2 phase Read
 *
 *  'o_busy'
 * 0 - no transmission currently happening
 * 1 - transmission currently happening
 *
 * Once all the appropriate inputs have been set, set 'i_usher' to 1 for at least one cycle,
 * this will register the inputs and begin the transmission process,
 * meaning, the input doesn't have to stay constant until finish of transmission.
 * 
 * set PRESCALER to clk frequency / (target frequency of i2c * 2)
 */
module SCCB
#(
    parameter PRESCALE = 4
)
(
    input clk,

     /*
      * Host interface
      */
    input  logic        i_usher,
    input  logic [7:0]  i_address,
    input  logic [7:0]  i_subaddress,
    input  logic [7:0]  i_data,
    input  logic [1:0]  i_mode,
    input  logic [15:0] i_prescaler,
    
    output logic busy,
    
     /*
      * Device interface
      */
    inout  logic io_sda,
    output logic  o_scl,

);

    // SCL state
    logic        r_scl;
    logic [15:0] r_scl_counter;
    logic        r_scl_en;

    logic        r_scl_next;
    logic [15:0] r_scl_counter_next;
    logic        r_scl_en_next;
    
    // SDA state
    logic r_sda_en;
    logic r_sda_tx;

    logic r_sda_en_next;
    logic r_sda_tx_next;



    // Prescale clock logic, when disabled clock must stay high
    always_comb
        begin
            r_scl_next = 1'b1;
            r_scl_counter_next = 0;

            if(r_scl_en)
                begin
                    if(r_scl_counter == (PRESCALE - 1))
                        begin
                            r_scl_next = ~r_scl;
                            r_scl_counter_next = 0;
                        end
                    else
                        r_scl_next = r_scl;
                        r_scl_counter_next = r_scl_counter + 1;
                end
        end
    
    
    
    


    


    assign io_sda = r_sda_en ? r_sda_tx : 1'bz;
    assign  o_scl = r_scl;




endmodule