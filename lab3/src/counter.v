module timer (value,clk,tc);
    parameter MAX_VAL = 125000000;
    parameter bit_width = 1;
    
    input clk;
    output [bit_width-1:0] value;
    output tc;
    wire [bit_width-1:0] next;
    
    REGISTER #(bit_width) RR1 (.q(value), .d(next), .clk(clk));
    
    assign next = (tc == 1'b1) ? {bit_width{1'b0}} : value + 1;
    assign tc = value == (MAX_VAL-1);
endmodule

module counter #(
    parameter N = 4,
    parameter RATE_HZ = 1) 
(
    input clk,
    input rst_counter,
    input [N-1:0] rst_counter_val,
    output [N-1:0] counter_output
);

    localparam MAX = 125_000_000/RATE_HZ;
   
    wire [N-1:0] counter_val;
    wire [N-1:0] counter_update;
    wire is_update;
    wire [N-1:0] fast_val;
    
// This register will be updated when is_one_sec is True
    REGISTER_CE #(N) led_counter_reg (.clk(clk), .ce(is_update), .d(counter_val), .q(counter_update));
    timer #(MAX,N) timer1 (.clk(clk),.value(fast_val),.tc(is_update));
   
    assign counter_val = rst_counter ? rst_counter_val : counter_update + 1;
    assign counter_output = counter_update;
   
endmodule
