`default_nettype none
`timescale 1ns/1ps

module tb;

   reg   [2:0]    ADDRESS;
   reg            ADS_bar;
   reg            CLK;
   reg            EN_bar;
   reg            MR;
   reg            RD_bar;
   reg            WR_bar;

   wire           INTR;
   wire           STPZ;

   // two inouts, not sure if they need to be regs or wires
   reg    [7:0]   DATA;
   reg            DQ;


   reg [31:0] timcnt = 0;
   always @ (posedge CLK) timcnt <= timcnt + 1;

   ds1wm dt
     (.ADDRESS(ADDRESS), .ADS_bar(ADS_bar), .CLK(CLK), .EN_bar(EN_bar),
      .MR(MR), .RD_bar(RD_bar), .WR_bar(WR_bar), .INTR(INTR),
      .STPZ(STPZ), .DATA(DATA), .DQ(DQ));

   reg    [7:0]   pycount = 0;

   initial begin
      CLK = 0;
      while (1) begin
	 // need to check tick rate of clock on ds2411 chip
	 #500;  // delay 500 units (500ns = 0.5us)
	 CLK = !CLK;
      end
   end

   initial begin
      $dumpfile("tb.lxt");
      $dumpvars(0, tb);
   end
endmodule
