module full_adder 
(
    input a,
    input b,
    input carry_in,
    output sum,
    output carry_out
);
    // TODO: Insert your RTL here to calculate the sum and carry out bits
    // Remove these assign statements once you write your own RTL
    assign sum = a^b^carry_in;
    assign carry_out = (a&carry_in) | (a&b) | (b&carry_in);

endmodule
