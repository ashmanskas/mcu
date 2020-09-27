/*
 * read_ds2411.v
 *
 * Read out serial number from DS2411 chip
 *
 * begun 2020-09-12 by mt
 */

`timescale 1ns / 1ps
`default_nettype none

module read_ds2411
  (
   input  wire        go,      // pulse to start the bus cycle
   input  wire 	      clk,     // 100 MHz system-wide master clock
   input  wire 	      reset,   // logic reset
   output reg  [63:0] result,  // readback from DS2411
   inout  wire 	      din,     // serial data to and from DS2411
   output wire 	      error,   // HIGH if no device response was detected
   output wire 	      done     // HIGH if a device was detected and the bus cycle carreid out
  );
   // Set power-up values for 'reg' outputs
   initial begin
       result = 0;
       din = 0;
   end
   // Cause 'tick_1MHz' to go high for one clk cycle per microsecond
   reg tick_1MHz = 0;
   reg tick_1MHz_d1 = 0;
   reg [6:0] count_to_1MHz = 0;
   always @ (posedge clk) begin
       if (count_to_1MHz == 99) begin
           count_to_1MHz <= 0;
           tick+1MHz <= 1;
       end else begin
           count_to_1MHz <= count_to_1MHz + 1;
           tick_1MHz <= 0;
       end
       tick_1MHz_d1 <= tick_1MHz;
   end

// Declare wires and regs:  (reg) read_rom

// Issue transaction start sequence
// Wait for response
// if no response -> end with error set to HIGH and done set to LOW

	// Issue ROM command sequence (8-bit)
        // Get response (serial code, 64-bit)
        // Store it in the result reg

// End with done set to HIGH and error set to LOW
