/* Convolutional filter
 *
 * using parallel row buffering following 'Design for Embedded Image Processing on FPGAs' 
 * by Donald G. Bailey
 * follows    
 * Q[x,y] = f( I[x,y], ... , I[x + dx, y + dy]),  (dx, dy) in W    
 * terminology in the book in comments
 *
 * 'K_DEPTH' is important for the kernel modules that calculate Q[x,y]
 *  i.e if we simply add all the numbers in the window together in our kernel module,
 * 'K_DEPTH has to be sufficiently large enough to hold the resulting value.
 *
 * conv_entry_lut module is actually synthesizable, however, shift registers are used 
 * in place of the FIFO
 *
 * TODO, add stalling mechanism for constant extension
 * actually, since the window size is expected to be small, we will just calculate the 
 * coordinates within the window to decide whether its out of bounds
 *
 * The stalling mechanism would use scale linearly with the window size, the 'naive' method will
 * scale exponentially in terms of resource use (muxes, adders, comparators) but simplifies the
 * design greatly. Also maybe that's not so bad, in software it takes exponential time to check for
 * each index in the window if it is within bounds, and so instead we parallize the operation by
 * trading the exponential time with exponential amount of resource.
 *
 * Side note, works for kernel window dimenions < roughly double the image dimensions
 *
 * It is assumed that after reset, pixel (0,0) is fed first as an input
 */

