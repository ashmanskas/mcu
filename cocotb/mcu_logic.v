/*
 * mcu_logic.v
 * 
 * Algorithmic logic for prototype Master Coincidence Unit, omitting
 * the Xilinx-specific details to simplify simulation
 * 
 * begun 2020-06-25 by wja and sz
 */

`timescale 1ns / 1ps
`default_nettype none

module mcu_logic
  (
   // 100 MHz system-wide master clock (generated on MCU)
   input  wire        clk,
   // Register file "bus" for control & monitoring via network
   input  wire [15:0] baddr,
   input  wire [15:0] bwrdata,
   output wire [15:0] brddata,
   input  wire        bwr,
   input  wire        bstrobe,
   // For each ROCSTAR <-> MCU connector, 8 bits in and 4 bits out
   input  wire [7:0]  A1in, A2in, A3in, A4in,
   output wire [3:0]  A1out, A2out, A3out, A4out,
   input  wire [7:0]  B1in, B2in, B3in, B4in,
   output wire [3:0]  B1out, B2out, B3out, B4out
   );
    // Instantiate register file "bus" I/O
    wire [33:0] ibus = {clk, bwr, baddr, bwrdata};
    wire [15:0] obus;
    assign brddata = obus;
    bror #(16'h0000) r0000(ibus, obus, 16'h1234);  // read-only register
    wire [15:0] q0001;
    breg #(16'h0001) r0001(ibus, obus, q0001);  // dummy read/write register
    // We'll create some sort of reset logic later
    reg rst = 0;
    // Instantiate a module to process each of the 8 cables;
    // this is highly oversimplified for now
    cable A1 (.clk(clk), .rst(rst), .in(A1in), .out(A1out));
    cable A2 (.clk(clk), .rst(rst), .in(A2in), .out(A2out));
    cable A3 (.clk(clk), .rst(rst), .in(A3in), .out(A3out));
    cable A4 (.clk(clk), .rst(rst), .in(A4in), .out(A4out));
    cable B1 (.clk(clk), .rst(rst), .in(B1in), .out(B1out));
    cable B2 (.clk(clk), .rst(rst), .in(B2in), .out(B2out));
    cable B3 (.clk(clk), .rst(rst), .in(B3in), .out(B3out));
    cable B4 (.clk(clk), .rst(rst), .in(B4in), .out(B4out));
endmodule  // mcu_logic

/*
 * Module containing logic to process a given ROCSTAR <-> MCU cable.
 * The inputs/outputs will become more complicated once we start
 * trying to detect coincidences.
 */
module cable
  (
   input  wire       clk,  // 100 MHz clock
   input  wire       rst,  // synchronous reset
   input  wire [7:0] in,   // 8-bit input data (from ROCSTAR)
   output reg  [3:0] out   // 4-bit output data (to ROCSTAR)
   );
    // Initialize registered outputs to avoid 'X' values in simulation at t=0
    initial begin
        out <= 4'b0000;
    end
    // Mnemonic names for output values written to cable
    localparam O_IDLE0 = 4'b0111;
    localparam O_IDLE1 = 4'b1011;
    localparam O_IDLE2 = 4'b1101;
    localparam O_IDLE3 = 4'b1110;
    // Mnemonic names for Finite State Machine states
    localparam START = 0, IDLE1 = 1, IDLE2 = 2, IDLE3 = 3;
    reg [1:0] fsm = START;  // flip-flop
    reg [1:0] fsm_prev = START;  // flip-flop: keep track of previous state
    reg [1:0] fsm_d = START;  // combinational logic
    reg [3:0] out_d;  // combinational logic
    reg [31:0] ticks = 0;  // useful to display time in units of 'clk'
    always @ (posedge clk) begin
        // Update 'fsm' FF from 'fsm_d' next-state value, except on reset
        if (rst) begin
            fsm <= START;
        end else begin
            fsm <= fsm_d;
        end
        // Update 'out' FF from 'out_d' next value
        out <= out_d;
        // Previous state on next clock is what 'fsm' is now
        fsm_prev <= fsm;
        // Increment 'ticks' counter
        ticks <= ticks + 1'd1;
    end
    // This COMBINATIONAL always block contains the next-state logic
    // and other state-dependent combinational logic.
    always @ (*) begin
        // Assign default values to avoid risk of implicit latches
        fsm_d = START;
        out_d = 4'b0000;
        if (0) $strobe("fsm_d=%1d fsm=%1d fsm_prev=%1d @%1d",
                       fsm_d, fsm, fsm_prev, ticks);
        case (fsm)
            START:
              begin
                  out_d = O_IDLE0;
                  fsm_d = IDLE1;
              end
            IDLE1:
              begin
                  out_d = O_IDLE1;
                  fsm_d = IDLE2;
              end
            IDLE2:
              begin
                  out_d = O_IDLE2;
                  fsm_d = IDLE3;
              end
            IDLE3:
              begin
                  out_d = O_IDLE3;
                  fsm_d = START;
              end
            default:
              begin
                  $strobe("INVALID STATE: fsm=%d fsm_prev=%d @%1d", 
                          fsm, fsm_prev, ticks);
                  fsm_d = START;
              end
        endcase
    end
    
    
endmodule  // cable

/*
 * A read-only register that lives on the register file "bus" at 16-bit
 * address 'MYADDR' with data width 'W' (W <= 16).
 */
module bror #( parameter MYADDR=0, W=16 ) 
  (
   input  wire [1+1+16+16-1:0] i,  // bus inputs, combined for concision
   output wire [15:0]          o,  // bus output, abbreviated for concision
   input  wire [W-1:0]         d   // data to place on bus at this address
   );
    wire        clk, wr;
    wire [15:0] addr, wrdata;
    wire [15:0] rddata;
    assign {clk, wr, addr, wrdata} = i;  // pick apart contents of 'i'
    assign o = {rddata};
    // The real work happens below
    wire addrok = (addr==MYADDR);  // Does requested addr match my address?
    // If address matches, put 'd' onto 'rddata' bus; else "high impedance".  
    // See "Three-state logic" in wikipedia, e.g.
    assign rddata = addrok ? d : 16'bz;
endmodule  // bror

/*
 * A read-write register that lives on the register file "bus" at 16-bit
 * address 'MYADDR' with data width 'W' (W <= 16), and power-up value 'PU'.
 */
module breg #( parameter MYADDR=0, W=16, PU=0 ) 
  (
   input  wire [1+1+16+16-1:0] i,  // bus inputs, combined for concision
   output wire [15:0]          o,  // bus output, abbreviated for concision
   output wire [W-1:0]         q   // copy of internal register value
   );
    wire        clk, wr;
    wire [15:0] addr, wrdata;
    wire [15:0] rddata;
    assign {clk, wr, addr, wrdata} = i;  // pick apart contents of 'i'
    assign o = {rddata};
    // The real work happens below
    reg [W-1:0] regdat = PU;  // Define register with power-up value 'PU'
    wire addrok = (addr==MYADDR);  // Does requested addr match my address?
    // If address matches, put current contents of 'reg' onto 'rddata' bus;
    // else "high impedance," i.e. this instance leaves 'rddata' undisturbed
    // unless the address matches.
    assign rddata = addrok ? regdat : 16'bz;
    // If address matches and a write cycle is requested, then update the
    // contents of register 'regdat' from the 'wrdata' contents of the bus.
    always @ (posedge clk)
      if (wr && addrok)
        regdat <= wrdata[W-1:0];
    // Let the outside world see the current contents of 'regdat'
    assign q = regdat;
endmodule  // breg

`default_nettype wire
