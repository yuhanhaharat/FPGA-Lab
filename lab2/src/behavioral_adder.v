module behavioral_adder (
    input [2:0] A,
    input [2:0] B,
    output [3:0] sum
);
    assign sum = A + B;
    
endmodule
