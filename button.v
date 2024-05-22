// This module processes buttons connected to a FPGA 
// to prevent contact bouncing. The module should be 
// connected directly to the input pin. When the button 
// is pressed, this module output is high. 
// The module is designed to work at 50 MHz.

module button (
	input clock,
	input reset,
	input button,
	output out
);

//// Registers
reg button_q;
reg rstrigger;
reg [15:0] counter;

//// Conditions
wire increment = button_q & ~&counter;
wire decrement = ~button_q & |counter;
wire set_rs    = &counter;
wire reset_rs  = ~|counter;

always @(posedge clock) begin
  button_q <= button;

  if (reset)
    counter <= 0;
    else begin
	   if (increment)
        counter <= counter + 1'b1;
      else	if (decrement)
        counter <= counter - 1'b1;
  end
 
  if (set_rs)
    rstrigger <= 1;
  else if (reset_rs)
    rstrigger <= 0;
	 
end

assign out = rstrigger;

endmodule