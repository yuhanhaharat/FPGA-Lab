module structural_adder(A,B,sum); 
    input [2:0] A;
    input [2:0] B;
    output [3:0] sum;
    wire [3:0] Cin;
    // TODO: Insert your RTL here
    // Remove the assign statement once you write your own RTL
    assign Cin[0] = 1'b0;
    
    genvar i;
    generate
        for(i=0;i<3;i=i+1) begin:SA
          full_adder add1(.a(A[i]),.b(B[i]),.carry_in(Cin[i]),.carry_out(Cin[i+1]),.sum(sum[i]));
        end
    endgenerate
    assign sum[3] = Cin[3];
endmodule
