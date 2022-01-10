/*Other student solution
module uart_transmitter #(
    parameter CLOCK_FREQ = 125_000_000,
    parameter BAUD_RATE = 115_200)
(
    input clk,
    input rst,

    input [7:0] data_in,
    input data_in_valid,
    output data_in_ready,

    output serial_out
);

    localparam  SYMBOL_EDGE_TIME    =   CLOCK_FREQ / BAUD_RATE;
    //localparam  CLOCK_COUNTER_WIDTH =   $clog2(SYMBOL_EDGE_TIME);
    localparam  CLOCK_COUNTER_WIDTH =   11;
    localparam  IDLE = 0;
    localparam  START = 1;
    localparam  STOP = 10;

    reg [9:0] to_send;
    reg [CLOCK_COUNTER_WIDTH:0] clock_ctr;
    reg [3:0] state;

    assign data_in_ready = state == IDLE;
    assign serial_out = state == IDLE ? 1 : to_send[state-1];

    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
        end
        else if (state == IDLE && (data_in_valid && data_in_ready)) begin
            state <= START;
        end
        else if (state != IDLE) begin
            state <= clock_ctr == SYMBOL_EDGE_TIME ? (state == STOP ? IDLE : state+1) : state;
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            to_send <= 0;
        end
        else if (data_in_valid && data_in_ready) begin
            to_send <= {1'b1, data_in, 1'b0};
        end
    end

    always @(posedge clk) begin
        if (rst || (data_in_valid && data_in_ready) || (clock_ctr == SYMBOL_EDGE_TIME)) begin
            clock_ctr <= 0;
        end
        else begin
            clock_ctr <= clock_ctr + 1;
        end
    end

endmodule*/

module uart_transmitter #(
    parameter CLOCK_FREQ = 125_000_000,
    parameter BAUD_RATE = 115_200)
