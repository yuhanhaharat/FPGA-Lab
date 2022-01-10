module synchronizer #(parameter WIDTH = 1) (
    input [WIDTH-1:0] async_signal,
    input clk,
    output [WIDTH-1:0] sync_signal
);
	    // TODO: Create your 2 flip-flop synchronizer here
	    // This module takes in a vector of WIDTH-bit asynchronous
      // (from different clock domain or not clocked, such as button press) signals
	    // and should output a vector of WIDTH-bit synchronous signals
      // that are synchronized to the input clk
        wire[WIDTH-1:0] async_out;
        
        genvar i;
        generate
            for (i = 0; i < WIDTH; i = i + 1) begin
                REGISTER #(1) R1(.clk(clk),.q(async_out[i]),.d(async_signal[i]));
            end
        endgenerate
        
        generate
            for (i = 0; i < WIDTH; i = i + 1) begin
                REGISTER #(1) R2(.clk(clk),.q(sync_signal[i]),.d(async_out[i]));
            end
        endgenerate
endmodule
