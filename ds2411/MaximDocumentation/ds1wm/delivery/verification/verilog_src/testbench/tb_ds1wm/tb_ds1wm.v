

module tb_ds1wm();

   wire [2:0] addr;
   wire       ads_n;
   wire [7:0] data;
   wire       dq;
   wire       en_n;
   wire       intr;
   wire       mr;
   wire       rd_n;
   wire       wr_n;
   wire       clk;
   wire       stpz;


         
   assign (weak0,weak1) dq = 1;            // simulates a weak pullup.
  
   ds1wm xds1wm(
   	   .CLK(clk),
   	   .MR(mr),
 
   	   .DQ(dq),
   	   .STPZ(stpz),
 
   	   .ADDRESS(addr),
   	   .ADS_bar(ads_n),
   	   .RD_bar(rd_n),
   	   .WR_bar(wr_n),
   	   .EN_bar(en_n),
 
   	   .INTR(intr),
   	   .DATA(data)
 
   );

   tc_ds1wm xtc_ds1wm (

   	   .ADDR(addr),
   	   .ADS_N(ads_n),
	   .CLK(clk),
   	   .EN_N(en_n),
	   .MR(mr),
   	   .RD_N(rd_n),
   	   .WR_N(wr_n),
 
   	   .INTR(intr),
   	   .DATA(data),
 
   	   .IO(dq),
	   .STPZ(stpz)


   );
   
   
   
endmodule     
