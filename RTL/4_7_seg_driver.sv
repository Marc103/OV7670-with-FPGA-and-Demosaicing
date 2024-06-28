/*
 * Multiplex the 4 by 7 seg displays
 */

 module 4_7_SEGMENT_DRIVER
    (
        input  logic clk, // assumed to be 100 MHz, paramaterize later (todo)
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
        output logic DP, // default to 0.
    );

end module