////////////////////////////////////////////////////////////////
// Includes
`include "pixel_data_interface.svh"

module conv_net #(
    // We make the fixed point format a part of the interface parameters so that pixel format can
    // be deduced at synthesis time.
    
    // Kernel FP parameters 
    parameter FP_M_KERNEL = 8,
    parameter FP_N_KERNEL = 0,
    parameter FP_S_KERNEL = 0,

    // input image dimensions
    parameter WIDTH = 5,
    parameter HEIGHT = 5,

    // kernel window dimensions
    parameter K_WIDTH = 3,
    parameter K_HEIGHT = 3,

    // Constant extension value
    parameter CONSTANT = 0,

    // how many cycles do we have per pixel (should be < (K_WIDTH * K_HEIGHT))
    parameter CLKS_PER_PIXEL = 1

) ( 
    pixel_data_interface.writer in,
    pixel_data_interface.reader out,
    
    // reset signal
    input rst_n_i,

    // kernel coefficients
    input [FP_M_KERNEL + FP_N_KERNEL + FP_S_KERNEL - 1: 0] kernel_coeffs_i [K_HEIGHT][K_WIDTH],

    // kernel status output (ready or busy, 1 is ready 0 is busy)
    output kernel_status_o
); 
    localparam MID_K_H = K_HEIGHT/2;
    localparam MID_K_W = K_WIDTH/2;

    // State for pipe col and row index
    logic [15:0]   col_pipe = (WIDTH - 1) - MID_K_W;
    logic [15:0]   row_pipe = (HEIGHT - 1) - MID_K_H;

    logic [15:0]   col_pipe_next;
    logic [15:0]   row_pipe_next;

    // Kernel State for cycles per pixel
    localparam READY = 1'b1;
    localparam BUSY = 1'b0;

    logic kernel_state = READY;
    logic kernel_state_next;

    localparam CLKS_MAX = (CLKS_PER_PIXEL > (K_HEIGHT*K_WIDTH)) ? (K_HEIGHT*K_WIDTH) : CLKS_PER_PIXEL;

    logic [$clog2(CLKS_MAX):0] convolution_step = (CLKS_MAX - 1);
    logic [$clog2(CLKS_MAX):0] convolution_step_next;

    // is pipe full?
    logic ispipefull = 0;
    logic ispipefull_next = 0;

    // Data valid wrt to the kernel state
    logic w_dv_i;
    assign w_dv_i = (kernel_state == READY) && (in.valid == 1) ? 1 : 0;
    assign kernel_status_o = kernel_state;

    always@(*) begin
        
        ////////////////////////////////////////////////////////////////
        // Kernel State logic
        kernel_state_next = kernel_state;
        convolution_step_next = convolution_step;

        case(kernel_state)
            READY: begin
                if(in.valid) begin
                    if(CLKS_MAX == 1) begin
                        kernel_state_next = READY;
                        convolution_step_next = 0;
                    end else begin
                        kernel_state_next = BUSY;
                        convolution_step_next = 0;
                    end
                end
            end
            BUSY: begin
                if(convolution_step == (CLKS_MAX - 2)) begin
                    kernel_state_next = READY;
                    convolution_step_next = (CLKS_MAX - 1);
                end else begin
                    kernel_state_next = BUSY;
                    convolution_step_next = convolution_step + 1;
                end
            end
        endcase


        ////////////////////////////////////////////////////////////////
        // Pipe col and row incrementing logic

        row_pipe_next = row_pipe;
        col_pipe_next = col_pipe;

        if(w_dv_i) begin
            row_pipe_next = row_pipe;
            col_pipe_next = col_pipe + 1;

            // sync
            if((in.col == (WIDTH - 1)) && (in.row == (HEIGHT - 1))) begin
                col_pipe_next = (WIDTH - 1) - MID_K_W;
                row_pipe_next = (HEIGHT - 1) - MID_K_H;
            end
            else begin
                if(col_pipe == (WIDTH - 1)) begin
                    col_pipe_next = 0;
                    if(row_pipe == (HEIGHT -1))
                        row_pipe_next = 0;
                    else
                        row_pipe_next = row_pipe + 1;
                end


            end
        end

        ////////////////////////////////////////////////////////////////
        // Is pipe full? 
        ispipefull_next = 0;

        if(ispipefull == 1) begin
            ispipefull_next = 1;
        end else begin
            if((row_pipe == (HEIGHT-1)) && (col_pipe == (WIDTH-1)) && (w_dv_i == 1)) begin
                ispipefull_next = 1;
            end 
        end

        // reset logic
        if(!rst_n_i) begin
            ispipefull_next = 0;
            col_pipe_next = (WIDTH - 1) - MID_K_W;
            row_pipe_next = (HEIGHT - 1) - MID_K_H;
            kernel_state_next = READY;
            convolution_step_next = (CLKS_MAX - 1);
        end 

    end

    always@(posedge in.clk) begin
        ispipefull       <= ispipefull_next;
        row_pipe         <= row_pipe_next;
        col_pipe         <= col_pipe_next;
        kernel_state     <= kernel_state_next;
        convolution_step <= convolution_step_next;
    end

    // Wiring between modules
    logic [(in.FP_M + in.FP_N + in.FP_S -1):0] w_kernel_cel_cr  [K_HEIGHT][K_WIDTH];
    logic [(in.FP_M + in.FP_N + in.FP_S -1):0] w_kernel_cr_ksa  [K_HEIGHT][K_WIDTH];

    conv_entry_fifo #(
        .WIDTH(WIDTH),
        .HEIGHT(HEIGHT),
        .DEPTH(in.FP_M + in.FP_N + in.FP_S),
        .K_WIDTH(K_WIDTH),
        .K_HEIGHT(K_HEIGHT),
        .K_DEPTH(FP_M_KERNEL + FP_N_KERNEL + FP_S_KERNEL)
    ) conv_entry (
        .rst_n_i(rst_n_i),    
        .pclk_i(in.clk),
        .dv_i(w_dv_i),
        .pixel_data_i(in.pixel),
        .kernel_o(w_kernel_cel_cr)
    );

    conv_router #(
        .WIDTH(WIDTH),
        .HEIGHT(HEIGHT),
        .DEPTH(in.FP_M + in.FP_N + in.FP_S),
        .K_WIDTH(K_WIDTH),
        .K_HEIGHT(K_HEIGHT),
        .CONSTANT(CONSTANT)
    ) conv_router (
        .kernel_i(w_kernel_cel_cr),
        .col_i(col_pipe),
        .row_i(row_pipe),
        .kernel_o(w_kernel_cr_ksa)
    );

    kernel_convolution #(
        .FP_M_IMAGE(in.FP_M),
        .FP_N_IMAGE(in.FP_N),
        .FP_S_IMAGE(in.FP_S),
        
        .FP_M_KERNEL(FP_M_KERNEL),
        .FP_N_KERNEL(FP_N_KERNEL),
        .FP_S_KERNEL(FP_S_KERNEL),

        .FP_M_IMAGE_OUT(out.FP_M),
        .FP_N_IMAGE_OUT(out.FP_N),
        .FP_S_IMAGE_OUT(out.FP_S),
        
        .WIDTH(WIDTH),
        .HEIGHT(HEIGHT),
        .K_WIDTH(K_WIDTH),
        .K_HEIGHT(K_HEIGHT),
        .CLKS_PER_PIXEL(CLKS_MAX)
    ) kernel_convolution (
        .ispipefull_i(ispipefull),
        // kernel state
        .kernel_state_i(kernel_state),
        .convolution_step_i(convolution_step),
        // rest
        .kernel_i(w_kernel_cr_ksa),
        .kernel_coeffs_i(kernel_coeffs_i),
        .col_i(col_pipe),
        .row_i(row_pipe),
        .col_o(out.col),
        .row_o(out.row),
        .pixel_data_o(out.pixel),
        .dv_o(out.valid),
        .pclk_i(in.clk),
        .dv_i(w_dv_i)
    );

endmodule

/**
 * This module contains the row buffers and window shift registers
 * it takes in the pixel data and pushes it along.
 * The output is the kernel window of data. It's postfixed with 'lut'
 * because it uses shift registers for the row instead of proper FIFOs
 *
 */

module conv_entry_lut #(
    parameter WIDTH = 320,
    parameter HEIGHT = 240,
    parameter DEPTH = 8,
    parameter K_WIDTH = 3,
    parameter K_HEIGHT = 3,
    parameter K_DEPTH = 8
)  (
    // reset, in this module, no effect
    input                rst_n_i,

    // pixel clock
    input                pclk_i,

    // incoming pixel data
    input  [(DEPTH-1):0] pixel_data_i,
    input                dv_i,

    // outgoing kernel window
    output [(DEPTH-1):0] kernel_o  [K_HEIGHT][K_WIDTH]
);

    localparam MID_K_H = HEIGHT/2;
    localparam MID_K_W = WIDTH/2;

    // Kernel Shift Registers
    logic [(DEPTH-1):0] ksr      [K_HEIGHT][K_WIDTH];
    logic [(DEPTH-1):0] ksr_next [K_HEIGHT][K_WIDTH];

    // Buffer Shift Registers
    // in RTL this should be proper FIFOs (well a shift register implementation can be done too if we need to swap BRAM for LUTs)
    // note that there are K_HEIGHT - 1 buffers required, not K_HEIGHT
    logic [(DEPTH-1):0] bsr      [0:(K_HEIGHT-2)][0:(WIDTH-1)];
    logic [(DEPTH-1):0] bsr_next [0:(K_HEIGHT-2)][0:(WIDTH-1)];

    // Indexing variables 
    integer k_r, k_c;
    integer b_r, b_c;
    integer si;

    always@(*) begin
        ////////////////////////////////////////////////////////////////
        // Kernel Shift Register wiring
        for(k_r = 0; k_r < K_HEIGHT; k_r = k_r + 1) begin
            for(k_c = 0; k_c < K_WIDTH; k_c = k_c + 1) begin
                ksr_next[k_r][k_c] = ksr[k_r][k_c];
            end
        end

        if(dv_i) begin
            // main shift registers
            for(k_r = 0; k_r < K_HEIGHT; k_r = k_r + 1) begin
                for(k_c = 1; k_c < K_WIDTH; k_c = k_c + 1) begin
                    ksr_next[k_r][k_c] = ksr[k_r][k_c - 1];
                end
            end

            // first row first register, pixel data fed here
            ksr_next[0][0] = pixel_data_i;

            // rest of rows's first registers, repsective buffer out fed here
            for(k_r = 1; k_r < K_HEIGHT; k_r = k_r + 1) begin
                ksr_next[k_r][0] = bsr[k_r - 1][WIDTH - 1];
            end
        end
        
        ////////////////////////////////////////////////////////////////
        // Buffer Shift Register wiring
        for(b_r = 0; b_r < (K_HEIGHT - 1); b_r = b_r + 1) begin
            for(b_c = 0; b_c < WIDTH; b_c = b_c + 1) begin
                bsr_next[b_r][b_c] = bsr[b_r][b_c];
            end
        end

        if(dv_i) begin
            // main shift registers
            for(b_r = 0; b_r < (K_HEIGHT - 1); b_r = b_r + 1) begin
                for(b_c = 1; b_c < WIDTH; b_c = b_c + 1) begin
                    bsr_next[b_r][b_c] = bsr[b_r][b_c - 1];
                end
            end

            // first row first register, pixel data fed here
            bsr_next[0][0] = pixel_data_i;

            for(b_r = 1; b_r < (K_HEIGHT - 1); b_r = b_r + 1) begin
                bsr_next[b_r][0] = bsr[b_r - 1][WIDTH - 1];
            end
        end

    end

    always@(posedge pclk_i) begin
        // Kernel Shift Register update
        for(k_r = 0; k_r < K_HEIGHT; k_r = k_r + 1) begin
            for(k_c = 0; k_c < K_WIDTH; k_c = k_c + 1) begin
                ksr[k_r][k_c] <= ksr_next[k_r][k_c];
            end
        end

         // Buffer Shift Register update
        for(b_r = 0; b_r < (K_HEIGHT - 1); b_r = b_r + 1) begin
            for(b_c = 0; b_c < WIDTH; b_c = b_c + 1) begin
                bsr[b_r][b_c] <= bsr_next[b_r][b_c];
            end
        end

    end

    assign kernel_o = ksr;

endmodule

/**
 * This module contains the row buffers and window shift registers
 * it takes in the pixel data and pushes it along.
 * The output is the kernel window of data. It is the appropriate FIFO
 * version of 'conv_entry_lut', hence postfixed with 'fifo'
 *
 */

module conv_entry_fifo #(
    parameter WIDTH = 320,
    parameter HEIGHT = 240,
    parameter DEPTH = 8,
    parameter K_WIDTH = 3,
    parameter K_HEIGHT = 3,
    parameter K_DEPTH = 8
)  (
    // reset
    input rst_n_i,

    // pixel clock
    input                                      pclk_i,

    // incoming pixel data
    input  [(DEPTH-1):0]                       pixel_data_i,
    input                                      dv_i,

    // outgoing kernel window
    output [(DEPTH-1):0] kernel_o  [K_HEIGHT][K_WIDTH]
);

    localparam MID_K_H = HEIGHT/2;
    localparam MID_K_W = WIDTH/2;

    // Kernel Shift Registers
    logic [(DEPTH-1):0] ksr      [K_HEIGHT][K_WIDTH];
    logic [(DEPTH-1):0] ksr_next [K_HEIGHT][K_WIDTH];

    ////////////////////////////////////////////////////////////////
    // Wiring for Row Buffers as synchronous FIFOs
    //
    // note that there are K_HEIGHT - 1 buffers required, not K_HEIGHT
    // It is necessary at the start to separate the read and write pointers
    // by the WIDTH of the image before allowing data to be read out

    // rw pointer separation counter
    logic [$clog2(WIDTH):0] pointer_separation = 0;
    logic [$clog2(WIDTH):0] pointer_separation_next;

    // read
    logic               r_rrst_n      = 1;
    logic               r_rrst_n_next ;
    logic               r_rd          ;
    logic [(DEPTH-1):0] w_rdata       [0:K_HEIGHT-2];
    logic               w_rempty      [0:K_HEIGHT-2];

    // write
    logic               r_wrst_n      = 1;
    logic               r_wrst_n_next ;
    logic               r_wr          ;
    logic [(DEPTH-1):0] w_wdata       [0:K_HEIGHT-2];
    logic               w_wfull       [0:K_HEIGHT-2];

    // Indexing variables
    integer k_r, k_c;
    integer b_r, b_c;

    always@(*) begin
        ////////////////////////////////////////////////////////////////
        // Kernel Shift Register wiring
        for(k_r = 0; k_r < K_HEIGHT; k_r = k_r + 1) begin
            for(k_c = 0; k_c < K_WIDTH; k_c = k_c + 1) begin
                ksr_next[k_r][k_c] = ksr[k_r][k_c];
            end
        end


        if(dv_i) begin
            // main shift registers
            for(k_r = 0; k_r < K_HEIGHT; k_r = k_r + 1) begin
                for(k_c = 1; k_c < K_WIDTH; k_c = k_c + 1) begin
                    ksr_next[k_r][k_c] = ksr[k_r][k_c - 1];
                end
            end

            // first row first register, pixel data fed here
            ksr_next[0][0] = pixel_data_i;

            // rest of rows's first registers, repsective buffer out fed here
            for(k_r = 1; k_r < K_HEIGHT; k_r = k_r + 1) begin
                ksr_next[k_r][0] = w_rdata[k_r - 1];
            end
        end
        

        ////////////////////////////////////////////////////////////////
        // Row Buffer State Control, includes pointer separation

        // logic is,
        // if dv, we can always write
        // if dv, we can only read if pointers are separated by WIDTH
        // if not dv, cant read nor write
        
        pointer_separation_next = pointer_separation;
        r_rd = 0;
        r_wr = 0;

        if(dv_i) begin
            r_wr = 1;

            if(pointer_separation == WIDTH) begin
                r_rd = 1;
            end
            else begin
                pointer_separation_next = pointer_separation + 1;
                r_rd = 0;
            end

        end

        // buffer reset logic, todo
        if(!rst_n_i) begin
            r_rrst_n_next = 0;
            r_wrst_n_next = 0;
            pointer_separation_next = 0;
        end else begin
            r_rrst_n_next = 1;
            r_wrst_n_next = 1;
        end
    end

    always@(posedge pclk_i) begin

        // Kernel Shift Register update
        for(k_r = 0; k_r < K_HEIGHT; k_r = k_r + 1) begin
            for(k_c = 0; k_c < K_WIDTH; k_c = k_c + 1) begin
                ksr[k_r][k_c] <= ksr_next[k_r][k_c];
            end
        end

        // Row Buffer Reset update, most logic is purely combinational
        r_rrst_n <= r_rrst_n_next;
        r_wrst_n <= r_wrst_n_next;

        pointer_separation <= pointer_separation_next;

    end

    ////////////////////////////////////////////////////////////////
    // Buffer Shift Register wiring
    // must be $clog2(WIDTH) + 1 instead of $clog(WIDTH)

    genvar b_row;
    
    generate
        // first buffer entry point
        if(K_HEIGHT > 1) begin
            assign w_wdata[0] = pixel_data_i;

            afifo #(
                .DSIZE(DEPTH),
                .ASIZE($clog2(WIDTH) + 1)
            )  entry_fifo_buffer (
                // write side
                .i_wclk(pclk_i),
                .i_wrst_n(r_wrst_n),
                .i_wr(r_wr),
                .i_wdata(w_wdata[0]),
                .o_wfull(w_wfull[0]),
                // read side
                .i_rclk(pclk_i),
                .i_rrst_n(r_rrst_n),
                .i_rd(r_rd),
                .o_rdata(w_rdata[0]),
                .o_rempty(w_rempty[0])
            );
        end

        // rest of buffer wiring
        for(b_row = 1; b_row < (K_HEIGHT - 1); b_row = b_row + 1) begin

            // i could have done .w_wdata(r_data[previous]) but
            // I think its much more organized to do it this way
            assign w_wdata[b_row] = w_rdata[b_row - 1];

            afifo #(
                .DSIZE(DEPTH),
                .ASIZE($clog2(WIDTH) + 1)
            )  fifo_buffers (
                // write side
                .i_wclk(pclk_i),
                .i_wrst_n(r_wrst_n),
                .i_wr(r_wr),
                .i_wdata(w_wdata[b_row]),
                .o_wfull(w_wfull[b_row]),
                // read side
                .i_rclk(pclk_i),
                .i_rrst_n(r_rrst_n),
                .i_rd(r_rd),
                .o_rdata(w_rdata[b_row]),
                .o_rempty(w_rempty[b_row])
            );
        end
    endgenerate

    // what does initializing [7:0] ksr [0][0] mean?
    // should be one row/column index pointing to a single byte
    // and so kernel_o = ksr should work.
    // but for some reason, i have to do it this way for a 1x1 window
    assign kernel_o = ksr;


endmodule

/**
 * This module takes the kernel window,
 * and assigns the given constant value to pixels
 * outside the actual image (constant extension).
 */
module conv_router #(
    // input image dimensions
    parameter WIDTH = 320,
    parameter HEIGHT = 240,

    // input image depth
    parameter DEPTH = 8,

    parameter K_WIDTH = 3,
    parameter K_HEIGHT = 3,

    // Constant value for pixels outside image
    parameter CONSTANT = 0
)  (
    // input kernel window
    input  [(DEPTH-1):0]                        kernel_i  [K_HEIGHT][K_WIDTH],

    // row and column for incoming pixel
    input signed [15:0]  col_i, 
    input signed [15:0]  row_i, 

    // outgoing kernel window with constant extension applied
    output [(DEPTH-1):0]                        kernel_o  [K_HEIGHT][K_WIDTH]
);

    localparam MID_K_H = K_HEIGHT / 2;
    localparam MID_K_W = K_WIDTH / 2;

    ////////////////////////////////////////////////////////////////
    // Wiring constant expression muxes

    // The k window order is actually
    /*
     *  bottom right --------- bottom left
     *               |        |
     *               |        |
     *               |        |
     *  top right    --------- top left
     */
    // so we have to be careful on how to properly index

    logic [DEPTH-1:0] r_kernel [K_HEIGHT][K_WIDTH];

    integer k_col, k_row;
    integer k_c, k_r;
    integer k_c_offset, k_r_offset;
    integer k_r_act, k_c_act;

    always@(*) begin
        for(k_row = 0; k_row < K_HEIGHT; k_row = k_row + 1) begin
            for(k_col = 0; k_col < K_WIDTH; k_col = k_col + 1) begin
                k_c = (K_WIDTH - 1) - k_col + ( (K_WIDTH - 1) % 2);
                k_r = (K_HEIGHT - 1) - k_row + ( (K_HEIGHT - 1) % 2);
                k_c_offset = k_c - MID_K_W;
                k_r_offset = k_r - MID_K_H;
                k_r_act = row_i + k_r_offset;
                k_c_act = col_i + k_c_offset;

                if( (k_c_act >= 0) && (k_c_act < WIDTH) &&
                    (k_r_act >= 0) && (k_r_act < HEIGHT) )
                    r_kernel[k_row][k_col] = kernel_i[k_row][k_col];
                else
                    r_kernel[k_row][k_col] = CONSTANT;

            end
        end
    end

    // see conv_entry_fifo comments at the kernel_o assign
    assign kernel_o = r_kernel;

endmodule

/**
 * Kernel convolution with parameterized cycles so we can perform
 * MAC operations over several cycles to save on resources or 1
 * with maximal resource usage.
 * It also takes in the values to multiply the window with, called
 * kernel coefficients.
 */

module kernel_convolution #(
    // FP parameters 
    parameter FP_M_IMAGE = 8,
    parameter FP_N_IMAGE = 0,
    parameter FP_S_IMAGE = 0,

    parameter FP_M_KERNEL = 8,
    parameter FP_N_KERNEL = 0,
    parameter FP_S_KERNEL = 0,

    parameter FP_M_IMAGE_OUT = 8,
    parameter FP_N_IMAGE_OUT = 0,
    parameter FP_S_IMAGE_OUT = 0,

    // input image dimensions
    parameter WIDTH = 320,
    parameter HEIGHT = 240,

    // kernel window dimensions
    parameter K_WIDTH = 3,
    parameter K_HEIGHT = 3,

    // how many cycles do we have per pixel
    parameter CLKS_PER_PIXEL = 1
)  (
    // clock
    input pclk_i,

    // data valid, are we about to shift new values in?
    input dv_i,

    // is the pipe full?
    input ispipefull_i,

    // kernel state and cycle count is managed by the conv_net module
    input                            kernel_state_i,
    input [$clog2(CLKS_PER_PIXEL):0] convolution_step_i,

    // input kernel window
    input  [(FP_M_IMAGE + FP_N_IMAGE + FP_S_IMAGE -1):0] kernel_i [K_HEIGHT][K_WIDTH],

    // input kernel coeffs
    input  [(FP_M_KERNEL + FP_N_KERNEL + FP_S_KERNEL -1):0] kernel_coeffs_i  [K_HEIGHT][K_WIDTH],

    // incoming pipe pixel col and row
    input  [15:0]  col_i, 
    input  [15:0]  row_i, 


    // output filtered pixel data
    output [FP_M_IMAGE_OUT + FP_N_IMAGE_OUT + FP_S_IMAGE_OUT -1:0] pixel_data_o,

    // outgoing row and column for pipe pixel
    output  [15:0] col_o, 
    output  [15:0] row_o, 

    // output dv
    output dv_o
);
    // Kernel State for cycles per pixel
    localparam READY = 1'b1;
    localparam BUSY = 1'b0;

    // parallel number of macs to perform, ceiling division 
    localparam PARALLEL_MACS = (((K_WIDTH * K_HEIGHT) % CLKS_PER_PIXEL) != 0) ? 
                               (((K_WIDTH * K_HEIGHT) / CLKS_PER_PIXEL) + 1) : 
                               ((K_WIDTH * K_HEIGHT) / CLKS_PER_PIXEL);

    localparam DEPTH     = FP_M_IMAGE + FP_N_IMAGE + FP_S_IMAGE;    
    localparam K_DEPTH   = FP_M_KERNEL + FP_N_KERNEL + FP_S_KERNEL;
    localparam DEPTH_OUT = FP_M_IMAGE_OUT + FP_N_IMAGE_OUT + FP_S_IMAGE_OUT;

    // output format of calculated result
    localparam FP_MC = FP_M_IMAGE + FP_M_KERNEL + 1 + $clog2(K_WIDTH * K_HEIGHT);
    localparam FP_NC = FP_N_IMAGE + FP_N_KERNEL;
    localparam FP_SC = 1;

    // accumulator bit width
    localparam ACC_DEPTH = FP_MC + FP_NC + FP_SC;

    localparam DEPTH_DIFF = (DEPTH_OUT > ACC_DEPTH) ?
                            (DEPTH_OUT - ACC_DEPTH) :
                            (ACC_DEPTH - DEPTH_OUT);
    
    logic signed [(ACC_DEPTH-1):0] accumulator;
    logic signed [(ACC_DEPTH-1):0] accumulator_next;
    logic signed [(ACC_DEPTH-1):0] accumulator_out;

    // flat kernel window
    logic [0:(K_HEIGHT * K_WIDTH * DEPTH) - 1] kernel_flattened;
    logic signed [(FP_M_IMAGE + FP_N_IMAGE + 1 - 1):0] temp_k;

    // flat kernel coefficients
    logic [0:(K_HEIGHT * K_WIDTH * K_DEPTH)-1] kernel_coeffs_flattened;
    logic signed [(FP_M_KERNEL + FP_N_KERNEL + 1 - 1):0] temp_kc;

    // indexing variables
    integer k_c, k_r, si, si_k, si_k_coeffs, cs, offset_k, offset_k_coeffs;

    // dv_o state
    logic r_dv_o;
    logic r_dv_o_next;
    
    always@(*) begin
        ////////////////////////////////////////////////////////////////
        // Wiring for flattening kernel window
        for(k_r = 0; k_r < K_HEIGHT; k_r = k_r + 1) begin
            for(k_c = 0; k_c < K_WIDTH; k_c = k_c + 1) begin
                si = (k_r * K_WIDTH * DEPTH) + (k_c * DEPTH);
                kernel_flattened[si +: DEPTH] = kernel_i[k_r][k_c];
            end
        end

        ////////////////////////////////////////////////////////////////
        // Wiring for flattening kernel coefficients
        // bottom/top right/left flip, see conv_router notes
        for(k_r = 0; k_r < K_HEIGHT; k_r = k_r + 1) begin
            for(k_c = 0; k_c < K_WIDTH; k_c = k_c + 1) begin
                si = (k_r * K_WIDTH * K_DEPTH) + (k_c * K_DEPTH);
                kernel_coeffs_flattened[si +: K_DEPTH] = kernel_coeffs_i[(K_HEIGHT - 1) - k_r][(K_WIDTH - 1) - k_c];
            end
        end

        ////////////////////////////////////////////////////////////////
        // Kernel calculations wrt to convolution step
        accumulator_next = 0;
        accumulator_out = accumulator;

        si_k = convolution_step_i * PARALLEL_MACS * DEPTH;
        si_k_coeffs = convolution_step_i * PARALLEL_MACS * K_DEPTH;

        for(cs = 0; cs < PARALLEL_MACS; cs = cs + 1) begin
            offset_k = si_k + (cs * DEPTH);
            offset_k_coeffs = si_k_coeffs + (cs * K_DEPTH);
            if(offset_k < (K_HEIGHT * K_WIDTH * DEPTH)) begin
                
                // conversions to signed 
                if(FP_S_IMAGE == 0) begin
                    temp_k = { {1'b0}, kernel_flattened[offset_k +: DEPTH] };
                end else begin
                    temp_k = kernel_flattened[offset_k +: DEPTH];
                end

                if(FP_S_KERNEL == 0) begin
                    temp_kc = { {1'b0}, kernel_coeffs_flattened[offset_k_coeffs +: K_DEPTH]};
                end else begin
                    temp_kc = kernel_coeffs_flattened[offset_k_coeffs +: K_DEPTH];
                end

                accumulator_out += (temp_k * temp_kc);
            end
        end

        case(kernel_state_i)
            READY: begin
                if(dv_i) begin 
                    accumulator_next = 0;
                end else begin 
                    accumulator_next = accumulator;
                end  
            end
            BUSY: begin
                accumulator_next = accumulator_out;
            end
        endcase

        // dv_o logic
        r_dv_o_next = 0;

        if(CLKS_PER_PIXEL == 1) begin
            r_dv_o_next = dv_i;
        end else begin
            if(convolution_step_i == (CLKS_PER_PIXEL - 2)) begin
                r_dv_o_next = 1;
            end
        end

    end

    ////////////////////////////////////////////////////////////////
    // Fixed Point output formatting
    // see FP notes

    // rename
    logic [(ACC_DEPTH-1):0] sqc;
    assign sqc = accumulator_out;

    logic [FP_M_IMAGE_OUT + FP_N_IMAGE_OUT + FP_S_IMAGE_OUT -1:0] r_pixel_data;

    // Had to do this to make the repition multipliers and widths constant
    localparam bit_width_sqc = ACC_DEPTH;
    localparam sext_lhs = (FP_M_IMAGE_OUT - FP_MC) > 0 ? FP_M_IMAGE_OUT - FP_MC : 0;
    localparam li       = (FP_M_IMAGE_OUT - FP_MC) > 0 ? bit_width_sqc - 2 : bit_width_sqc - 2 + (FP_M_IMAGE_OUT - FP_MC);
    localparam zext_rhs = (FP_N_IMAGE_OUT - FP_NC) > 0 ? FP_N_IMAGE_OUT - FP_NC : 0;
    localparam ri       = (FP_N_IMAGE_OUT - FP_NC) > 0 ? 0 : 0 - (FP_N_IMAGE_OUT - FP_NC);

    always@(*) begin
        r_pixel_data = 0;

        if((li >= 0) && (ri < (bit_width_sqc - 1))) begin
            if(FP_S_IMAGE_OUT == 1) begin
                r_pixel_data = { sqc[bit_width_sqc-1], {sext_lhs{sqc[bit_width_sqc-1]}} , sqc[ri +: (li - ri + 1)] , {zext_rhs{1'b0}} };
            end else begin
                r_pixel_data = { {sext_lhs{sqc[bit_width_sqc-1]}} , sqc[ri +: (li - ri + 1)] , {zext_rhs{1'b0}} };
            end

        end else begin
            if(FP_S_IMAGE_OUT == 1) begin
                if(ri == (bit_width_sqc - 1)) begin
                    r_pixel_data = { {sqc[bit_width_sqc-1]}, {sext_lhs{sqc[bit_width_sqc-1]}} , {zext_rhs{1'b0}} };
                end else begin
                    r_pixel_data = { {1'b0}, {sext_lhs{1'b0}} , {zext_rhs{1'b0}} };
                end
            end else begin
                if(ri == (bit_width_sqc - 1)) begin
                    // hack to get around all zero replications in concat error
                    r_pixel_data = { {1'b0} , {sext_lhs{sqc[bit_width_sqc-1]}} , {zext_rhs{1'b0}} } >> 1;
                end else begin
                    // hack to get around all zero replications in concat error
                    r_pixel_data = { {1'b0} , {sext_lhs{1'b0}} , {zext_rhs{1'b0}} } >> 1;
                end

            end
        end
    end


    // pipe col row is already latched, we don't need to track it
    assign col_o = col_i;
    assign row_o = row_i;

    // dv_o is simple, if we are in the ready state, dv goes high
    // actually, doing that will cause repeated data, need to be more careful
    assign dv_o = (ispipefull_i == 1) ? r_dv_o : 0;
    
    // pixel out
    assign pixel_data_o = r_pixel_data;    

    always@(posedge pclk_i) begin
        accumulator <= accumulator_next;
        r_dv_o <= r_dv_o_next;
    end

endmodule