//`define OW_SWITCH

module tc_ds1wm (ADDR,ADS_N,CLK,EN_N,RD_N,WR_N,MR,INTR,DATA,IO,STPZ);

   output [2:0] ADDR;
   output	ADS_N;
   output	CLK;
   output	EN_N;
   output	RD_N;
   output	WR_N;
   output	MR;



   input       INTR;

   inout [7:0] DATA;


   inout       IO;
   input	STPZ;
   
   reg MR;
   

   
`ifdef OW_SWITCH

   reg [63:0]  ROMID;
   reg [63:0]  ROMID1;
   reg [63:0]  ROMID2;
   reg [63:0]  ROMID3;
   reg [63:0]  ROMID4;
   wire [63:0] xow_slave_romid;
   wire [63:0] xxow_slave_romid;
   wire [63:0] xxxow_slave_romid;   
   wire [63:0] xxxxow_slave_romid;
   
         
`else

   reg [63:0]  ROMID;
   wire [63:0] xow_slave_romid;
      
`endif
         
   wire        CLK;
   wire [7:0]  clksel;

initial begin
 ROMID = 64'hFFFF_FFFF_FFFF_FFFF;
end 
   cpu_bfm xcpu_bfm(
   		     // Interface to DS1WM/
   		     .ADDR(ADDR),

   		     .ADS_N(ADS_N),
		     .CLKSEL(clksel),
   		     .RD_N(RD_N),
   		     .WR_N(WR_N),
   		     .EN_N(EN_N),
 
   		     .INTR(INTR),
   		     .DATA(DATA)
   );




`ifdef OW_SWITCH


   ow_slave xow_slave(
 
   		     .IO(IO),
		     .ROMID(xow_slave_romid)

   );

   ow_slave xxow_slave(
 
   		     .IO(IO),
		     .ROMID(xxow_slave_romid)

   );

   ow_slave xxxow_slave(
 
   		     .IO(IO),
		     .ROMID(xxxow_slave_romid)

   );

   ow_slave xxxxow_slave(
 
   		     .IO(IO),
		     .ROMID(xxxxow_slave_romid)

   );
   
   scoreboard xscoreboard(.OWS_ROMID1(xow_slave_romid),
   			.OWS_ROMID2(xxow_slave_romid),
			.OWS_ROMID3(xxxow_slave_romid),
			.OWS_ROMID4(xxxxow_slave_romid),
			.STPZ(STPZ)
   			); 


`else

   ow_slave xow_slave(
 
   		     .IO(IO),
		     .ROMID(xow_slave_romid)

   );

   scoreboard xscoreboard(.OWS_ROMID(xow_slave_romid),
   			  .STPZ(STPZ)
   			); 
   
`endif   


     
   clkgen     xclkgen(.CLK(CLK),
                      .SEL(clksel)
		     ); 
   
   // Generate System CLOCK
/*   
   parameter tclk = 125;    // clk half-period  4Mhz -> 125ns  
   
   initial begin
   
      CLK = 0;
      
      forever #tclk CLK = !CLK;
      
		     .ROMID(xxxxow_slave_romid)
   end 
   
*/   
   task reset();
      begin
       MR = 1'b0;
       @(posedge CLK);
       MR = 1'b1;
       @(posedge CLK);
       MR = 1'b0;
     end  
   
   endtask
 `include "stimulus.inc"   
   

endmodule
