module uart #(
  parameter CLOCK_FREQ = 125_000_000,
  parameter BAUD_RATE  = 115_200
) (
  input clk,
  input rst,

  input  serial_in,
  output serial_out
);

    wire [7:0] uart_rx_data_out;
    wire uart_rx_data_out_valid;
    wire uart_rx_data_out_ready;

    uart_receiver #(
        .CLOCK_FREQ(125_000_000),
        .BAUD_RATE(115_200)) uart_rx (
        .clk(clk),
        .rst(rst),
        .data_out(uart_rx_data_out),             // output
        .data_out_valid(uart_rx_data_out_valid),     // output
        .data_out_ready(uart_rx_data_out_ready),     // input
        .serial_in(serial_in)                        // input
    );
    
    wire [7:0] uart_tx_data_in;
    wire uart_tx_data_in_valid;
    wire uart_tx_data_in_ready;
    
    uart_transmitter #(
        .CLOCK_FREQ(125_000_000),
        .BAUD_RATE(115_200)) uart_tx (
        .clk(clk),
        .rst(rst),
        .data_in(uart_tx_data_in),             // input
        .data_in_valid(uart_tx_data_in_valid), // input
        .data_in_ready(uart_tx_data_in_ready), // output
        .serial_out(serial_out)            // output
    );
    
    localparam FIFO_WIDTH    = 8;
    localparam FIFO_LOGDEPTH = 10;
    wire [FIFO_WIDTH-1:0] fifo_uart_enq_data, fifo_uart_deq_data;
    wire fifo_uart_enq_valid, fifo_uart_enq_ready, fifo_uart_deq_valid, fifo_uart_deq_ready;

    fifo #(.WIDTH(FIFO_WIDTH), .LOGDEPTH (FIFO_LOGDEPTH)) FIFO_UART (
        .clk(clk),
        .rst(rst),

        .enq_valid(fifo_uart_enq_valid),  // input
        .enq_data(fifo_uart_enq_data),    // input
        .enq_ready(fifo_uart_enq_ready),  // output

        .deq_valid(fifo_uart_deq_valid),  // output
        .deq_data(fifo_uart_deq_data),    // output
        .deq_ready(fifo_uart_deq_ready)); // input

    // FPGA_SERIAL_RX --> UART Receiver <--> FIFO_UART <--> UART Transmitter --> FPGA_SERIAL_TX
    // R/V Handshakes
    wire [7:0] in_char;
    reg [7:0] out_char;
    wire [7:0] uart_rx_data_out_inv;
    assign in_char = uart_rx_data_out;
    always@(*)begin
        if (in_char >= "a" && in_char <= "z")
            out_char = in_char - 8'd32;
        else if (in_char >= "A" && in_char <= "Z")
            out_char = in_char + 8'd32;
        else
            out_char = in_char;    
    end
    
    assign uart_rx_data_out_inv = out_char;

    assign fifo_uart_enq_data     = uart_rx_data_out_inv;
    assign fifo_uart_enq_valid    = uart_rx_data_out_valid;
    assign uart_rx_data_out_ready = fifo_uart_enq_ready;

    assign uart_tx_data_in        = fifo_uart_deq_data;
    assign uart_tx_data_in_valid  = fifo_uart_deq_valid;
    assign fifo_uart_deq_ready    = uart_tx_data_in_ready;
endmodule
