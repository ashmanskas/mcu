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
   input  wire        GND,     // ground
   output reg  [63:0] result,  // readback from DS2411
   inout  wire 	      din,     // serial data to and from DS2411
   output reg 	      error,   // HIGH if no device response was detected
   output reg 	      done,    // HIGH if a device was detected and the bus cycle carried out
   output reg         working  // HIGH if in logic loop
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
   reg [7:0]   count_ROM_cmd_bit;
   reg [4:0]   count_chargeup_delay;
   reg [4:0]   count_pull_low;
   reg [5:0]   count_let_float;
   reg [7:0]   count_sample_line;

   assign din = din_enable ? GND : 1'bz;
   reg         din_enable;
   

   // Start state machine
   localparam
     stm0=0, stm1=1, stm2=2, stm3=3,
     stm4=4, stm5=5, stm6=6, stm7=7,
     stm8=8, stm9=9, stm10=10, stm11=11,
     stm12=12, stm13=13;
   reg [4:0]   smtm = 0;
   always @ (posedge tick_1MHz_d1) begin
      if (reset) begin
	 done <= 0;
	 error <= 0;
	 working <= 0;
	 smtm <= stm0;
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
		count_ROM_cmd_bit <= 0;
		count_chargeup_delay <= 0;
		count_pull_low <= 0;
		count_let_float <= 0;
		count_sample_line <= 0;
		if (go) begin
		   working <= 1;
		   done <= 0;
		   error <= 0;
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
		      error <= 1; // error set to HIGH
		      done <= 0;  // done set to LOW
		      working <= 0;
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
		   smtm <= stm8;
		end else begin // send bits from least significant to most significant
		   din_enable <= 1'b1;
		   if (READ_ROM_CMD[count_ROM_command_sequence] == 1'b0) begin
		      smtm <= stm5;
		   end else begin
		      smtm <= stm6;
		   end
		end
	     end
	   // State 5: Send ZERO
	   stm5:
	     begin
		if (count_ROM_cmd_bit == ZERO_TIME) begin
		   count_ROM_cmd_bit <= 0;
		   count_ROM_command_sequence = count_ROM_command_sequence + 1;
		   din_enable <= 1'b0;
		   smtm <= stm7;
		end else begin
		   count_ROM_cmd_bit <= count_ROM_cmd_bit + 1;
		   smtm <= stm5;
		end
	     end
	   // State 6: Send ONE
	   stm6:
	     begin
		if (count_ROM_cmd_bit == ZERO_TIME) begin
		   count_ROM_cmd_bit <= 0;
		   count_ROM_command_sequence = count_ROM_command_sequence + 1;
		   smtm <= stm7;
		end else if (count_ROM_cmd_bit == ONE_TIME) begin
		   count_ROM_cmd_bit <= count_ROM_cmd_bit + 1;
		   din_enable <= 1'b0;
		   smtm <= stm6;
		end else begin
		   count_ROM_cmd_bit <= count_ROM_cmd_bit + 1;
		   smtm <= stm6;
		end
	     end
	   // State 7: Charge up delay for ROM command
	   stm7:
	     begin
		if (count_chargeup_delay == SHORT_DELAY) begin
		   count_chargeup_delay <= 0;
		   smtm <= stm4;
		end else begin
		   count_chargeup_delay <= count_chargeup_delay + 1;
		   smtm <= stm7;
		end
	     end
	   // State 8: Get response (serial code, 64-bit)
	   stm8:
	     begin
		if (count_store_ROM == 64) begin
		   count_store_ROM <= 0;
		   smtm <= stm13;
		end else begin
		   din_enable = 1'b1;
		   smtm <= stm9;
		end
	     end
	   // State 9: Pull line low (Start READ)
	   stm9:
	     begin
		if (count_pull_low == SHORT_DELAY) begin
		   count_pull_low <= 0;
		   din_enable <= 1'b0;
		   smtm <= stm10;
		end else begin
		   count_pull_low <= count_pull_low + 1;
		   smtm <= stm9;
		end
	     end
	   // State 10: Let line float
	   stm10:
	     begin
		if (count_let_float == 5) begin
		   count_let_float <= 0;
		   smtm <= stm11;
		end else begin
		   count_let_float <=  count_let_float + 1;
		   smtm <= stm10;
		end
	     end
	   // State 11: Sample line
	   stm11:
	     begin
		if (count_sample_line == 0) begin
		   if (din == GND) begin // Response is stored in read_rom
		      read_rom[63 - count_store_ROM] <= 1'b0;
		      count_sample_line <= count_sample_line + 1;
		      count_store_ROM <= count_store_ROM + 1;
		   end else begin
		      read_rom[63 - count_store_ROM] <= 1'b1;
		      count_sample_line <= count_sample_line + 1;
		      count_store_ROM <= count_store_ROM + 1;
		   end
		end else if (count_sample_line == DELAY + DELAY + SHORT_DELAY + SHORT_DELAY - 5) begin
		   count_sample_line <= 0;
		   smtm <= stm12;
		end else begin
		   count_sample_line <= count_sample_line + 1;
		   smtm <= stm11;
		end
	     end
	   // State 12: Charge up delay
	   stm12:
	     begin
		if (count_chargeup_delay == SHORT_DELAY) begin
		   count_chargeup_delay <= 0;
		   smtm <= stm8;
		end else begin
		   count_chargeup_delay <= count_chargeup_delay + 1;
		   smtm <= stm12;
		end
	     end
	   // State 13: Set result to read_rom and end by setting done to HIGH and error to LOW
	   stm13:
	     begin
	        result <= read_rom;
	        done <= 1;
	        error <= 0;
	        working <= 0;
		smtm <= stm0;
	     end
	 endcase
      end
   end
endmodule
