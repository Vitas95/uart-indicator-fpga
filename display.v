// This module control 7-segment LED indicator.
// It converts input four digits with decoder to display it 
// on a seven-segment display in common anode configuration
// (aclive low).

module display (
  input [15:0] number,
  input [3:0] dig,
  output reg [6:0] one_segment
);

////Registers
reg [3:0] current_digit;

always @(number or dig) begin
	case(dig)
		4'b0001:  current_digit = number[3:0];
		4'b0010:  current_digit = number[7:4];
		4'b0100:  current_digit = number[11:8];
		4'b1000:  current_digit = number[15:12];
		default:  current_digit = number[3:0];
	endcase
end

always @(current_digit) begin
	case (current_digit)
		4'b0000: one_segment = 7'b1000000;
		4'b0001: one_segment = 7'b1111001;
		4'b0010: one_segment = 7'b0100100;
		4'b0011: one_segment = 7'b0110000;
		4'b0100: one_segment = 7'b0011001;
		4'b0101: one_segment = 7'b0010010;
		4'b0110: one_segment = 7'b0000010;
		4'b0111: one_segment = 7'b1111000;
		4'b1000: one_segment = 7'b0000000;
		4'b1001: one_segment = 7'b0010000;
		default: one_segment = 7'b1000000;
	endcase
end

endmodule