/*
 * Multiplex the 4 by 7 seg displays
 * Cycles per Display (CPD)
 * refresh period = 1 ms to 16 ms
 * digit period = refresh / 4
 * taking refresh period = 1 ms
 * 0.25 ms digit period
 * for a 100Mhz clock, that equates to 25000 cycles
 * from basys 3 reference manual : "to illuminate a segment, the anode should 
 * be driven high while the cathode is driven low. However, since 
 * the Basys 3 uses transistors to drive enough current into the 
 * common anode point, the anode enables are inverted. Therefore, 
 * both the AN0..3 and the CA..G/DP signals are driven low when active."

 */

 module SEGMENT_DRIVER_4_7
   #(parameter CPD = 25000) 
    (
        input  logic clk, 
        input  logic [15:0] binary_num,
        output logic AN3,
        output logic AN2,
        output logic AN1,
        output logic AN0,
        output logic CA,
        output logic CB,
        output logic CC,
        output logic CD,
        output logic CE,
        output logic CF,
        output logic CG,
        output logic DP // default to 0.
    );

    logic [$clog2(CPD):0] counter = 0;

    parameter s_AN3 = 2'b00;
    parameter s_AN2 = 2'b01;
    parameter s_AN1 = 2'b10;
    parameter s_AN0 = 2'b11;


    logic [1:0] state       = s_AN3; 
    logic [1:0] next_state  = s_AN3;

    logic [3:0] multiplexed_binary;

    Binary_To_7Segment Bt7 (.i_Binary_Num(multiplexed_binary),
                           .o_Segment_A(CA),
                           .o_Segment_B(CB),
                           .o_Segment_C(CC),
                           .o_Segment_D(CD),
                           .o_Segment_E(CE),
                           .o_Segment_F(CF),
                           .o_Segment_G(CG));



    always_comb
        begin
            AN3 = 1'b1;
            AN2 = 1'b1;
            AN1 = 1'b1;
            AN0 = 1'b1;
            multiplexed_binary = 4'b1111;
            case(state)
                s_AN3:
                    begin
                        multiplexed_binary = binary_num[15:12];
                        AN3 = 1'b0;
                    end
                s_AN2:
                    begin
                        multiplexed_binary = binary_num[11:8];
                        AN2 = 1'b0;
                    end
                s_AN1:
                    begin
                        multiplexed_binary = binary_num[7:4];
                        AN1 = 1'b0;
                    end
                s_AN0:
                    begin
                        multiplexed_binary = binary_num[3:0];
                        AN0 = 1'b0;
                    end
            endcase
        end



    always@(posedge clk)
        begin
            if(counter == CPD)
                begin
                    counter <= 0;
                    case(state)
                        s_AN3:
                            begin
                                next_state <= s_AN2;
                            end
                        s_AN2:
                            begin
                                next_state <= s_AN1;
                            end
                        s_AN1:
                            begin
                                next_state <= s_AN0;
                            end
                        s_AN0:
                            begin
                                next_state <= s_AN3;
                            end
                    endcase
                end
            else
                begin
                    counter <= counter + 1;
                end
            state <= next_state;

        end





endmodule