// This module contains main control for the UART interface
// and 7-segment indicator. It is able to receive and transmit
// data via the UART interface, and change digits on 7-segment 
// indicator.

module control (
	input clock,
	input reset,
  
  // UART receiver FIFOs connection
	input      [7:0] uart_rx_fifo_data,
  output reg       uart_rx_fifo_read,
	input            uart_rx_fifo_full,
 	input            uart_rx_fifo_empty,
  
  // UART transmitter FIFOs connection
	output reg [7:0] uart_tx_fifo_data,
  output reg       uart_tx_fifo_write,
  input            uart_tx_fifo_full,
	input            uart_tx_fifo_empty,
  
  // 7-seg indicator control
  output reg [3:0]  dig,
	output reg [15:0] display_numbers
);

////Registers
reg [2:0]   next_state, current_state;
reg [1:0]   byte_counter,answer_byte_counter;
reg [7:0]   received_byte, received_byte_q;
reg [18:0]  dig_counter;

// Memory for uart transmissions
reg [7:0] answer_Ok[1:0] = '{8'b0110_1011, 8'b0100_1111};
reg [7:0] answer_Er[1:0] = '{8'b0111_0010, 8'b0100_0101};

// Satates of the state mashine
parameter [2:0] IDLE      = 3'b000, 
                RECEIVE   = 3'b001, 
                CHECK     = 3'b010,
                SET       = 3'b011, 
                ANSWER_OK = 3'b100,
                ANSWER_ER = 3'b110;

// Conditions
wire messege_received = (byte_counter == 2);
wire byte_0_valid     = ~&received_byte_q[7:6] & &received_byte_q[5:4] & ~|received_byte_q[3:2]; // First byte should be in range from 0 to 3. This is equal to the number of 7-seg indicators.
wire byte_1_valid     = ~&received_byte[7:6] & &received_byte[5:4]; // THe second byte should be in range from 0 to 9. This is number to display.
wire answer_sent      = (answer_byte_counter == 2);

// State mashine
always @(*) begin
  case (current_state)
    IDLE: begin
      if (uart_rx_fifo_full) next_state = RECEIVE;
			else next_state = IDLE;
    end
    
		RECEIVE: begin
      if (messege_received) next_state = CHECK;
			else next_state = current_state;
    end
    
		CHECK: begin
      if (byte_0_valid & byte_1_valid) next_state = SET;
			else next_state = ANSWER_ER;
		end
						
		SET: next_state = ANSWER_OK;
		
		ANSWER_OK: begin 
      if (answer_sent) next_state = IDLE;
			else next_state = current_state;
		end				
            
		ANSWER_ER: begin
      if (answer_sent) next_state = IDLE;
			else next_state = current_state;
    end
            
		default: next_state = IDLE;
	endcase
end

// Sequential part of the state machine
always @(posedge clock) begin
	if (reset)  current_state <= IDLE;
	else  current_state <= next_state;
end

// Main receiving logic
always @(posedge clock) begin
  if (reset | next_state != RECEIVE) begin
    //received_byte     <= 0;
    //received_byte_q   <= 0;
      byte_counter      <= 0;
  end else begin
    if (next_state == RECEIVE) begin
      byte_counter      <= byte_counter + 1'b1;
      received_byte     <= uart_rx_fifo_data;
      received_byte_q   <= received_byte;
    end
  end
end

assign uart_rx_fifo_read = (next_state == RECEIVE);

// Save received digit to the output register
always @(posedge clock) begin
  if (reset) display_numbers <= 0;
  else begin
    display_numbers <= display_numbers;
    if (next_state == SET) begin
      case (received_byte_q[1:0])
        2'b00:   display_numbers <= {display_numbers[15:4], received_byte[3:0]};
        2'b01:   display_numbers <= {display_numbers[15:8], received_byte[3:0], display_numbers[3:0]};
        2'b10:   display_numbers <= {display_numbers[15:12], received_byte[3:0], display_numbers[7:0]};
        2'b11:   display_numbers <= {received_byte[3:0], display_numbers[11:0]};
        default: display_numbers <= display_numbers;
      endcase
    end 
  end
end
  
// Write answer into transmit uart fifo
always @(posedge clock) begin
  if (reset) begin
    //uart_tx_fifo_data   <= 0;
    uart_tx_fifo_write  <= 0;
    answer_byte_counter <= 0;
  end else begin
    uart_tx_fifo_write  <= 0;
    answer_byte_counter <= 0;
    if (next_state == ANSWER_OK) begin
      uart_tx_fifo_data   <= answer_Ok[answer_byte_counter];
      answer_byte_counter <= answer_byte_counter + 1'b1;
      uart_tx_fifo_write  <= 1;
    end else if (next_state == ANSWER_ER) begin
      uart_tx_fifo_data   <= answer_Er[answer_byte_counter];
      answer_byte_counter <= answer_byte_counter + 1'b1;
      uart_tx_fifo_write  <= 1;
    end
  end
end

// 7-segment indicator counter
always @(posedge clock) begin
  if (reset) begin
    dig_counter <= 0;
    dig         <= 4'b0001;
  end else begin
    dig_counter <= dig_counter + 1'b1;
    if (dig_counter == 5_000) begin
      dig_counter <= 0;
      dig         <= {dig[0], dig[3:1]};
    end
  end
end

endmodule