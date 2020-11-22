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
   input  wire         go,      // pulse to start the bus cycle
   input  wire 	      clk,     // 100 MHz system-wide master clock
   input  wire 	      reset,   // logic reset
   input  wire        GND,     // ground
   output reg  [63:0] result,  // readback from DS2411
   inout  wire 	      din,     // serial data to and from DS2411
   output reg 	      error,   // HIGH if no device response was detected
   output reg 	      done     // HIGH if a device was detected and the bus cycle carried out
  );
   
   // Set power-up values for 'reg' outputs
   initial begin
      result <= 0;
      error <= 0;
      done <= 0;
   end
   
   // Cause 'tick_1MHz' to go high for one clk cycle per microsecond
   reg tick_1MHz = 0;
   reg tick_1MHz_d1 = 0;
   reg [6:0] count_to_1MHz = 0;
   always @ (posedge clk) begin
       if (count_to_1MHz == 99) begin
           count_to_1MHz <= 0;
           tick_1MHz <= 1;
       end else begin
           count_to_1MHz <= count_to_1MHz + 1;
           tick_1MHz <= 0;
       end
       tick_1MHz_d1 <= tick_1MHz;
   end

// Declare wires and regs
   localparam
     TRANS_START = 630,              // 'transaction start' signal time
     TRANS_WAIT = 240,               // allowed response time after transaction start signal
     DELAY = 40,                     // general delay
     SHORT_DELAY = 15,               // read & write delay between bits (for chargeup)
     ZERO_TIME = 120,                // time for sending a zero
     ONE_TIME = 15;                  // time for sending a one

   reg [7:0]   READ_ROM_CMD = 8'b00110011;  // 0x33 READ ROM command 
   
   reg [63:0]  read_rom;           // register for storing readout (which comes least significant bit first)

   reg [10:0]  count_trans_start;  // helper counter for starting transaction
   reg [8:0]   count_start_response; // helper counter for waiting for response
   reg 	       response_caught;      // helper for catching responses
   reg [3:0]   count_ROM_command_sequence;  // helper counter for sending READ ROM command
   reg [6:0]   count_store_ROM;             // helper counter for storing ROM

   assign din = din_enable ? GND : 1'bz;
   reg         din_enable;
   

// Start state machine
   localparam
     stm0=0, stm1=1, stm2=2, stm3=3,
     stm4=4, stm5=5, stm6=6;
   reg [3:0]   smtm = 0;
   always @ (posedge tick_1MHz_d1) begin
      if (reset) begin
	 smtm <= 3'b0;
      end else begin
	 case(smtm)
	   // State 0: Wait for go
	   stm0:		       
	     begin
		read_rom <= 0;
		count_trans_start <= 0;
		response_caught <= 1'b0;
		count_ROM_command_sequence <= 0;
		count_store_ROM <= 0;
		din_enable <= 0;
		count_start_response <= 0;
				
		if (go) begin
		   smtm <= stm1;
		end else begin
		   smtm <= stm0;
		end
	     end
	   // State 1: Issue transaction start sequence
	   stm1:
	     begin
		din_enable = 1'b1;
		if (count_trans_start == TRANS_START) begin
		   smtm <= stm2;
		   count_trans_start <= 0;
		end else begin
		   count_trans_start <= count_trans_start + 1;
		   smtm <= stm1;
		end		   
	     end
	   // State 2: Deassign din
	   stm2:
	     begin
	        din_enable = 1'b0;
		smtm <= stm3;
	     end
	   // State 3: Wait for response
	   stm3:
	     begin
	        if (count_start_response == 240) begin
		   if (response_caught) begin
		      count_start_response <= 0;
		      response_caught <= 1'b0;
		      smtm <= stm4;
		   end else begin  // if no response end with:
		      count_start_response <= 0;
		      error <= 1'b1; // error set to HIGH
		      done <= 1'b0;  // done set to LOW
		      smtm <= stm0;  // move to State 0
		   end
	        end else begin 
		   if (din == GND) begin
		      response_caught <= 1'b1;
		   end
		   count_start_response = count_start_response + 1;
		   smtm <= stm3;
		end
	     end
	   // State 4: Issue ROM command sequence (8-bit)
	   stm4:
	     begin
		if (count_ROM_command_sequence == 8) begin
		   count_ROM_command_sequence <= 0;
		   smtm <= stm5;
		end else begin // send bits from least significant to most significant
		   din_enable = 1'b1;
		   if (READ_ROM_CMD[count_ROM_command_sequence] == 1'b0) begin
		      repeat (ZERO_TIME) begin
			 @ (posedge tick_1MHz_d1);
		      end
		      din_enable = 1'b0;
		   end else begin
		      repeat (ONE_TIME) begin
			 @ (posedge tick_1MHz_d1);
		      end
		      din_enable = 1'b0;
		      repeat (ZERO_TIME - ONE_TIME) begin
			 @ (posedge tick_1MHz_d1);
		      end
		   end
		   count_ROM_command_sequence = count_ROM_command_sequence + 1;
		   smtm <= stm4;
		end
		repeat (SHORT_DELAY) begin
		   @ (posedge tick_1MHz_d1);
		end
	     end
	   // State 5: Get response (serial code, 64-bit)
	   stm5:
	     begin
		if (count_store_ROM == 64) begin
		   count_store_ROM <= 0;
		   smtm <= stm6;
		end else begin
		   din_enable = 1'b1;
		   repeat (SHORT_DELAY) begin
		      @ (posedge tick_1MHz_d1);
		   end
		   din_enable = 1'b0;
		   repeat (SHORT_DELAY + SHORT_DELAY) begin
	              @ (posedge tick_1MHz_d1);
		   end
		   if (din == GND) begin // Response is stored in read_rom
		      read_rom[63 - count_store_ROM] <= 1'b0;
		   end else begin
		      read_rom[63 - count_store_ROM] <= 1'b1;
		   end
		   repeat (DELAY + DELAY) begin
		      @ (posedge tick_1MHz_d1);
		   end
		   count_store_ROM <= count_store_ROM + 1;
		   smtm <= stm5;
		end
		repeat (SHORT_DELAY) begin
		   @ (posedge tick_1MHz_d1);
		end
	     end
	   // State 6: Set result to read_rom and end by setting done to HIGH and error to LOW
	   stm6:
	     begin
	        result <= read_rom;
		assign done = 1'b1;
		assign error = 1'b0;
		smtm <= stm0;
	     end
	 endcase
      end
   end
endmodule
