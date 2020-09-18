`default_nettype none
`timescale 1ns/1ps

module tb;

    // The usual way to make a Verilog testbench is to define a 'reg'
    // for each input of the "device under test" and to define a
    // 'wire' for each output of the DUT, so that the testbench can
    // store values to be fed into the DUT's inputs and can observe
    // the DUT's outputs.
    reg         clk=0;
    reg         reset=0;

    // Group together 'ibus' and 'obus' signals for internal
    // register-file 'bus' interface
    reg         bwr=0;
    reg         bstrobe=0;  // currently unused
    reg  [15:0] baddr=0, bwrdata=0;
    wire [15:0] brddata;
    wire [33:0] ibus = {clk, bwr, baddr, bwrdata};
    wire [15:0] obus;
    assign brddata = obus;

    reg  [7:0]  adcdat=0;
    wire        single;
    wire [5:0]  offset;
    dynode_trigger dt
      (.clk(clk), .reset(reset), .ibus(ibus), .obus(obus),
       .data_in(adcdat), .single(single), .offset(offset));

    // This is here to let us look at a python variable from the
    // Verilog waveform viewer.
    reg [7:0] pycount = 0;

    // Create a 100 MHz clock on the 'clk' net, since I've always
    // suspected (but never actually verified) that it was faster to
    // do it in Verilog than to do it in the cocotb Python code.
    initial begin
        clk = 0;
        while (1) begin
            #5;  // delay 5 units (which we defined above to be ns)
            clk = !clk;
        end
    end

    // This is needed to create a (compressed) Value Change Dump file
    // in Icarus Verilog, so that we can view the simulation results
    // with gtkwave.  In commercial simulators, this is not necessary.
    initial begin
        $dumpfile("tb.lxt");
        $dumpvars(0, tb);
    end
endmodule

/*
 * A read-only register that lives on the register file "bus" at 16-bit
 * address 'MYADDR' with data width 'W' (W <= 16).
 */
module brorpl #( parameter MYADDR=0, W=16 ) 
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
endmodule  // brorpl

/*
 * A read-write register that lives on the register file "bus" at 16-bit
 * address 'MYADDR' with data width 'W' (W <= 16), and power-up value 'PU'.
 */
module bregpl #( parameter MYADDR=0, W=16, PU=0 ) 
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
endmodule  // bregpl

`default_nettype wire
