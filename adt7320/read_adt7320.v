/*
 * read_adt7320.v
 * 
 * Read out temperature data from ADT7320 chip
 * 
 * begun 2020-09-11 by wja, em, sz, mj, mt
 */

`timescale 1ns / 1ps
`default_nettype none

module read_adt7320
  (
   input  wire        clk,     // 100 MHz system-wide master clock
   input  wire        reset,   // logic reset (may not be needed?)
   input  wire [2:0]  addr,    // address bits in ADT7320 command byte
   output reg  [15:0] result,  // data read back from 7320
   output reg         cs,      // chip-select* wire to 7320
   output reg         sclk,    // serial clock to 7320
   output reg         din,     // serial data to 7320
   input  wire        dout     // serial data read back from 7320
   );
    // Set power-up values for 'reg' outputs
    initial begin
        result = 0;
        cs = 1;
        sclk = 1;
        din = 1;
    end
    // Cause 'tick_1MHz' to go high for one clk cycle per microsecond
    reg tick_1MHz = 0;
    reg tick_1MHz_d1 = 0;  // delayed-one-clk version of tick_1MHz
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
    // Finite State Machine to issue commands and collect responses
    localparam
      START=0,    SELECT=1, COMMAND=2,  CMD1=3,
      RESPONSE=4, RESP1=5,  DESELECT=6, PAUSE=7;
    reg [2:0] fsm = START;
    reg [2:0] fsm_d;  // combinational, not flipflop
    // These are the outputs of the FSM: some combinational, some flipflop
    // 8-bit command byte to send to the 7320
    reg [7:0] cmdbyte = 0;  // ff
    reg [7:0] cmdbyte_d;  // comb
    reg cmdbyte_ena;  // comb
    // CS, DIN, and SCLK serial inputs to the 7320
    reg cs_d, cs_ena;  // comb
    reg din_d, din_ena;  // comb
    reg sclk_d, sclk_ena;  // comb
    // Count ticks of the serial operation
    reg [7:0] count = 0;  // ff
    reg count_clr, count_inc;  // comb
    // Accumulate transient copy of response read back from 7320
    reg [15:0] resp = 0;  // ff
    reg [15:0] resp_d;  // comb
    reg resp_ena;  // comb
    // Copy transient 'resp' into output 'result'
    reg result_ena;  // comb
    // Synchronous update logic for FSM
    always @ (posedge clk) begin
        if (reset) begin
            fsm <= START;
        end else if (tick_1MHz) begin
            fsm <= fsm_d;
        end
        if (tick_1MHz_d1) begin
            if (cmdbyte_ena) begin
                cmdbyte <= cmdbyte_d;
            end
            if (cs_ena) begin
                cs <= cs_d;
            end
            if (din_ena) begin
                din <= din_d;
            end
            if (sclk_ena) begin
                sclk <= sclk_d;
            end
            if (count_clr) begin
                count <= 0;
            end else if (count_inc) begin
                count <= count + 1;
            end
            if (resp_ena) begin
                resp <= resp_d;
            end
            if (result_ena) begin
                result <= resp;
            end
        end
    end
    always @ (*) begin
        fsm_d = START;
        cmdbyte_d = 0;
        cmdbyte_ena = 0;
        cs_d = 1;
        cs_ena = 0;
        din_d = 1;
        din_ena = 0;
        sclk_d = 1;
        sclk_ena = 0;
        count_clr = 0;
        count_inc = 0;
        resp_d = 0;
        resp_ena = 0;
        result_ena = 0;
        case (fsm)
            START:
              begin
                  cmdbyte_d[7]   = 0;
                  cmdbyte_d[6]   = 1;     // read/write* (1=read)
                  cmdbyte_d[5:3] = addr;  // address which 7320 register
                  cmdbyte_d[2:0] = 0;
                  cmdbyte_ena = 1;
                  cs_d = 1;  // deassert 7320 chip-select*
                  cs_ena = 1;
                  din_d = 1;  // send a '1' to 7320 DIN when idle
                  din_ena = 1;
                  sclk_d = 1;  // send a '1' to 7320 SCLK when idle
                  sclk_ena = 1;
                  fsm_d = SELECT;
              end
            SELECT:
              begin
                  cs_d = 0;  // assert 7320 chip-select*
                  cs_ena = 1;
                  count_clr = 1;  // clear bit counter
                  resp_d = 0;  // initialize response to zero
                  resp_ena = 1;
                  fsm_d = COMMAND;
              end
            COMMAND:
              begin
                  count_inc = 1;
                  din_d = cmdbyte[7];
                  din_ena = 1;
                  sclk_d = 0;
                  sclk_ena = 1;
                  fsm_d = CMD1;
              end
            CMD1:
              begin
                  cmdbyte_d[7:0] = {cmdbyte[6:0], 1'b0};  // shift left
                  sclk_d = 1;
                  sclk_ena = 1;
                  if (count == 8) begin
                      fsm_d = RESPONSE;
                  end else begin
                      fsm_d = COMMAND;
                  end
              end
            RESPONSE:
              begin
                  count_inc = 1;
                  sclk_d = 0;
                  sclk_ena = 1;
                  fsm_d = RESP1;
              end
            RESP1:
              begin
                  sclk_d = 1;
                  sclk_ena = 1;
                  resp_d = {resp[14:0], dout};  // shift left
                  resp_ena = 1;
                  if (count == 24) begin
                      fsm_d = DESELECT;
                  end else begin
                      fsm_d = RESPONSE;
                  end
              end
            DESELECT:
              begin
                  cs_d = 1;  // deassert 7320 chip-select*
                  cs_ena = 1;
                  result_ena = 1;
                  fsm_d = PAUSE;
              end
            PAUSE:
              begin
                  count_inc = 1;
                  if (count == 48) begin
                      fsm_d = START;
                  end else begin
                      fsm_d = PAUSE;
                  end
              end
            default:
              begin
                  $strobe("INVALID STATE: fsm=%d", fsm);
                  fsm_d = START;
              end
        endcase
    end
endmodule  // read_adt7320

`default_nettype wire
