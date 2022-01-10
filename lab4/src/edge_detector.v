//https://vhdlguide.com/2016/07/23/edge-detector/

module edge_detector #(
    parameter WIDTH = 1
)(
    input clk,
    input [WIDTH-1:0] signal_in,
    output [WIDTH-1:0] edge_detect_pulse
);
    
    wire [WIDTH-1:0] signal_syn; 
    wire [WIDTH-1:0] signal_dly;  
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin
            REGISTER #(1) R1(.d(signal_in[i]),.q(signal_syn[i]),.clk(clk));
        end
    endgenerate
    
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin
            REGISTER #(1) R2(.d(signal_syn[i]),.q(signal_dly[i]),.clk(clk));
        end
    endgenerate
    
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin
            assign edge_detect_pulse[i] = signal_syn[i] && ~signal_dly[i];
        end
    endgenerate
endmodule
