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

    wire [7:0] mcu_trigger_out;
    wire event_trigger_out;
    wire [23:0] event_time_out;
    wire enecor_load;
    wire [23:0] dyn_evntim;
    wire [7:0] pulookup;
    wire [11:0] dyn_enecor;

    reg [7:0] timcnt=0;
    reg [3:0] dynadcdly=0;
    reg [1:0] selecttime=0;
    reg [3:0] smoothpmt=0;
    reg [11:0] integcntl=0;

    wire [7:0] adc_delay;
    wire [11:0] sum_integ;

    reg [1:0] trigger_data_mode=0;
    reg [3:0] integration_pipeline_len=0;
    reg [4:0] data_pipeline_len=0;
    reg [1:0] trigger_channel_select=0;

    reg trigger=0;
    reg trigger_data_fifo_ren=0;
    wire [15:0] trigger_data_fifo_q;
    wire trigger_data_fifo_ne;
    wire trigger_data_fifo_full;

   reg [7:0] evnt_timsd_temp;
   

    always @ (posedge clk) timcnt <= timcnt + 1;

    dynode_trigger_roger dtr
      (.clk(clk), .reset(reset), .ibus(ibus), .obus(obus),
       .data_in(adcdat),
       .MCU_trigger_out(mcu_trigger_out),
       .event_trigger_out(event_trigger_out),
       .event_time_out(event_time_out),
       .enecor_load(enecor_load),
       .dyn_evntim(dyn_evntim),
       .pulookup(pulookup),
       .dyn_enecor(dyn_enecor),
       .timcnt(timcnt),
       .dynadcdly(dynadcdly),
       .selecttime(selecttime),
       .smoothpmt(smoothpmt),
       .integcntl(integcntl),
       .adc_delay(adc_delay),
       .sum_integ(sum_integ),
       .trigger_data_mode(trigger_data_mode),
       .integration_pipeline_len(integration_pipeline_len),
       .data_pipeline_len(data_pipeline_len),
       .trigger_channel_select(trigger_channel_select),
       .trigger(trigger),
       .trigger_data_fifo_ren(trigger_data_fifo_ren),
       .trigger_data_fifo_q(trigger_data_fifo_q),
       .trigger_data_fifo_ne(trigger_data_fifo_ne),
       .trigger_data_fifo_full(trigger_data_fifo_full),
       .evnt_timsd_temp(evnt_timsd_temp));

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

/*
 * Single-clock 33-bit-wide FIFO, depth 2048 words
 */
module fifo33  #( parameter W=33 )
  (
   input wire          clk,
   input wire	       rst,
   input wire [W-1:0]  d,
   input wire          wen,
   input wire          ren,
   output wire [W-1:0] q,
   output wire         nempty,
   output wire [15:0]  nwords,
   output wire         nearlyfull
   );

    //register reset signal to reduce clock skew
    reg rst_local = 1'b0;
    always @ (posedge clk) rst_local <= rst;

    reg [W-1:0] mem [2047:0];
    integer i;
    initial begin
        for (i=0; i<2048; i=i+1) mem[i] = 0;
    end
    reg [10:0]  wptr = 0;
    reg [10:0]  rptr = 0;
    wire [10:0] nword = wptr-rptr;
    reg 	nearlyfullreg = 0, veryfull = 0;
    assign nempty = (nword!=0);
    assign nwords = nword;
    assign nearlyfull = nearlyfullreg;
    reg [W-1:0] qreg = 0;
    assign q = qreg;
    always @ (posedge clk) begin
	if(rst_local) begin
	    wptr <= 11'b0;
	    rptr <= 11'b0;
	end else begin
	    if (wen && !veryfull) begin
		// On write-enable, write word to memory and increment pointer
		mem[wptr] <= d;
		wptr <= wptr + 1'd1;
	    end
	    if (ren && nempty) begin
		qreg <= mem[rptr];
		rptr <= rptr + 1'd1;
	    end else if (ren) begin
		qreg <= 1'd0;
	    end
	    nearlyfullreg <= (nword[10:8]==3'b111);
	    veryfull <= (nword[10:2]==9'h1ff);
	end
    end
endmodule // fifo33

`default_nettype wire
