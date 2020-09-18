/* This is a module used in the file dynode_trg.v which is under the project ROCSTAR
	It calculates the energy of an event at the dynode signals for event windowing.
	the number if intrgration samples is adjustable from 1 to 15
	Started on 08/15/2018 by Roger E Arseneau for U of PENN ROCSTAR project
	
Rev.  00	09/04/2018	Start design for ROCSYAR dynode_integrator 
Rev.  00	09/11/2018	Design complete and simulated 
Rev.  00	10/15/2018	Compile with full ROCSTAR.v 

*/
	
module dynode_integrate 
  (
   input  wire        clk,
   input  wire        reset,
   input wire [3:0] integcount, 			// set the number of clk cyc to integrate  1 to 15
   input wire [7:0] dyn_adcdly,		//delayed ADC data for energy integration 
   input wire [15:0] dyn_curval,		//baseline for energy integration baseline correction
   input wire 	dyn_event,		//event detected
   input wire [23:0] evntim,   		// event start time to correct integration value
   output reg  [11:0]  dyn_energy, // integration value
   output reg  [3:0]  dyn_ingcnt,		// number of integration samples
   output reg  ene_load,			// energy integration ready
   output reg [23:0] dyn_evntim,   // event start time to correct integration value
   output reg  [7:0]  adc_delay ,	// adc dlayed at input
   output reg  [11:0]  sum_integ, 	// sum register to test dela  
   output reg  [7:0]  dynadc_dly 	// adc dlayed number of integ cycles

   //output for simulation
//   , 
//   input wire [3:0] integstartdly, 
//   output reg [2:0] smiao, 
//   output reg [2:0] smibo, 
//   output reg dyna_evento, 
//   output reg dynb_evento, 
// 	output reg  en_intego ,
//	output reg en_integsumo 
  
   ); 
   
    always @ (*)begin
		adc_delay <= dyn_adcdly ;
		sum_integ <= integ_sum ;
		end
		
		
//    always @ (*) begin
//	//output for simulation
//	smiao <= smia ;
//	smibo <= smib ;
//	dyna_evento <= dyna_event ;
//	dynb_evento <= dynb_event ;
//	en_intego <=  en_integ;
//	en_integsumo <=  en_integsum;
//
//	end

     localparam
