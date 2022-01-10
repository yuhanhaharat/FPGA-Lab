`timescale 1ns / 1ps

module timer(value,clk,tc,rst);
    parameter MAX_VAL = 125000000-1;
    input clk,rst;
    output [31:0] value;
    output tc;
    wire [31:0] next;
    
    REGISTER_R #(.N(32)) RR1 (.q(value), .d(next), .clk(clk),.rst(rst));
    
    assign next = (tc == 1'b1) ? 32'd0 : value + 1;
    assign tc = value == MAX_VAL;
endmodule

module z1top_counter (
    input CLK_125MHZ_FPGA,
    input [3:0] BUTTONS,
    output [5:0] LEDS,
    input [1:0] SWITCHES
);
    assign LEDS[5:4] = 0;
    
    // Some initial code has been provided for you
    wire [3:0] led_counter_val;
    wire [3:0] led_counter_update;
    wire is_one_sec;

    // This register will be updated when is_one_sec is True
    REGISTER_CE #(4) led_counter_reg (.clk(CLK_125MHZ_FPGA), .ce(is_one_sec), .d(led_counter_update), .q(led_counter_val));

    assign LEDS[3:0] = led_counter_val;
    assign led_counter_update = led_counter_val + 1;

    // is_one_sec is True every second (= how many cycles?)
    // You may use another register of keep track of the time
    // TODO: Correct the following assignment when you write your code
     
    wire [31:0] fast_val;
    wire rst;
    assign rst = SWITCHES[0];
    timer timer1 (.clk(CLK_125MHZ_FPGA),.value(fast_val),.tc(is_one_sec),.rst(rst));
    
    // TODO: Instantiate a REIGISTER module for your second register/counter
    // You also need to think of how many bits are required for your register

endmodule
