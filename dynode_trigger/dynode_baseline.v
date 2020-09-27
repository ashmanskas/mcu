`default_nettype none

/* This is a module used in the file dynode_trg.v which is under the project ROCSTAR
	It calculates the baseline of the dynode ADC signals for
	event detection and energy integration. Correction is to a fraction of an LSB.
	Started on 08/15/2018 by Roger E Arseneau for U of PENN ROCSTAR project
	
Rev.  00	08/06/2018	Start design for ROCSYAR detector board 
Rev.  00	08/16/2018	Compile and simulate with with dynode_baseline.vwf 
Rev.  00	10/15/2018	Compile with full ROCSTAR.v 

*/
	
module dynode_baseline 
  (
   input  wire        clk,
   input  wire        reset,
   input  wire 		dyn_indet,		//event may be present
   input wire 			dyn_event,		//event detected
   input wire 			dyn_pileup,		//pileup up event detected
  input wire		dyn_pudump,		//fd to wide
   input  wire [7:0]  dyn_data_in,		//dynode ADC data
   input  wire [3:0]  dynadcdly,		//sets number of clk cyc delays to integrations and bsleline
   output reg  [11:0]  dyn_blcor,		//baseline corrected ADC for event detection 
   output reg [7:0] dyn_adcdly,		//delayed ADC data for energy integration 
   output reg [15:0] dyn_curval		//baseline for energy integration baseline correction
   );
   
   localparam
//   dynadcdly = 12, // sets number of clk cyc delays to integrations and bsleline 
   blstopdly= 3, // set the number of clk cyc to delay start of event hold  
   blstoptime= 5'b10111 , // number of clk cyc to hold baseline for event
   blchangerate= 16'h0001  // baseline size of change per test
   ;
   
    // delay ADC to baseline to allow event detection to stop 
    // event data from effect baseline value
    reg [7:0] data_delay [15:0];
    reg [7:0] data_dlylast ;
    always @ (posedge clk) begin
	data_delay[0] <= dyn_data_in;
	data_delay[1] <= data_delay[0];
	data_delay[2] <= data_delay[1];
	data_delay[3] <= data_delay[2];
	data_delay[4] <= data_delay[3];
	data_delay[5] <= data_delay[4];
	data_delay[6] <= data_delay[5];
	data_delay[7] <= data_delay[6];
	data_delay[8] <= data_delay[7];
	data_delay[9] <= data_delay[8];
	data_delay[10] <= data_delay[9];
	data_delay[11] <= data_delay[10];
	data_delay[12] <= data_delay[11];
	data_delay[13] <= data_delay[12];
	data_delay[14] <= data_delay[13];
	data_delay[15] <= data_delay[14];
	data_dlylast <= data_delay[dynadcdly];
    end

    // register and signals
	reg [11:0] ene16sum[3:0];
	reg [9:0] ene4sum[3:0];
	reg [9:0] enesum = 0;
    reg [11:0] newvalue = 0;
    reg [15:0] currentvalue = 0;
    reg eventpresent = 0;
    reg [4:0] holdcnt = 0;
    reg stopbl = 0;
	reg indet_d = 0;
	reg event_d = 0;
	reg pileup_d = 0;
	reg pudump_d = 0;
	reg [3:0] sample = 0;
    reg [15:0] stopdly  = 0;
    reg  stopdlylast = 0;

    initial begin
        ene4sum[0] = 0;
        ene4sum[1] = 0;
        ene4sum[2] = 0;
        ene4sum[3] = 0;
    end
	
  always @ (posedge clk) begin
 	
	stopbl <= (dyn_indet  & !indet_d) | (dyn_event & !event_d)
				| (dyn_pileup & !pileup_d)| (dyn_pudump & !pudump_d) ;
	indet_d <= dyn_indet ;  // enent signals
	event_d <= dyn_event ;
	pileup_d <= dyn_pileup ;
	pudump_d <= dyn_pudump ;
	
    // delay ADC to baseline to allow event detection to stop 
    // event data from effect baseline value
 	stopdly[0] <= stopbl;
	stopdly[1] <= stopdly[0];
	stopdly[2] <= stopdly[1];
	stopdly[3] <= stopdly[2];
	stopdly[4] <= stopdly[3];
	stopdly[5] <= stopdly[4];
	stopdly[6] <= stopdly[5];
	stopdly[7] <= stopdly[6];
	stopdly[8] <= stopdly[7];
	stopdly[9] <= stopdly[8];
	stopdly[10] <= stopdly[9];
	stopdly[11] <= stopdly[10];
	stopdly[12] <= stopdly[11];
	stopdly[13] <= stopdly[12];
	stopdly[14] <= stopdly[13];
	stopdly[15] <= stopdly[14];
	stopdlylast <= stopdly[blstopdly];
	
	if ( stopdlylast  )// stop baseline calculation for blstoptime clk cyc
		holdcnt <= blstoptime ;
	else if  (holdcnt != 5'b00000 )
 		holdcnt <= holdcnt - 5'b00001 ;
 	else begin holdcnt <= 5'b00000 ; 
 	
 	sample <= sample + 4'b0001 ; end
 	
 	eventpresent <= (holdcnt != 5'b00000 )| stopdlylast ;
 	
 	if (( sample [1:0]  == 2'b00 )&  !eventpresent  ) begin
		enesum <= { 2'b00, data_dlylast } ;  // start new 4 point sum
		if ( sample [3:2]  == 2'b00 )
			ene4sum[0]  <= enesum ;		// save a 4 point sum
		else if ( sample [3:2]  == 2'b01 )
			ene4sum[1]  <= enesum ;
		else if ( sample [3:2]  == 2'b10 )
			ene4sum[2]  <= enesum ;
		else
			ene4sum[3]  <= enesum ;
	end else if  (!eventpresent )
 	enesum  <= enesum + { 2'b00, data_dlylast } ;// continue 4 point sum
 	else enesum  <= enesum ;
 	
 	newvalue <= ene4sum[0] +  ene4sum[1] +  ene4sum[2] +  ene4sum[3] ; // add 4 sums to make 16 point sum
 	
 	if (reset == 1'b1 ) currentvalue <= 16'h0000 ;
	else if ((currentvalue[15:4] < newvalue )& !eventpresent )// test if currentvalue needs adjustment
			currentvalue <= currentvalue + blchangerate ;
	else if ((currentvalue[15:4] > newvalue )& !eventpresent )
			currentvalue <= currentvalue - blchangerate;
	else currentvalue <= currentvalue;

	if (	currentvalue[15:4] < {dyn_data_in, 4'b0000} )   //test to block under flow
	dyn_blcor <= 	{ dyn_data_in, 4'b0000 } -  currentvalue[15:4] ;
	else dyn_blcor <= 12'h000 ;
	
	end
	
	 always @ (*) begin

	dyn_curval  <= 	currentvalue ;
	
	dyn_adcdly <= data_dlylast ;
	
   end

endmodule

`default_nettype wire
