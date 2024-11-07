`ifndef _PIXEL_DATA_INTERFACE_SVH
    `define _PIXEL_DATA_INTERFACE_SVH

/**
 * This interface is a generic internal interface carrying pixel information.
 */
interface pixel_data_interface #(
    // We make the fixed point format a part of the interface parameters so that pixel format can
    // be deduced at synthesis time.

    // Integer bits dedicated to the fixed point representation of a pixel
    parameter FP_M = 8,

    // Fractional bits dedicated to the fixed point representation of a pixel
    parameter FP_N = 0,

    // Sign bits. Should be 0 or 1.
    parameter FP_S = 0
) (
    input clk
);
    // actual pixel data
    logic [(FP_M + FP_N + FP_S - 1):0] pixel;

    // high whenever bus holds valid data.
    logic valid;

    // coordinates.
    logic [15:0] row;
    logic [15:0] col;

    modport writer(input clk, input pixel, input valid, input row, input col);
    modport reader(input clk, output pixel, output valid, output row, output col);
endinterface

`endif