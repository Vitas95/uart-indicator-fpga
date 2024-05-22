// This module contains the fifo module.
// It has 8 bit word and 8 byte depth.

module fifo 
#(
  parameter DEPTH         = 8,
  parameter POINTER_WIDTH = 3
)(
  input   clock,
  input   reset,
  
  // Control ports
  input   write,
  input   read,
  
  // Status ports
  output  empty,
  output  full,
  
  // Data ports
  input  [7:0] data_in,
  output [7:0] data_out
);

reg [POINTER_WIDTH:0] write_pointer;
reg [POINTER_WIDTH:0] read_pointer;
reg [7:0] mem[DEPTH-1:0];

// Main logic
always @(posedge clock) begin
  if (reset) begin
    write_pointer <= 0;
    read_pointer  <= 0;
  end else begin
    
    if (write) begin
      mem[write_pointer] <= data_in;
      write_pointer      <= write_pointer + 1'b1;
    end
    
    if (read) begin
      read_pointer <= read_pointer + 1'b1;
    end
  end
end

// Output data
assign data_out = mem[read_pointer[POINTER_WIDTH-1:0]];

// Assign status ports
assign empty = (write_pointer[POINTER_WIDTH-1:0] == read_pointer[POINTER_WIDTH-1:0]) & (write_pointer[POINTER_WIDTH] == read_pointer[POINTER_WIDTH]);
assign full  = (write_pointer[POINTER_WIDTH-1:0] == read_pointer[POINTER_WIDTH-1:0]) & (write_pointer[POINTER_WIDTH] != read_pointer[POINTER_WIDTH]);

endmodule