(
    input clk,
    input rst,

    // Enqueue the to-be-sent character
    input [7:0] data_in,
    input data_in_valid,
    output data_in_ready,

    // Serial bit output
    output reg serial_out
);
    // See diagram in the lab guide
    localparam SYMBOL_EDGE_TIME    = CLOCK_FREQ / BAUD_RATE;
    //localparam CLOCK_COUNTER_WIDTH = $clog2(SYMBOL_EDGE_TIME);
    localparam CLOCK_COUNTER_WIDTH = 11;

    (* mark_debug = "true" *) wire [9:0] tx_shift_val;
    reg [9:0] tx_shift_next;
    wire tx_shift_ce;

    // LSB to MSB
    REGISTER_CE #(.N(10)) tx_shift (
        .q(tx_shift_val),
        .d(tx_shift_next),
        .ce(tx_shift_ce),
        .clk(clk));

    (* mark_debug = "true" *) wire [3:0] bit_counter_val;
    wire [3:0] bit_counter_next;
    wire bit_counter_ce, bit_counter_rst;

    // Count to 10
    //REGISTER_R_CE #(.N(4), .INIT(0)) bit_counter (
    //    .q(bit_counter_val),
    //    .d(bit_counter_next),
    //    .ce(bit_counter_ce),
    //    .rst(bit_counter_rst),
    //    .clk(clk)
    //);

    (* mark_debug = "true" *) wire [CLOCK_COUNTER_WIDTH-1:0] clock_counter_val;
    wire [CLOCK_COUNTER_WIDTH-1:0] clock_counter_next;
    wire clock_counter_ce, clock_counter_rst;

    // Keep track of sample time and symbol edge time
    REGISTER_R_CE #(.N(CLOCK_COUNTER_WIDTH), .INIT(0)) clock_counter (
        .q(clock_counter_val),
        .d(clock_counter_next),
        .ce(clock_counter_ce),
        .rst(clock_counter_rst),
        .clk(clk)
    );

  localparam STATE_IDLE   = 0;
  localparam STATE_START  = 1;
  localparam STATE_TRANSMIT1  = 2;
  localparam STATE_TRANSMIT2  = 3;
  localparam STATE_TRANSMIT3  = 4;
  localparam STATE_TRANSMIT4  = 5;
  localparam STATE_TRANSMIT5  = 6;
  localparam STATE_TRANSMIT6  = 7;
  localparam STATE_TRANSMIT7  = 8;
  localparam STATE_TRANSMIT8  = 9;
  localparam STATE_DONE = 10;
  
  wire [3:0] state_value;
  reg  [3:0] state_next;

  REGISTER_R #(.N(4), .INIT(STATE_IDLE)) state_reg (
    .clk(clk),
    .rst(rst),
    .d(state_next),
    .q(state_value)
  );
  
  wire idle = state_value == STATE_IDLE;
  wire start = state_value == STATE_START;
  wire transmit1 = state_value == STATE_TRANSMIT1;
  wire transmit2 = state_value == STATE_TRANSMIT2;
  wire transmit3 = state_value == STATE_TRANSMIT3;
  wire transmit4 = state_value == STATE_TRANSMIT4;
  wire transmit5 = state_value == STATE_TRANSMIT5;
  wire transmit6 = state_value == STATE_TRANSMIT6;
  wire transmit7 = state_value == STATE_TRANSMIT7;
  wire transmit8 = state_value == STATE_TRANSMIT8;
  wire done = state_value == STATE_DONE;
  
  wire is_symbol_edge = (clock_counter_val == SYMBOL_EDGE_TIME - 1);
  wire data_in_fire = data_in_valid & data_in_ready;

  always @(*) begin
      state_next = state_value;
      case (state_value)
        STATE_IDLE: begin
          if (data_in_fire == 1'b1) begin
            state_next = STATE_START;
          end
        end
        STATE_START: begin
          if(is_symbol_edge == 1'b1) begin
              state_next = STATE_TRANSMIT1;
          end
        end
        STATE_TRANSMIT1: begin
          if (is_symbol_edge == 1'b1)begin
            state_next = STATE_TRANSMIT2;
          end
        end
        STATE_TRANSMIT2: begin
          if (is_symbol_edge == 1'b1)begin
            state_next = STATE_TRANSMIT3;
          end
        end
        STATE_TRANSMIT3: begin
          if (is_symbol_edge == 1'b1)begin
            state_next = STATE_TRANSMIT4;
          end
        end
        STATE_TRANSMIT4: begin
          if (is_symbol_edge == 1'b1)begin
            state_next = STATE_TRANSMIT5;
          end
        end
        STATE_TRANSMIT5: begin
        if (is_symbol_edge == 1'b1)begin
            state_next = STATE_TRANSMIT6;
          end
        end
        STATE_TRANSMIT6: begin
          if (is_symbol_edge == 1'b1)begin
            state_next = STATE_TRANSMIT7;
          end
        end
        STATE_TRANSMIT7: begin
        if (is_symbol_edge == 1'b1)begin
            state_next = STATE_TRANSMIT8;
          end
        end
        STATE_TRANSMIT8: begin
          if (is_symbol_edge == 1'b1)begin
            state_next = STATE_DONE;
          end
        end
        STATE_DONE: begin
          if(is_symbol_edge == 1'b1) begin
                state_next = STATE_IDLE;
          end
        end
      endcase
  end

  assign data_in_ready = idle;
 
  assign clock_counter_next = clock_counter_val + 1;
  assign clock_counter_ce = 1'b1;
  assign clock_counter_rst = rst || data_in_fire || is_symbol_edge;
  
  always@(*)begin
      if(data_in_fire == 4'd1)begin
          tx_shift_next = {1'b1,data_in,1'b0};
      end
  end
  
  assign tx_shift_ce = data_in_fire == 4'd1;  //only when data_in_fire, we take new data
      
  always@(*)begin
    serial_out = 1'b1;
    case(state_value)
        STATE_START:begin
            serial_out = tx_shift_val[0];
        end
        STATE_TRANSMIT1:begin
            serial_out = tx_shift_val[1];
        end
        STATE_TRANSMIT2:begin
            serial_out = tx_shift_val[2];
        end
        STATE_TRANSMIT3:begin
            serial_out = tx_shift_val[3];
        end
        STATE_TRANSMIT4:begin
            serial_out = tx_shift_val[4];
        end
        STATE_TRANSMIT5:begin
            serial_out = tx_shift_val[5];
        end
        STATE_TRANSMIT6:begin
            serial_out = tx_shift_val[6];
        end
        STATE_TRANSMIT7:begin
            serial_out = tx_shift_val[7];
        end
        STATE_TRANSMIT8:begin
            serial_out = tx_shift_val[8];
        end
        STATE_DONE:begin
            serial_out = tx_shift_val[9];
        end
    endcase
  end
endmodule

/*does not work in FPGA
module uart_transmitter #(
    parameter CLOCK_FREQ = 125_000_000,
    parameter BAUD_RATE = 115_200)
(
    input clk,
    input rst,

    // Enqueue the to-be-sent character
    input [7:0] data_in,
    input data_in_valid,
    output data_in_ready,

    // Serial bit output
    output serial_out
);
    // See diagram in the lab guide
    localparam SYMBOL_EDGE_TIME    = CLOCK_FREQ / BAUD_RATE;
    //localparam CLOCK_COUNTER_WIDTH = $clog2(SYMBOL_EDGE_TIME);
    localparam CLOCK_COUNTER_WIDTH = 11;

    (* mark_debug = "true" *) wire [9:0] tx_shift_val;
    reg [9:0] tx_shift_next;
    wire tx_shift_ce;

    // LSB to MSB
    REGISTER_CE #(.N(10)) tx_shift (
        .q(tx_shift_val),
        .d(tx_shift_next),
        .ce(tx_shift_ce),
        .clk(clk));

    (* mark_debug = "true" *) wire [3:0] bit_counter_val;
    wire [3:0] bit_counter_next;
    wire bit_counter_ce, bit_counter_rst;

    // Count to 10
    REGISTER_R_CE #(.N(4), .INIT(0)) bit_counter (
        .q(bit_counter_val),
        .d(bit_counter_next),
        .ce(bit_counter_ce),
        .rst(bit_counter_rst),
        .clk(clk)
    );

    (* mark_debug = "true" *) wire [CLOCK_COUNTER_WIDTH-1:0] clock_counter_val;
    wire [CLOCK_COUNTER_WIDTH-1:0] clock_counter_next;
    wire clock_counter_ce, clock_counter_rst;

    // Keep track of sample time and symbol edge time
    REGISTER_R_CE #(.N(CLOCK_COUNTER_WIDTH), .INIT(0)) clock_counter (
        .q(clock_counter_val),
        .d(clock_counter_next),
        .ce(clock_counter_ce),
        .rst(clock_counter_rst),
        .clk(clk)
    );

    wire is_symbol_edge = (clock_counter_val == SYMBOL_EDGE_TIME - 1);
    wire data_in_fire = data_in_valid & data_in_ready;
    
    assign clock_counter_next = clock_counter_val + 1;
    assign clock_counter_ce = 1'b1;
    assign clock_counter_rst = rst || data_in_fire || is_symbol_edge;
    
    assign bit_counter_next = bit_counter_val + 1;
    assign bit_counter_rst = (bit_counter_val == 4'd10 && is_symbol_edge) ? 1'b1 : 1'b0;
    assign bit_counter_ce = (bit_counter_val == 4'd0 && data_in_fire) || (bit_counter_val != 4'd0 && is_symbol_edge);   //disable bit_counter when there is no data comes in to the UART

    assign data_in_ready = (bit_counter_val == 4'd0);
    
    always@(*)begin
        if(data_in_fire == 4'd1)begin
            tx_shift_next = {1'b1,data_in,1'b0};
        end
    end
        
    assign tx_shift_ce = data_in_fire == 4'd1;  //only when data_in_fire, we take new data
    assign serial_out = (bit_counter_val == 4'd0) ? 1'b1 : tx_shift_val[bit_counter_val-1];
    
endmodule*/
