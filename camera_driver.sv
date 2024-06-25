/*
This is the OV7670 Camera driver module and follows "Figure 2 Functional Block Diagram"
in the OV7670 datasheet. The physical pins on the camera may differ:
SCL  <-> SIO_C
SDA  <-> SIO_D
HS   <-> HREF
VS   <-> VREF
MCLK <-> XCLK
*/

module OV7670_CAMERA_DRIVER
    (input  clk,
     input  reset_,
     output XCLK,
     
     output RESET#,
     output PWDN,
     
     output SIO_C,
     inout  SIO_D,

     input  rx_d,
     output tx_d,
     input  [7:0] tx_byte,
     output [7:0] rx_byte,

     
     input STROBE,
     input HREF,
     input PCLK,
     input VSYNC,
     input [7:0] D
     );

    // OE is active on LOW
    reg OE = 0;

    phase_states_t phase_state = IDLE;
    transmission_states_t transmission_state = IDLE;
    reg [3:0] bit_index = 7;

    always@(*)
        begin
            // Default values
            OE = 1'b1;
            tx_d = 1'b0;

            case(phase_state):
                IDLE:
                    begin

                    end
                PHASE_1:
                    begin

                    end
                PHASE_2_SA:
                    begin

                    end
                PHASE_2_RD:
                    begin

                    end
                PHASE_3_WD:
                    begin

                    end
            
                default:
                    begin
                    end
            endcase

            case(transmission_state):
                IDLE:
                    begin
                    end
                START:
                    begin
                    end
                DATA:
                    begin
                    end
                RW_:
                    begin
                    end
                X:
                    begin
                    end
                STOP:
                    begin
                    end
                
                default:
                    begin
                    end
            endcase
                


        end



    // Tri-state buffer
    // active LOW
    assign SIO_D = OE ? 1'bZ : TX_D;
    assign RX_D = SIO_D;

    always@(posedge CLK)
        begin
            if(~reset_) begin

            end
            else
        end




endmodule