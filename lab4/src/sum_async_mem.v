module sum_async_mem #(
    parameter AWIDTH = 10,
    parameter DWIDTH = 32,
    parameter DEPTH =  1024,
    parameter MEM_INIT_HEX_FILE = "async_mem_init_hex.mif"
) (
    input clk,
    input reset,
    output done,
    input [31:0] size,
    output [31:0] sum
);

    // TODO: Fill in the remaining logic to compute the sum of memory data from 0 to 'size'
    wire [AWIDTH-1:0] rom_addr;
    wire [DWIDTH-1:0] rom_rdata;
    ASYNC_ROM #(
        .AWIDTH(AWIDTH),
        .DWIDTH(DWIDTH),
        .DEPTH(DEPTH),
        .MEM_INIT_HEX_FILE(MEM_INIT_HEX_FILE)
    ) rom (.addr(rom_addr), .q(rom_rdata));

    wire [31:0] index_reg_val, index_reg_next;
    wire index_reg_rst, index_reg_ce;
    REGISTER_R_CE #(.N(32)) index_reg (.q(index_reg_val), .d(index_reg_next), .ce(index_reg_ce), .rst(index_reg_rst), .clk(clk));
    assign index_reg_rst = reset;
    assign index_reg_next = index_reg_val + 1;
    assign rom_addr = index_reg_val;
    
    wire [31:0] sum_reg_val, sum_reg_next;
    wire sum_reg_rst, sum_reg_ce;
    REGISTER_R_CE #(.N(32)) sum_reg (.q(sum_reg_val), .d(sum_reg_next), .ce(sum_reg_ce), .rst(sum_reg_rst), .clk(clk));
    assign sum_reg_rst = reset;
    assign sum_reg_next = sum_reg_val + rom_rdata; //perform accumulation
    assign sum = sum_reg_val; //sum value
    
    assign index_reg_ce = (size == index_reg_val) ? 1'b0 : 1'b1;
    assign sum_reg_ce = (size == index_reg_val) ? 1'b0 : 1'b1;
    
    assign done = (size == index_reg_val) ? 1'b1: 1'b0;

endmodule
