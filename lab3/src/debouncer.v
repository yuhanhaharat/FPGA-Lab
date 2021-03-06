module debouncer #(
    parameter WIDTH              = 1,
    parameter SAMPLE_CNT_MAX     = 25000,
    parameter PULSE_CNT_MAX      = 150,
    parameter WRAPPING_CNT_WIDTH = $clog2(SAMPLE_CNT_MAX) + 1,
    parameter SAT_CNT_WIDTH      = $clog2(PULSE_CNT_MAX) + 1)
(
    input clk,
    input [WIDTH-1:0] glitchy_signal,
    output [WIDTH-1:0] debounced_signal
);

    // TODO: fill in neccesary logic to implement the wrapping counter and the saturating counters
    // Some initial code has been provided to you, but feel free to change it however you like
    // One wrapping counter is required
    // One saturating counter is needed for each bit of debounced_signal
    // You need to think of the conditions for reseting, clock enable, etc. those registers
    // Refer to the block diagram in the spec
    
    wire [WIDTH-1:0] s_out;
    synchronizer #(.WIDTH(WIDTH)) s1(.clk(clk),.async_signal(glitchy_signal),.sync_signal(s_out));
    
    //Wrapping counter logic
    wire [WRAPPING_CNT_WIDTH-1:0] wrapping_cnt_val;
    wire [WRAPPING_CNT_WIDTH-1:0] wrapping_cnt_next;
    wire wrapping_cnt_rst;

    REGISTER_R #(.N(WRAPPING_CNT_WIDTH)) wrapping_cnt(.q(wrapping_cnt_val), .d(wrapping_cnt_next), .rst(wrapping_cnt_rst), .clk(clk));
    wire WC_out;
    assign wrapping_cnt_rst = wrapping_cnt_val == (SAMPLE_CNT_MAX-1);
    assign wrapping_cnt_next = wrapping_cnt_val+1;
    assign WC_out = wrapping_cnt_val == (SAMPLE_CNT_MAX-1);
    
    //Synchronizer logic    
    wire [SAT_CNT_WIDTH-1:0] sat_cnt_val[WIDTH-1:0];
    wire [SAT_CNT_WIDTH-1:0] sat_cnt_next[WIDTH-1:0];
    wire sat_cnt_rst[WIDTH-1:0];
    wire sat_cnt_ce[WIDTH-1:0];
    
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin
            assign sat_cnt_rst[i] = ~s_out[i];   
        end
    endgenerate
    
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin
            assign sat_cnt_ce[i] =  WC_out && s_out[i];   
        end
    endgenerate
    
    wire [WIDTH-1:0] tc;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin
            assign sat_cnt_next[i] = (tc[i] == 0) ? sat_cnt_val[i]+1 : sat_cnt_val[i];
            assign tc[i] = sat_cnt_val[i] == PULSE_CNT_MAX;
        end
    endgenerate
    
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin
            REGISTER_R_CE #(.N(SAT_CNT_WIDTH)) sat_cnt (.q(sat_cnt_val[i]), .d(sat_cnt_next[i]), .rst(sat_cnt_rst[i]), .ce(sat_cnt_ce[i]), .clk(clk));
        end
    endgenerate

    genvar j;
    generate
        for (j = 0; j < WIDTH; j = j + 1) begin
            assign debounced_signal[j] = (sat_cnt_val[j] == (PULSE_CNT_MAX));
        end
    endgenerate
endmodule
