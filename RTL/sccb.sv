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
 * set 'PRESCALER' to clk frequency / (target frequency of i2c * 2)
 *
 * t_prc minimum value is 15ns, at 100 mhz, this results in at least 150 cycles
 * 'T_PRC_CYCLES' must be set to the minimum number of cycles **divided by two**
 *
 */
module SCCB
#(
    parameter PRESCALE = 125
    parameter T_PRC_CYCLES = 75,
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
    parameter [3:0] START             = 4'h0;
    parameter [3:0] ADDRESS_BYTE      = 4'h1;
    parameter [3:0] SUBADDRESS_BYTE   = 4'h2;
    parameter [3:0] TX_BYTE           = 4'h3;
    parameter [3:0] RX_BYTE           = 4'h4;
    parameter [3:0] DONT_CARE_A       = 4'h5;
    parameter [3:0] DONT_CARE_B0      = 4'h5;
    parameter [3:0] DONT_CARE_B1      = 4'h5;
    parameter [3:0] DONT_CARE_C       = 4'h5;
    parameter [3:0] STOP              = 4'h6; 
    parameter [3:0] IDLE              = 4'h7;


    // Transmission state
    logic [2:0]  s_transmission;
    logic [2:0]  r_bit_index;
    

    logic [2:0]  s_transmission_next;
    logic [2:0]  r_bit_index_next;

    // Input state
    
    

    // SCL state
    logic        r_scl;
    logic [15:0] r_clock_counter;

    logic        r_scl_next;
    logic [15:0] r_clock_counter_next;

    
    // SDA state
    logic r_sda_en;
    logic r_sda_tx;

    logic r_sda_en_next;
    logic r_sda_tx_next;

    always_comb
        begin
            r_clock_counter_next = r_clock_counter + 1;
            r_scl_next           = r_scl;
            r_sda_tx_next        = r_sda_tx;
            r_sda_en_next        = 1'b0;
            s_transmission_next  = s_transmission;
            r_bit_index_next     = 8'd0;


            case(s_transmission)
                IDLE:
                    begin
                        r_clock_counter_next = 0;

                        // When changing to START state, need to set
                        // sda to 1 and en to 1
                        r_sda_en_next        = 1'b1;
                        r_sda_tx_next        = 1'b1;
                    end
                START:
                    begin
                        r_sda_en_next        = 1'b1;

                        // Wait t_prc cycles
                        if(r_clock_counter == (T_PRC_CYCLES - 1))
                            r_sda_tx_next = 1'b0;
                        
                        // Wait two prescaled cycle
                        if(r_clock_counter == ((PRESCALE * 2) - 1))
                            begin
                                r_scl_next = 1'b0;
                                r_clock_counter_next = 0;
                                s_transmission_next = BYTE_TX;
                            end
                    end

                ADDRESS_BYTE:
                    begin
                        r_sda_en_next        = 1'b1;
                        r_sda_tx_next = i_address[r_bit_index];

                        if(r_clock_counter == (PRESCALE - 1))
                            r_scl_next = 1'b1;

                        if(r_clock_counter == ((PRESCALE * 2) - 1))
                            begin
                                r_scl_next           = 1'b0;
                                r_bit_index_next     = r_bit_index + 1;
                                r_clock_counter_next = 0;

                                if(r_bit_index == 8'd7)
                                    s_transmission_next = DONT_CARE;
                            end
                    end

                SUBADDRESS_BYTE:
                    begin
                        r_sda_en_next        = 1'b1;
                        r_sda_tx_next = i_subaddress[r_bit_index];

                        if(r_clock_counter == (PRESCALE - 1))
                            r_scl_next = 1'b1;

                        if(r_clock_counter == ((PRESCALE * 2) - 1))
                            begin
                                r_scl_next           = 1'b0;
                                r_bit_index_next     = r_bit_index + 1;
                                r_clock_counter_next = 0;

                                if(r_bit_index == 8'd7)
                                    s_transmission_next = DONT_CARE;
                            end
                    end

                DONT_CARE_A:
                    begin
                        r_sda_en_next        = 1'b1;
                        r_sda_tx_next        = 1'b0;

                        if(r_clock_counter == (PRESCALE - 1))
                            r_scl_next = 1'b1;

                        if(r_clock_counter == ((PRESCALE * 2) - 1))
                            begin
                                r_scl_next           = 1'b0;
                                r_clock_counter_next = 0;
                                s_transmission_next = DONT_CARE;
                            end
                    end

                STOP:
                    begin
                    end

                default:
                    begin
                        r_scl_next = 1'b1;
                    end

            endcase


        end
    
    always_comb
        begin

        end
    
    
    
    


    


    assign io_sda = r_sda_en ? r_sda_tx : 1'bz;
    assign  o_scl = r_scl;




endmodule