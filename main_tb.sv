// This testbench will exercise the whole module.
// It sends out a few bytes via UART interface.
// It then exercises the receive by receiving answer
// from the module.

`timescale 1us / 100ns

module main_tb();

// Testbench uses only 1 MHz frequency after PLL
// Baud rate of the UART is 9600
// CLOCK_PER_BIT = round(CLK_PERIOD_US * BIT_DURATION_US) = 104
parameter 		 CLK_PERIOD       = 1.0;
parameter 		 UART_CLK_PER_BIT = 104;

// Test bytes which will be sent via uart
parameter [7:0] TEST_BYTE_1  = 8'b0011_0011,  // 3
                TEST_BYTE_2  = 8'b0011_0101,  // 5
                TEST_BYTE_3  = 8'b0011_0000,  // 0
                TEST_BYTE_4  = 8'b0011_0011,  // 3
                TEST_BYTE_5  = 8'b0011_0001,  // 1
                TEST_BYTE_6  = 8'b0011_0011;  // 3

// DUT module inputs
reg   uart_rx;

// DUT module connections
wire        uart_tx;
wire  [6:0] one_segment;
wire  [3:0] dig_out;

// DUT
main #(
  .UART_CLK_PER_BIT(104),
  .UART_COUNTER_WIDTH(7),
  .FIFO_DEPTH_RX(2),
  .POINTER_WIDTH_RX(1),
  .FIFO_DEPTH_TX(8),
  .POINTER_WIDTH_TX(4),
  .TESTBENCH(1)
) main_dut (
	.reset_button(1),
	.clk_50(0),
	.uart_rx(uart_rx),
	.uart_tx(uart_tx),
	.one_segment(one_segment),
	.dig_out(dig_out)
);

// Initiate all inputs and outputs at time 0.
task init();
  uart_rx        <= 1;
  main_dut.reset <= 0;
  main_dut.clk_1 <= 0;
endtask

// Reset the module
task reset_pulse();
  #(CLK_PERIOD);
  main_dut.reset <= 1;
  #(CLK_PERIOD);
  main_dut.reset <= 0;
  #(CLK_PERIOD);
endtask

// Start the clock signal
always #(CLK_PERIOD/2) main_dut.clk_1 <= ~main_dut.clk_1;

// Send one byte via the uart interface
// Task also checks if the data was received correctly
task send_byte (
  input [7:0] tx_byte
);
  integer i;
  
  begin
    // Start bit
    uart_rx <= 0;
    #(UART_CLK_PER_BIT);
    
    // Data
    for (i=0; i < 8; i=i+1) begin
      uart_rx <= tx_byte[i];
      #(UART_CLK_PER_BIT);
    end
    
    // Checking if the receiving was successful.
    if (main_dut.uart_rx_data == tx_byte) $display("UART reception succeed.");
    else $display("UART reception failure!");
    
    // Stop bit
    uart_rx <= 1;
    #(UART_CLK_PER_BIT);
  end
endtask

// Main simulation cycle
initial begin
  init();
  reset_pulse();
  #(CLK_PERIOD);
  send_byte(TEST_BYTE_1); #(0.2);
  send_byte(TEST_BYTE_2); #(0.4);
  send_byte(TEST_BYTE_3); #(0.6);
  send_byte(TEST_BYTE_4); #(0.8);
  send_byte(TEST_BYTE_5); #(1.1);
  send_byte(TEST_BYTE_6); #(1.3);
end

// Add signals to simulation

endmodule