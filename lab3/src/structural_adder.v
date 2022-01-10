module structural_adder #(parameter N = 3) 
(
    input [N-1:0] a,
    input [N-1:0] b,
    output [N:0] sum,
    input clk
);
    wire [N:0] Cin;
    wire [N:0] sum_comb;
    
    assign Cin[0] = 1'b0;
    genvar i;
    generate
        for(i=0;i<N;i=i+1) begin:SA
          full_adder add1(.a(a[i]),.b(b[i]),.carry_in(Cin[i]),.carry_out(Cin[i+1]),.sum(sum_comb[i]));
        end
    endgenerate
    assign sum_comb[N] = Cin[N];
    
    REGISTER #(N+1) R1(.d(sum_comb),.q(sum),.clk(clk));
    
endmodule

