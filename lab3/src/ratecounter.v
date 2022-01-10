`timescale 1ns / 1ps

module timer(clk,tc,MAX_VAL,rst);
    input clk,rst;
    output tc;
    input [31:0] MAX_VAL;
    
    wire [31:0] value;
    wire [31:0] next;
    
    REGISTER_R #(.N(32)) RR1 (.q(value), .d(next), .clk(clk),.rst(rst));
    
    assign next = (tc == 1'b1) ? {32{1'b0}} : value + 1;
    assign tc = value == MAX_VAL;
endmodule

module ratecounter (clk,out,freq,buttonrst);
    input clk,buttonrst;
    input [3:0] freq;
    output [5:0] out;
    //assign out[5:4] = 0;    //initial value for LED4,5
    
    reg [31:0] MAX;
    
    always@(*)begin
        case(freq) 
            4'd1: MAX = 32'd62500000;
            4'd2: MAX = 32'd41666666;
            4'd3: MAX = 32'd31250000;
            4'd4: MAX = 32'd25000000;
            4'd5: MAX = 32'd12500000;
            4'd6: MAX = 32'd6250000;
            default: MAX = 32'd125000000;
        endcase
    end
    
    // Some initial code has been provided for you
    wire [3:0] counter_val;
    wire [3:0] counter_update;
    wire is_update;

    // This register will be updated when is_one_sec is True
    REGISTER_CE #(4) counter_reg (.clk(clk), .ce(is_update), .d(counter_update), .q(counter_val));
    
    //LED value is counter value
    assign out[3:0] = counter_val;
    assign counter_update = counter_val + 1;
    
    timer timer1 (.clk(clk),.tc(is_update),.MAX_VAL(MAX),.rst(buttonrst));
endmodule

module ratecounter_run(clk,in,out);
    input clk;
    input [3:0] in;
    output [5:0] out;
    
    wire [3:0] freq_val,freq_next;
    wire freq_rst;
    wire buttonrst;
        
    assign freq_next = (in[0] == 1) ? freq_val + 1 :
                       (in[1] == 1) ? freq_val - 1 :
                       freq_val;
    assign freq_rst = (in[3] == 1);
    assign buttonrst = (in[0] == 1 || in[1] == 1) ? 1:0;
    
    REGISTER_R #(.N(4)) freq_cnt (.q(freq_val), .d(freq_next), .rst(freq_rst), .clk(clk));
    
    ratecounter rc1(.clk(clk),.out(out),.freq(freq_val),.buttonrst(buttonrst));
endmodule
