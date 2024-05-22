// This is main module that combines all the modules together.

module main 
#(
  parameter UART_CLK_PER_BIT    = 104,
  parameter UART_COUNTER_WIDTH  = 7,
  parameter FIFO_DEPTH_RX       = 2,
  parameter POINTER_WIDTH_RX    = 1,
  parameter FIFO_DEPTH_TX       = 8,
  parameter POINTER_WIDTH_TX    = 4,
  parameter TESTBENCH           = 0
)(
	input 	reset_button,
	input 	clk_50,
	input 	uart_rx,
	output 	uart_tx,
	output 	[6:0] one_segment,
	output	[3:0] dig_out
);

// Registerts
logic uart_rx_q;
logic reset_button_q;
logic reset_button_processed_q;
logic pll_lock_q;


// Connections between modules
logic [7:0]  uart_rx_data;
logic [7:0]  uart_rx_fifo_data;
logic [7:0]  uart_tx_data;
logic [7:0]  uart_tx_fifo_data;
logic [15:0] display_numbers;
logic [3:0]  dig;
logic        clk_1;
logic        pll_lock;
logic        reset_button_processed;

// Creating the reset signal
logic reset_pll;
logic reset_b;
logic reset;
assign reset_pll = pll_lock & ~pll_lock_q;
assign reset_b   = reset_button_processed & ~reset_button_processed_q;
assign reset     = reset_b | reset_pll;

//Processing input signals to remove metastability
always @(posedge clk_1)begin
  uart_rx_q                <= uart_rx;
  reset_button_q           <= ~reset_button; // Invert button cause it is active low on PCB
  reset_button_processed_q <= reset_button_processed;
  pll_lock_q               <= pll_lock;
end

// Pll is used in design only. When it's testbench 
// clock should be driven manualy.
generate
  if (TESTBENCH == 0) begin
    pll pll_m (
      .inclk0(clk_50),
      .c0    (clk_1),
      .locked(pll_lock)
    );
  end
endgenerate

// Reset button processing
button button_reset_m
(
	.out(reset_button_processed),
	.button(reset_button_q),
	.clock(clk_50),
	.reset(reset)
);

// UART interface
uart_receiver
#(
  .CLK_PER_BIT(UART_CLK_PER_BIT),
  .COUNTER_WIDTH(UART_COUNTER_WIDTH)
) uart_receiver_m (
  .clock(clk_1),
  .reset(reset),
  .Rx(uart_rx_q),
  .data(uart_rx_data),
  .data_ready(uart_rx_data_ready)
);

fifo 
#(
  .DEPTH(FIFO_DEPTH_RX),
  .POINTER_WIDTH(POINTER_WIDTH_RX)
) fifo_uart_rx_m (
  .clock(clk_1),
  .reset(reset),
  
  // Control ports
  .write(uart_rx_data_ready),
  .read(uart_rx_fifo_read),
  
  // Status ports
  .empty(uart_rx_fifo_empty),
  .full(uart_rx_fifo_full),
  
  // Data ports
  .data_in(uart_rx_data),
  .data_out(uart_rx_fifo_data)
);

uart_transmitter
#(
  .CLK_PER_BIT(UART_CLK_PER_BIT),
  .COUNTER_WIDTH(UART_COUNTER_WIDTH)
) uart_transmitter_m (
	.clock(clk_1),
	.reset(reset),
	.data_in(uart_tx_data),
	.start(~uart_tx_fifo_empty),
  .read_data(uart_tx_fifo_read),
	.Tx(uart_tx),
	.transmitter_busy()
);

fifo 
#(
  .DEPTH(FIFO_DEPTH_TX),
  .POINTER_WIDTH(POINTER_WIDTH_TX)
) fifo_uart_tx_m (
  .clock(clk_1),
  .reset(reset),
  
  // Control ports
  .write(uart_tx_fifo_write),
  .read(uart_tx_fifo_read),
  
  // Status ports
  .empty(uart_tx_fifo_empty),
  .full(uart_tx_fifo_full),
  
  // Data ports
  .data_in(uart_tx_fifo_data),
  .data_out(uart_tx_data)
);

// Main controller
control control_m (
  .clock(clk_1),
  .reset(reset),
  
  // UART receiver FIFOs connection
	.uart_rx_fifo_data(uart_rx_fifo_data),
  .uart_rx_fifo_read(uart_rx_fifo_read),
	.uart_rx_fifo_full(uart_rx_fifo_full),
 	.uart_rx_fifo_empty(uart_rx_fifo_empty),
  
  // UART transmitter FIFOs connection
	.uart_tx_fifo_data(uart_tx_fifo_data),
  .uart_tx_fifo_write(uart_tx_fifo_write),
  .uart_tx_fifo_full(uart_tx_fifo_full),
	.uart_tx_fifo_empty(uart_tx_fifo_empty),
  
  // 7-seg indicator control
  .dig(dig),
	.display_numbers(display_numbers)
);

// Display

display display_m (
  .number(display_numbers),
  .dig(dig),
  .one_segment(one_segment)
);

// Invert before output
assign dig_out = ~dig;

endmodule