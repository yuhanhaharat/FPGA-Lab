`timescale 1ns/1ns

module structural_adder_tb();
    parameter N = 32;
    integer i;
    reg clock;
    initial clock = 0;
    always #(4) clock <= ~clock;
    
    reg  [N-1:0] operand1, operand2;
    wire [N:0] adder_output;
    
    // memory to hold our test vectors
    reg [7:0] test_data [5:0];
    
    structural_adder #(32) dut (
        .a(operand1),
        .b(operand2),
        .sum(adder_output),
        .clk(clock)
    );

    initial begin
        // read in our test vectors
        $readmemb("test_data1.mem", test_data);//file that store binary vector for operand1 and operand2
         
        // for each test vector apply inputs
        for (i = 0; i < 6; i = i + 1)
        begin
            {operand1,operand2} = test_data[i];
            #(8);
        end
        
        $stop;
    end

endmodule
