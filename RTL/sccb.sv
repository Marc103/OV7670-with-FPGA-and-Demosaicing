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
    parameter PRESCALE = 125,
    parameter T_PRC_CYCLES = 75
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
    
    output logic        o_busy,
    output logic [7:0]  o_data,
    
     /*
      * Device interface
      */
    inout  logic io_sda,
    output logic  o_scl,
    output logic [3:0] d_state
);
    parameter [3:0] START             = 4'h0;
    parameter [3:0] ADDRESS_BYTE      = 4'h1;
    parameter [3:0] SUBADDRESS_BYTE   = 4'h2;
    parameter [3:0] TX_BYTE           = 4'h3;
    parameter [3:0] RX_BYTE           = 4'h4;
    parameter [3:0] DONT_CARE_A       = 4'h5;
    parameter [3:0] DONT_CARE_B       = 4'h6;
    parameter [3:0] DONT_CARE_C       = 4'h7;
    parameter [3:0] STOP              = 4'h8; 
    parameter [3:0] IDLE              = 4'h9;

    parameter [1:0] WR_3_PHASE = 2'b00;
    parameter [1:0] WR_2_PHASE = 2'b01;
    parameter [1:0] RD_2_PHASE = 2'b11;

    // Transmission state
    logic [3:0]  s_transmission;
    logic        r_usher;
    logic [7:0]  r_address;
    logic [7:0]  r_subaddress;
    logic [7:0]  r_data;
    logic [1:0]  r_mode;
    logic [2:0]  r_bit_index;
    logic [7:0]  r_rx_data;
    

    logic [3:0]  s_transmission_next;
    logic        r_usher_next;
    logic [7:0]  r_address_next;
    logic [7:0]  r_subaddress_next;
    logic [7:0]  r_data_next;
    logic [1:0]  r_mode_next;
    logic [2:0]  r_bit_index_next;
    logic [7:0]  r_rx_data_next;


    // SCL state
    logic        r_scl;
    logic [15:0] r_clock_counter;

    logic        r_scl_next;
    logic [15:0] r_clock_counter_next;

    
    // SDA state
    logic r_sda_rx;

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
            r_usher_next         = r_usher;
            r_address_next       = r_address;
            r_subaddress_next    = r_subaddress;
            r_data_next          = r_data;
            r_mode_next          = r_mode;
            r_bit_index_next     = 8'd7;
            r_rx_data_next       = r_rx_data;

            case(s_transmission)

                IDLE:
                    begin
                        r_clock_counter_next = 0;
                        r_usher_next         = i_usher;

                        // When changing to START state, need to set
                        // sda to 1 and en to 1
                        // register all inputs
                        if(r_usher == 1'b1)
                            begin
                                r_sda_en_next        = 1'b1;
                                r_sda_tx_next        = 1'b1;

                                s_transmission_next = START;
                                r_address_next      = i_address;
                                r_subaddress_next   = i_subaddress;
                                r_data_next         = i_data;
                                r_mode_next         = i_mode;
                            end
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
                                s_transmission_next = ADDRESS_BYTE;
                            end
                    end
                
                STOP:
                    begin
                        r_sda_en_next        = 1'b1;

                        if(r_clock_counter == (PRESCALE - 1))
                            begin
                                r_scl_next = 1'b1;
                            end

                        // set sda to high
                        if(r_clock_counter == ((PRESCALE * 2) - 1))
                            r_sda_tx_next = 1'b1;

                        // After clock returns high, wait t_prc (which is the same as t_psc) cycles
                        if(r_clock_counter == ((PRESCALE * 2) + T_PRC_CYCLES - 1))
                            begin
                                r_clock_counter_next = 0;
                                s_transmission_next = IDLE;
                                r_usher_next         = i_usher;
                            end
                            
                    end

                ADDRESS_BYTE:
                    begin
                        r_bit_index_next     = r_bit_index;
                        r_sda_en_next        = 1'b1;
                        r_sda_tx_next        = r_address[r_bit_index];

                        if(r_clock_counter == (PRESCALE - 1))
                            r_scl_next = 1'b1;

                        if(r_clock_counter == ((PRESCALE * 2) - 1))
                            begin
                                r_scl_next           = 1'b0;
                                r_bit_index_next     = r_bit_index - 1;
                                r_clock_counter_next = 0;

                                if(r_bit_index == 8'd0)
                                    s_transmission_next = DONT_CARE_A;
                            end
                    end

                SUBADDRESS_BYTE:
                    begin
                        r_bit_index_next     = r_bit_index;
                        r_sda_en_next        = 1'b1;
                        r_sda_tx_next        = r_subaddress[r_bit_index];

                        if(r_clock_counter == (PRESCALE - 1))
                            r_scl_next = 1'b1;

                        if(r_clock_counter == ((PRESCALE * 2) - 1))
                            begin
                                r_scl_next           = 1'b0;
                                r_bit_index_next     = r_bit_index - 1;
                                r_clock_counter_next = 0;

                                if(r_bit_index == 8'd0)
                                    s_transmission_next = DONT_CARE_B;
                            end
                    end
                
                TX_BYTE:
                    begin
                        r_bit_index_next     = r_bit_index;
                        r_sda_en_next        = 1'b1;
                        r_sda_tx_next        = r_data[r_bit_index];

                        if(r_clock_counter == (PRESCALE - 1))
                            r_scl_next = 1'b1;

                        if(r_clock_counter == ((PRESCALE * 2) - 1))
                            begin
                                r_scl_next           = 1'b0;
                                r_bit_index_next     = r_bit_index - 1;
                                r_clock_counter_next = 0;

                                if(r_bit_index == 8'd0)
                                    s_transmission_next = DONT_CARE_C;
                            end
                    end
                
                RX_BYTE:
                    begin
                        r_bit_index_next     = r_bit_index;

                        if(r_clock_counter == (PRESCALE - 1))
                            begin
                                r_rx_data_next[r_bit_index] =  r_sda_rx;
                                r_scl_next = 1'b1;
                            end

                        if(r_clock_counter == ((PRESCALE * 2) - 1))
                            begin
                                r_scl_next           = 1'b0;
                                r_bit_index_next     = r_bit_index - 1;
                                r_clock_counter_next = 0;

                                if(r_bit_index == 8'd0)
                                    s_transmission_next = DONT_CARE_C;
                            end
                    end

                DONT_CARE_A:
                    begin
                        r_sda_tx_next        = 1'b0;

                        if(r_clock_counter == (PRESCALE - 1))
                            r_scl_next = 1'b1;

                        if(r_clock_counter == ((PRESCALE * 2) - 1))
                            begin
                                r_scl_next           = 1'b0;
                                r_clock_counter_next = 0;
                                case(r_mode)
                                    WR_3_PHASE:
                                         s_transmission_next = SUBADDRESS_BYTE;
                                    WR_2_PHASE:
                                         s_transmission_next = SUBADDRESS_BYTE;
                                    RD_2_PHASE:
                                         s_transmission_next = RX_BYTE;
                                endcase
                               
                            end
                    end
                
                DONT_CARE_B:
                    begin
                        r_sda_tx_next        = 1'b0;

                        if(r_clock_counter == (PRESCALE - 1))
                            r_scl_next = 1'b1;

                        if(r_clock_counter == ((PRESCALE * 2) - 1))
                            begin
                                r_scl_next           = 1'b0;
                                r_clock_counter_next = 0;
                                case(r_mode)
                                    WR_3_PHASE:
                                        s_transmission_next = TX_BYTE;
                                    WR_2_PHASE:
                                        begin
                                        s_transmission_next = STOP;
                                        r_sda_tx_next = 1'b0;
                                        end
                                    RD_2_PHASE:
                                        begin
                                        s_transmission_next = STOP;
                                        r_sda_tx_next = 1'b0;
                                        end
                                endcase
                               
                            end
                    end
                
                DONT_CARE_C:
                    begin
                        r_sda_tx_next        = 1'b0;

                        if(r_clock_counter == (PRESCALE - 1))
                            r_scl_next = 1'b1;

                        if(r_clock_counter == ((PRESCALE * 2) - 1))
                            begin
                                r_scl_next           = 1'b0;
                                r_clock_counter_next = 0;
                                s_transmission_next  = STOP;
                            end
                    end
                

                default:
                    begin
                        r_scl_next = 1'b1;
                        s_transmission_next = IDLE;
                    end

            endcase

            if(s_transmission != IDLE)
                o_busy = 1'b1;
            else
                o_busy = 1'b0;

        end
    
    always@(posedge clk)
        begin
            s_transmission  <= s_transmission_next;
            r_usher         <= r_usher_next;
            r_address       <= r_address_next;
            r_subaddress    <= r_subaddress_next;
            r_data          <= r_data_next;
            r_mode          <= r_mode_next;
            r_bit_index     <= r_bit_index_next;

            r_scl           <= r_scl_next;
            r_clock_counter <= r_clock_counter_next;

            r_sda_en        <= r_sda_en_next;
            r_sda_tx        <= r_sda_tx_next;
        end
    
    assign io_sda   = r_sda_en ? r_sda_tx : 1'bz;
    assign o_scl    = r_scl;
    assign r_sda_rx = io_sda;
    assign d_state  = s_transmission;
    assign o_data   = r_rx_data;

endmodule