//	integcount 	= 4'h4, // set the number of clk cyc to integrate  1 to 15
	integstartdly = 4'h0 // sets number of clk cyc delays to start of integration 0 to integcount -1
    ;
   reg dyna_event ;
   reg dynb_event ;
  
 	//start integration a if not busy else b
	always @ (*) begin
 	if  (( smia == sia0 )& ( dyn_event == 1'b1 ))begin  
		dyna_event  <= 1'b1  ;
		dynb_event  <= 1'b0  ;  end
	else if(( smia != sia0 )& ( dyn_event == 1'b1 ))begin
		dynb_event  <= 1'b1  ;
		dyna_event  <= 1'b0  ;  end
	else begin
		dynb_event  <= 1'b0  ;
		dyna_event  <= 1'b0  ;  end
	end
	
   reg [23:0] evntima ;
   reg [23:0] evntimb ;
	
// load event time to keep ADC sample phase for energy correction	
	always @ (posedge clk) begin  
	if ( dyna_event == 1'b1 ) evntima <= evntim ;
	else evntima <= evntima ;
	if ( dynb_event == 1'b1 ) evntimb <= evntim ;
	else evntimb <= evntimb ;
	end
	                                     
	reg [3:0] ingra_dly ;
	reg [3:0] ingra_cnt ;
	reg [3:0] ingra_num ;
	
	always @ (posedge clk) begin
	
	if ((dyna_event == 1'b1) & ( smia == sia0))ingra_dly <= 4'h1 ;
	else if (( smia == sia1)& (ingra_dly  < integstartdly)) ingra_dly <= ingra_dly +1;
	else ingra_dly <= 4'h0 ;
	
	if ((dyna_event == 1'b1) & ( smia == sia0))ingra_cnt <= 4'h1 ;
	else if (( smia == sia1)& (ingra_cnt  < integcount)) ingra_cnt <= ingra_cnt +1;
	else if (( smia == sia1)& (ingra_cnt  == integcount)) ingra_cnt <= ingra_cnt ;
	else if (( smia == sia2)& (ingra_cnt  < integcount)& ( dynb_event == 1'b0 )) ingra_cnt <= ingra_cnt +1;
	else if (( smia > sia1)& (ingra_cnt  >= integcount)) ingra_cnt <= ingra_cnt ;
	else ingra_cnt <= ingra_cnt;

	if ((ingra_dly  == integstartdly )& (integstartdly > 0 )) ingra_num <= 4'h1 ;
	else if ((dyna_event == 1'b1 )& (integstartdly == 0 )) ingra_num <= 4'h1 ;
	else if (( smia > sia1)& (ingra_num < ingra_cnt )& (integstartdly > 0 ))ingra_num <= ingra_num + 1 ;
	else if (( smia == sia2)& (integstartdly == 0 ))ingra_num <= ingra_num + 1 ;
	else ingra_num <= 4'h0 ;
	
	end

      localparam  // state machine for event integration
      sia0=0, sia1=1, sia2=2, 
      sia3=3, sia4=4, sia5=5;
	reg [2:0] smia ;
    always @ (posedge clk) begin
	if (reset) begin
	    smia <= 3'b0;
	end else begin
	    case(smia)
		sia0:			// wait for event
		  begin
			if (( dyna_event == 1'b1 )& (0 == integstartdly)) smia <= sia2 ;
		    else  smia <= dyna_event ? sia1 : sia0;
		  end
		sia1:			//wait for event to get to integrated
		  begin  
			if (( dynb_event == 1'b1 )& (ingra_dly  < integstartdly)) smia <= sia0 ;
			else if (( dynb_event == 1'b1 )& (ingra_dly  == integstartdly)) smia <= sia2 ;
			else	smia <= (ingra_dly  < integstartdly)? sia1 : sia2;
		  end
		sia2:			// start integration
		  begin 
			if (( dynb_event == 1'b1 )& (0 == integstartdly) )smia <= sia0 ;
			else if ( dynb_event == 1'b1 )smia <= sia3 ;
			else if ( integcount == 4'h1 )smia <= sia0 ;
			else if (0 == integstartdly)smia <= (ingra_cnt  >= integcount)? sia0 : sia2 ;
			else smia <= (ingra_cnt  >= integcount)? sia3 : sia2;
		  end
		sia3:		// start end of integration trst
		  begin
				smia <= (ingra_num < ingra_cnt )? sia3 : sia0;
		  end
		sia4:			// readout integrator
		  begin
		      smia <=  sia0;
		  end
		sia5:
		  begin
			smia <= sia0 ;
		    //smia <= evnten ? sia1 : sia0;
		  end
	    endcase
	end
    end
    
	reg [3:0] ingrb_dly ;
	reg [3:0] ingrb_cnt ;
	reg [3:0] ingrb_num ;
	
	always @ (posedge clk) begin
	
	if ((dynb_event == 1'b1) & ( smib == sib0))ingrb_dly <= 4'h1 ;
	else if (( smib == sib1)& (ingrb_dly  < integstartdly)) ingrb_dly <= ingrb_dly +1;
	else ingrb_dly <= 4'h0 ;
	
	if ((dynb_event == 1'b1) & ( smib == sib0))ingrb_cnt <= 4'h1 ;
	else if (( smib == sib1)& (ingrb_cnt  < integcount)) ingrb_cnt <= ingrb_cnt +1;
	else if (( smib == sib1)& (ingrb_cnt  == integcount)) ingrb_cnt <= ingrb_cnt ;
	else if (( smib == sib2)& (ingrb_cnt  < integcount)& ( dyna_event == 1'b0 )) ingrb_cnt <= ingrb_cnt +1;
	else if (( smib > sib1)& (ingrb_cnt  >= integcount)) ingrb_cnt <= ingrb_cnt ;
	else ingrb_cnt <= ingrb_cnt ;

	if ((ingrb_dly  == integstartdly )& (integstartdly > 0 )) ingrb_num <= 4'h1 ;
	else if ((dynb_event == 1'b1 )& (integstartdly == 0 )) ingrb_num <= 4'h1 ;
	else if (( smib > sib1)& (ingrb_num < ingrb_cnt )& (integstartdly > 0 ))ingrb_num <= ingrb_num + 1 ;
	else if (( smib == sib2)& (integstartdly == 0 ))ingrb_num <= ingrb_num + 1 ;
	else ingrb_num <= 4'h0 ;	
	end

      localparam  // state machine for event integration
      sib0=0, sib1=1, sib2=2, 
      sib3=3, sib4=4, sib5=5;
	reg [2:0] smib ;
    always @ (posedge clk) begin
	if (reset) begin
	    smib <= 3'b0;
	end else begin
	    case(smib)
		sib0:			// wait for event
		  begin
			if ( (dynb_event == 1'b1 )& (0 == integstartdly)) smib <= sib2 ;
		    else  smib <= dynb_event ? sib1 : sib0;
		  end
		sib1:			//wait for event to get to integrated
		  begin  
			if ( (dyna_event == 1'b1 )& (ingrb_dly  < integstartdly)) smib <= sib0 ;
			else if ( (dyna_event == 1'b1 )& (ingrb_dly  == integstartdly)) smib <= sib2 ;
			else	smib <= (ingrb_dly  < integstartdly)? sib1 : sib2;
		  end
		sib2:			// start integration
		  begin
			if (( dyna_event == 1'b1 )& (0 == integstartdly) )smib <= sib0 ;
			else if ( dyna_event == 1'b1 )smib <= sib3 ;
			else if ( integcount == 4'h1 )smib <= sib0 ;
			else if (0 == integstartdly)smib <= (ingrb_cnt  >= integcount)? sib0 : sib2 ;
			else smib <= (ingrb_cnt  >= integcount)? sib3 : sib2;
		  end
		sib3:		// start end of integration trst
		  begin
				smib <= (ingrb_num < ingrb_cnt )? sib3 : sib0;
		  end
		sib4:			// readout integrator
		  begin
		      smib <=  sib0;
		  end
		sib5:
		  begin
			smib <= sib0 ;
		    //smib <= evnten ? sib1 : sib0;
		  end
	    endcase
	end
    end
    
/* There are two accumulator for the integration one sums the dynode ADC
 and the second sums the baseline. At the first sample the ADC value is loaded
 into the ADC accumulator clearing any previous sum when  en_integ goes high
 on the next clock cycle en_integsum goes high adding the ADC to the sum. 
 The sum is read out at the cycle after the last sample is added 
 so a new integration can start at the same time
*/

	reg en_integ ;					//starts data to be entered to accumulator
	reg en_integsum ;			// start accumulator to be add to self alond with new data
	reg read_integ ;
	
	always @ (posedge clk) begin
	
	if (0  < integstartdly ) begin
	if (((ingra_dly  == integstartdly )& ( smia > sia0))
				| (ingrb_dly  == integstartdly )& ( smib > sib0))en_integ <= 1'b1 ;
	else if  ( ((ingra_num == ingra_cnt )& ( smia > sia1))
				| ((ingrb_num == ingrb_cnt)& ( smib > sib1)) )   en_integ <= 1'b0 ;
	else if  ( ((ingra_num < ingra_cnt )& ( smia > sia1))
				| ((ingrb_num < ingrb_cnt )& ( smib > sib1)) )  en_integ <= en_integ ;
	else en_integ <= 1'b0 ;
	if ((ingra_dly  == integstartdly)| (ingrb_dly  == integstartdly ))en_integsum <= 1'b0 ;
	else if  (( (ingra_num == ingra_cnt )& ( smia > sia1))
			| ((ingrb_num == ingrb_cnt)& ( smib > sib1)) )  en_integsum <= 1'b0 ;
	else  en_integsum <= en_integ ;
	if  (( (ingra_num == ingra_cnt )& ( smia > sia1))
			| ((ingrb_num == ingrb_cnt)& ( smib > sib1)) )  read_integ <= 1'b1 ;
	else read_integ <= 1'b0 ; end

	else if (0  == integstartdly )begin
	if ( dyn_event ==1'b1 )en_integ <= 1'b1 ;
	else if  ( (((ingra_num + 0) < integcount )& ( smia == sia2))
				| (((ingrb_num + 0) < integcount )& ( smib == sib2)) )  en_integ <= en_integ ;
	else en_integ <= 1'b0 ;

	if ( dyn_event ==1'b1 )en_integsum <= 1'b0 ;
	else if  ( (((ingra_num + 0) == integcount )& ( smia == sia2))
				| (((ingrb_num + 0) == integcount )& ( smib == sib2)) )  en_integsum <= 1'b0 ;
	else  en_integsum <= en_integ ;		//(ingrb_cnt  >= integcount)(ingrb_dly  == integstartdly )
	
	if  ( (((ingra_num ) == integcount )& ( smia == sia2))
				| (((ingrb_num ) == integcount )& ( smib == sib2)) )  read_integ <= 1'b1 ;
	else read_integ <= 1'b0 ;	end
	
	end
	
	reg [11:0] integ_sum ;// sum of ADC
	reg [15:0] bl_corsum 	;	//sum of baseline;
	reg [11:0] energy ;		// integ_sum -  bl_cor/16
	reg reada ;				// if 1 read a time if 0 read b time

	always @ (posedge clk) begin
  
	if ((en_integ == 1'b1 )& ( en_integsum == 1'b0 ))begin
		integ_sum <= { 4'h0, dyn_adcdly };
		bl_corsum <= dyn_curval[15:4] ; 	end
	else if ((en_integ == 1'b1 )& ( en_integsum== 1'b1 ))begin
		integ_sum <= { 4'h0, dyn_adcdly }+ integ_sum ;
		bl_corsum <= { 4'h0, dyn_curval[15:4] } + bl_corsum ;  end
		
		if ( smia > sia1 ) reada <= 1'b1 ;   // select time to read out by last energy integrate
		else if ( smib > sib1 ) reada <= 1'b0 ;
		else  reada <= reada ;

	end
	
	always @ (*) begin
	if ( read_integ == 1'b1 )begin
		energy <= integ_sum - bl_corsum[15:4] ;
		dyn_energy <= energy ;	
		if ( reada == 1'b1 )begin
			dyn_evntim <= evntima ;
			dyn_ingcnt <= ingra_cnt ; end		
		else begin
			dyn_evntim <= evntimb ;
			dyn_ingcnt <= ingrb_cnt ; end
	end
	else begin
		energy <= 12'h000 ;
		dyn_energy <= energy ;	
		dyn_evntim <= 23'h000000 ;
		dyn_ingcnt <= 4'h0 ;		
	end
	ene_load <= read_integ ;
	end
	
     // delay ADC to baseline to allow event detection to stop 
    // event data from effect baseline value
    reg [7:0] data_delay [15:1];
    reg [7:0] data_dlylast ;
    always @ (posedge clk) begin
	data_delay[1] <= dyn_adcdly;
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
	dynadc_dly <= data_delay[integcount];
    end

  
endmodule
