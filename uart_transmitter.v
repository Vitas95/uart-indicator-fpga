// This file contains a UART transmitter. This receiver is able to
// transmit 8 bits of serial data, one start bit, one stop bit,
// and no parity bit. When transmission is ongoing transmitter_busy is
// driven high. Transmission starts when start input is high.
//
// Set Parameter CLKS_PER_BIT as follows:
// CLKS_PER_BIT = (Frequency of clock)/(Frequency of UART)
// Example: 1 MHz clock, 115200 baud UART
// (1000000)/(9600) = 104
// COUNTER_WIDTH = 2^COUNTER_WIDTH- size of the counter to count CLKS_PER_BIT
// 2^COUNTER_WIDTH

module uart_transmitter
#(
  parameter CLK_PER_BIT = 104,
  parameter COUNTER_WIDTH = 7
)(
	input       clock,
	input       reset,
	input [7:0] data_in,
	input       start,
  output      read_data,
	output reg  Tx,
	output      transmitter_busy
);

//// Registers
reg [2:0]               current_state;	
reg [2:0]               next_state;
reg [COUNTER_WIDTH-1:0] counter;	    //	This counter will identify the center of the transmitted bit
reg [3:0]               bit_counter;	// Count number of the received beams
reg [7:0]               data; 	      // Data from this register goes to the Tx output

//// Conditions
wire next_bit = (counter == CLK_PER_BIT-1);
wire last_bit = (bit_counter == 8);

// States of the state machine
parameter [2:0] IDLE      = 3'b000,
                READ_DATA = 3'b001,
                START_BIT = 3'b010,
                DATA      = 3'b011,
                STOP_BIT  = 3'b100;

// State machine
always @(*) begin
  case (current_state)
  
    IDLE: begin
      if (start) next_state = READ_DATA;
      else next_state = IDLE;
    end
    
    READ_DATA: next_state = START_BIT;
    
    START_BIT: begin
      if (next_bit) next_state = DATA;
      else next_state = START_BIT;
    end
    
    DATA: begin
      if (last_bit) next_state = STOP_BIT;
      else next_state = DATA;
    end
    
    STOP_BIT: begin
      if (next_bit) next_state = IDLE;
      else next_state = STOP_BIT;
    end
    
    default: next_state = IDLE;
  endcase
end

// Sequential part of the state machine
always @(posedge clock) begin
  if (reset) current_state <= IDLE;
  else current_state <= next_state;
end

// Main logic
always @(posedge clock) begin
  if (reset | next_state == IDLE) begin
    Tx          <= 1;
    data        <= 0;
    counter     <= 0;
    bit_counter <= 0;
  end else begin
    // Counter
    counter <= counter + 1'b1;
    if (next_bit) counter <= 0;
    
    // Load data for transmission 
    if (next_state == READ_DATA) data <= data_in;
    
    // Data transmission
    if (next_state == START_BIT) Tx <= 0;
    else if (current_state == DATA) begin
      Tx <= data[0];
      if (next_bit) begin
        data        <= {1'b0, data[7:1]};
        bit_counter <= bit_counter + 1'b1;
      end
    end else if (next_state == STOP_BIT) Tx <= 1;
    
  end
end

assign transmitter_busy = (next_state != IDLE);
assign read_data        = (next_state == READ_DATA);

endmodule