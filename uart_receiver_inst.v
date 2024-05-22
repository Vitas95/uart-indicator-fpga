// Copyright (C) 2023  Intel Corporation. All rights reserved.
// Your use of Intel Corporation's design tools, logic functions 
// and other software and tools, and any partner logic 
// functions, and any output files from any of the foregoing 
// (including device programming or simulation files), and any 
// associated documentation or information are expressly subject 
// to the terms and conditions of the Intel Program License 
// Subscription Agreement, the Intel Quartus Prime License Agreement,
// the Intel FPGA IP License Agreement, or other applicable license
// agreement, including, without limitation, that your use is for
// the sole purpose of programming logic devices manufactured by
// Intel and sold by Intel or its authorized distributors.  Please
// refer to the applicable agreement for further details, at
// https://fpgasoftware.intel.com/eula.


// Generated by Quartus Prime Version 22.1 (Build Build 922 07/20/2023)
// Created on Wed May 22 20:36:30 2024

uart_receiver uart_receiver_inst
(
	.clock(clock_sig) ,	// input  clock_sig
	.reset(reset_sig) ,	// input  reset_sig
	.Rx(Rx_sig) ,	// input  Rx_sig
	.data(data_sig) ,	// output [7:0] data_sig
	.data_ready(data_ready_sig) 	// output  data_ready_sig
);

defparam uart_receiver_inst.CLK_PER_BIT = 104;
defparam uart_receiver_inst.COUNTER_WIDTH = 7;
