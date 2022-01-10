`timescale 1ns/1ns

module timer(clk,tc);
    parameter MAX_VAL = 16;
    parameter bit_width = 1;
    
    input clk;
    output tc;
    wire [bit_width-1:0] value,next;
    
    REGISTER #(bit_width) RR1 (.q(value), .d(next), .clk(clk));
    
    assign next = (tc == 1'b1) ? {bit_width{1'b0}} : value + 1;
    assign tc = value == (MAX_VAL-1);
endmodule


module z1top_tone_generator (
    input CLK_125MHZ_FPGA,
    input [3:0] BUTTONS,
    input [1:0] SWITCHES,
    output [5:0] LEDS,

    output PMOD_OUT_PIN1,
    output PMOD_OUT_PIN2,
    output PMOD_OUT_PIN3,
    output PMOD_OUT_PIN4
);
    assign LEDS[5:4] = 2'b11;

    // Button parser
    // Sample the button signal every 500us
    localparam integer B_SAMPLE_CNT_MAX = 0.0005 * 125_000_000;
    // The button is considered 'pressed' after 100ms of continuous pressing
    localparam integer B_PULSE_CNT_MAX = 0.100 / 0.0005;

    wire [3:0] buttons_pressed;
    button_parser #(
        .WIDTH(4),
        .SAMPLE_CNT_MAX(B_SAMPLE_CNT_MAX),
        .PULSE_CNT_MAX(B_PULSE_CNT_MAX)
    ) bp (
        .clk(CLK_125MHZ_FPGA),
        .in(BUTTONS),
        .out(buttons_pressed)
    );

    wire mclk, lrclk, sclk, sdout;

    assign PMOD_OUT_PIN1 = mclk;
    assign PMOD_OUT_PIN2 = lrclk;
    assign PMOD_OUT_PIN3 = sclk;
    assign PMOD_OUT_PIN4 = sdout;

    i2s_controller i2s_controller (
        .clk(CLK_125MHZ_FPGA),
        .mclk(mclk),
        .lrck(lrclk),
        .sclk(sclk)
    );

    localparam NUM_SAMPLE_BITS = 16;

    wire [NUM_SAMPLE_BITS-1:0] i2s_sample_data;
    wire i2s_sample_bit;
    wire i2s_sample_sent;
    i2s_bit_serial i2s_bit_serial (
        .serial_clk(sclk),
        .i2s_sample_sent(i2s_sample_sent),//output
        .i2s_sample_data(i2s_sample_data),//input
        .i2s_sample_bit(i2s_sample_bit)//output
    );

    // 440Hz-tone
    // If we make the memory depth to be a power-of-two value,
    // Vivado synthesis will run faster
    // It is a waste of memory unfortunately, but let's not worry about it now
    localparam TONE_ADDR_WIDTH = 16;
    localparam TONE_DATA_WIDTH = NUM_SAMPLE_BITS;
    localparam TONE_NUM_SAMPLES = 44100;
    localparam TONE_MEM_DEPTH = 65536;//44100;

    wire [TONE_ADDR_WIDTH-1:0] tone_440_mem_addr;
    wire [TONE_DATA_WIDTH-1:0] tone_440_mem_rdata;
    ASYNC_ROM #(
        .AWIDTH(TONE_ADDR_WIDTH),
        .DWIDTH(TONE_DATA_WIDTH),
        .DEPTH(TONE_MEM_DEPTH),
        .MEM_INIT_BIN_FILE("tone_440_data_bin.mif")
    ) tone_440_memory (
        .q(tone_440_mem_rdata), .addr(tone_440_mem_addr));

    // TODO: Your code to interface with the I2S protocol
    //assign i2s_sample_sent = tone_440_mem_rdata;
    localparam TONE_DATA_WIDTH_Double = NUM_SAMPLE_BITS*2;
        
    wire [TONE_ADDR_WIDTH-1:0] counter_val;
    wire [TONE_ADDR_WIDTH-1:0] counter_update;
    wire is_update;
    REGISTER_CE #(TONE_ADDR_WIDTH) addr_counter_reg (.clk(sclk), .ce(is_update), .d(counter_val), .q(counter_update));
    timer #(TONE_DATA_WIDTH_Double,8) timer1 (.clk(sclk), .tc(is_update));
    assign counter_val = counter_update + 1;
    
    assign tone_440_mem_addr = counter_update;
    assign i2s_sample_data = tone_440_mem_rdata;
    
    assign sdout = i2s_sample_bit;
endmodule
