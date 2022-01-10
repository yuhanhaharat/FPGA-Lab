// Source: https://www.ibm.com/support/knowledgecenter/P8DEA/p8egb/p8egb_supportedresolution.htm
module display_controller #(

    // Video resolution parameters for 800x600 @60Hz -- pixel_freq = 40 MHz
    parameter H_ACTIVE_VIDEO = 800,
    parameter H_FRONT_PORCH  = 40,
    parameter H_SYNC_WIDTH   = 128,
    parameter H_BACK_PORCH   = 88,

    parameter V_ACTIVE_VIDEO = 600,
    parameter V_FRONT_PORCH  = 1,
    parameter V_SYNC_WIDTH   = 4,
    parameter V_BACK_PORCH   = 23

//    // Video resolution parameters for 1024x768 @60Hz -- pixel_freq = 65 MHz
//    parameter H_ACTIVE_VIDEO = 1024,
//    parameter H_FRONT_PORCH  = 24,
//    parameter H_SYNC_WIDTH   = 136,
//    parameter H_BACK_PORCH   = 160,
//
//    parameter V_ACTIVE_VIDEO = 768,
//    parameter V_FRONT_PORCH  = 3,
//    parameter V_SYNC_WIDTH   = 6,
//    parameter V_BACK_PORCH   = 29


//    // Video resolution parameters for 1280x720 @60Hz -- pixel_freq = 74.25 MHz
//    parameter H_ACTIVE_VIDEO = 1280,
//    parameter H_FRONT_PORCH  = 110,
//    parameter H_SYNC_WIDTH   = 40,
//    parameter H_BACK_PORCH   = 220,
//
//    parameter V_ACTIVE_VIDEO = 720,
//    parameter V_FRONT_PORCH  = 5,
//    parameter V_SYNC_WIDTH   = 5,
//    parameter V_BACK_PORCH   = 20
) (
    input pixel_clk,
    input rst,
    
    input [23:0] pixel_stream_din_data,
    input pixel_stream_din_valid,
    output pixel_stream_din_ready,

    // video signals
    output [23:0] video_out_pData,
    output video_out_pHSync,
    output video_out_pVSync,
    output video_out_pVDE
);

    // Some hints for you to get started
    localparam H_FRAME = H_ACTIVE_VIDEO + H_FRONT_PORCH + H_SYNC_WIDTH + H_BACK_PORCH;
    localparam V_FRAME = V_ACTIVE_VIDEO + V_FRONT_PORCH + V_SYNC_WIDTH + V_BACK_PORCH;

    wire [31:0] x_pixel_val, x_pixel_next;
    wire x_pixel_ce, x_pixel_rst;
    wire [31:0] y_pixel_val, y_pixel_next;
    wire y_pixel_ce, y_pixel_rst;

    // x_pixel: 0 ---> H_FRAME
    // y_pixel: 0 ---> V_FRAME
    REGISTER_R_CE #(.N(32), .INIT(0)) x_pixel (
        .q(x_pixel_val),
        .d(x_pixel_next),
        .ce(x_pixel_ce),
        .rst(x_pixel_rst),
         .clk(pixel_clk));
    REGISTER_R_CE #(.N(32), .INIT(0)) y_pixel (
        .q(y_pixel_val),
        .d(y_pixel_next),
        .ce(y_pixel_ce),
        .rst(y_pixel_rst),
        .clk(pixel_clk));
    
    localparam H_SYNC_START = H_ACTIVE_VIDEO + H_FRONT_PORCH;
    localparam H_SYNC_END = H_ACTIVE_VIDEO + H_FRONT_PORCH + H_SYNC_WIDTH;
    localparam V_SYNC_START = V_ACTIVE_VIDEO + V_FRONT_PORCH;
    localparam V_SYNC_END = V_ACTIVE_VIDEO + V_FRONT_PORCH + V_SYNC_WIDTH;
    
    //fix y first and scan x direction
    assign x_pixel_next = x_pixel_val + 1;
    assign y_pixel_next = y_pixel_val + 1;
    assign x_pixel_rst = (x_pixel_val == H_FRAME-1) ? 1'b1:1'b0;
    assign y_pixel_rst = rst;
    assign x_pixel_ce = pixel_stream_din_valid;
    assign y_pixel_ce = (x_pixel_val == H_FRAME-1) ? 1'b1:1'b0;
    
    assign video_out_pHSync = (x_pixel_val<H_SYNC_END && x_pixel_val>=H_SYNC_START) ? 1'b1 : 1'b0;
    assign video_out_pVSync = (y_pixel_val<V_SYNC_END && y_pixel_val>=V_SYNC_START) ? 1'b1 : 1'b0;
    wire H_active_region = (x_pixel_val >= 32'd0) && (x_pixel_val < H_ACTIVE_VIDEO);
    wire V_active_region = (y_pixel_val >= 32'd0) && (y_pixel_val < V_ACTIVE_VIDEO);
    assign video_out_pVDE = (H_active_region && V_active_region && pixel_stream_din_valid) ? 1'b1 : 1'b0;
    
    // TODO: fill in the remaining logic to implement the display controller
    // Make sure your signals meet the timing specification for HSync, VSync, and Video Active
    // For task 1, do not worry about the 'pixel_stream_din_data', just set 'video_out_pData'
    // to some constant value to test if your code works with a monitor
    // For task 2, you need to implement proper control logic to enqueue the 'pixel_stream_din'
    
    
//    assign video_out_pData = 24'h0000FF; // task 1
    // task 2
    assign pixel_stream_din_ready = video_out_pVDE;
    assign video_out_pData = pixel_stream_din_data; 

endmodule
