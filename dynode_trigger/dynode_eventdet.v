`default_nettype none

/* This is a module used in the file dynode_trg.v which is under the project ROCSTAR
	It detects and determines the start time of an event at the dynode signals for
	coincident testing..
	Started on 08/15/2018 by Roger E Arseneau for U of PENN ROCSTAR project
	
Rev.  00	08/15/2018	Start design for ROCSYAR dynode_eventdet 
Rev.  00	08/31/2018	Design completed and simulated 
Rev.  00	10/15/2018	Compile with full ROCSTAR.v 

*/
	
module dynode_eventdet 
  (
   input  wire          clk,
   input  wire          reset,
   input  wire  [7:0]   timcnt,				//time counter   
   input  wire  [11:0]  dyn_blcor,		//baseline corrected ADC for event detection 
   input  wire  [1:0]   selecttime,		// 0 = time from SD, 1 = time from cfd enetot 4 point, 2 = 1 pt
   input  wire  [3:0]   smoothpmt, 			// set number of points in smooth 1, 2, 3, or 4 
   output reg 	        dyn_indet,		//event may be present
   output reg 	        dyn_event,		//event detected
   output reg 	        dyn_pileup,		//pileup up event detected
   output reg 		dyn_pudump,		//fd to wide
   output reg   [23:0]  evntim,
   output reg   [7:0]   evnt_timsd_t     // temp output for scatter plot
   
//   output for simulation
// , output reg [14:0] fdo,
//   output reg [14:0] sdo,   
//   output reg [2:0] smedo,
//   output reg [2:0] smtmo,
//   output reg  fdeno,
//   output reg  sdeno,
//   output reg  evnteno,
//   output reg  enesdnego,
//   output reg  sd_delayo,
//   output reg [14:0] enesd_difo,
//   output reg [13:0] enesmo_lasto,
//   output reg [14:0] cfd_difo,
//   output reg [24:0] sd_timfraco,
//   output reg [23:0] sd_timadjo,
//   output reg [24:0] cfd_timfraco,
//   output reg [15:0] enetot_mo
 
   );
   
   localparam
// selecttime 		= 0,    	// 0 = time from SD, 1 = time from cfd enetot 4 point, 2 = 1 pt
// smoothpmt		= 3,     	// set number of points in smooth  
   sdtim0adj 	      	= 12'hA00, 	// time adjust for sd time
   cfdtim1adj 		= 12'hE40, 	// time adjust for cfd 1 time
   cfdtim2adj 		= 12'h980, 	// time adjust for cfd 2 time
   cfdtim1dly 		= 6,    	// sets number of clk cyc delays for timming test 1
   cfdtim2dly 		= 5,    	// sets number of clk cyc delays for timming test 2
   enetot1factor	= 3,    	// set number of right shifts 3 , 4 or 5  for timing test 1
   enetot2factor	= 4,    	         // set number of right shifts 3 , 4 or 5  for timing test 1
   indetonlevel		= 14'b0000_0100_000000 , // indet turn on level
   indetofflevel       	= 14'b0000_0010_000000 , // indet turn off level
   fdonlevel   		= 15'b0_0000_1000_000000 , // fd minimum for event
   sdonlevel		= 15'b0_0000_0110_000000,  // sd minimum for event
   pudetwide		= 3'b100        // evenr to close os dump both
   ;

    // Delay  to smooth data for 100 mhz sample 
    // rate to remove dead spots do to rise time less then 10 ns.
    reg [11:0] dynblcor_d [2:0];
    always @ (posedge clk) begin
	dynblcor_d[0] <= dyn_blcor;
	dynblcor_d[1] <= dynblcor_d[0];
	dynblcor_d[2] <= dynblcor_d[1];
    end

  

    reg [13:0] enesmo;
    
    // smooth dynode signal for event test 1, 2, 3, 4 and 5
    // 5 is a 3 point with the center point weighted twice
    // value times 4  for all except 3 is 3 times
    always @ (posedge clk) begin
       	if ( smoothpmt == 2 )enesmo <= dyn_blcor + dynblcor_d[0]  + dyn_blcor + dynblcor_d[0] ;
	else if ( smoothpmt == 3 )
		enesmo <= dyn_blcor + dynblcor_d[0]  +  dynblcor_d[1]  ;
	else if ( smoothpmt == 4 )
		enesmo <= dyn_blcor + dynblcor_d[0]  + dynblcor_d[1]   + dynblcor_d[2]  ;
	else if ( smoothpmt == 5 )
		enesmo <= dyn_blcor + dynblcor_d[0]  + dynblcor_d[0]   + dynblcor_d[1]  ;
	else    enesmo <= dyn_blcor + dyn_blcor  + dyn_blcor + dyn_blcor ;

       	if  ( indet == 1'b0 )
        	indet  <= ( enesmo  > indetonlevel ) ;
        else    indet  <= ( enesmo  > indetofflevel ); //|  ( smed != sed0 ) ;

        piledet = ((indet == 1'b1 ) & ( enefd > fdonlevel )& ( enefd[14] != 1'b1)  );	
    end // always @ (posedge clk)

   
 
    reg [14:0]	enefd;		// first derivative signed	
    reg [14:0]	enefd_d	;	// first derivative delayed signed	
    reg [14:0]	enesd	;	// second derivative	signed
    reg [14:0]	enesd_d	;	// second derivative	signed
    reg [14:0] enesd_p ;
    reg [14:0] enesd_n ;
    reg [14:0] enesd_dif ;      // the change in sd at zero crossing
    reg [7:0] evnt_timsd ;      // the vslue of event time at sd  zero crossing
    reg 	indet;		//event may be present enesmo greater then noise
    reg 	piledet;	//fd greater then noise
    reg 	evnt;		//event detected
    reg 	pileup;		//pileup up event detected
    reg [2:0] pucnt;		//pileup count for pileup to close
    reg  pudmp;			//dump pileup count for pileup to close
    reg [23:0] sd_evnttim ;     // time of sd crossing with fraction
    reg [23:0] cfd_evnttim ;    // time of cfd crossing with fraction
    reg [23:0] sel_evnttim ;    // time of sd or cfd crossing to output

    always @ (posedge clk) begin		 //gen fd and sd
	enefd <= enesmo - enesmo_d[0] ;
	enefd_d <= enefd ;
	enesd <= enefd - enefd_d ;
	enesd_d <= enesd ;
	
	// generate SD event time from counter input and cycle fraction
	if ( smed == sed3 ) sd_evnttim <= sd_timadj;
			
	if ( evnten == 1'b1)begin ; //sd neg  captures crossing
		enesd_n <= enesd ;
		enesd_p <= enesd_d ;
		evnt_timsd <= timcnt ;
	        evnt_timsd_t <= evnt_timsd;
	   
	end	
	
	end
    
	reg evnten ;		// start looking for sd neg to capture event data
	reg fden ;			//fd reach enable level
	reg sden ;		//sd reach enable level
	reg sdneg ;	
	reg [24:0] sd_timfrac ;	//fraction of clock cycle sd crossing occured
	reg [23:0] sd_timadj ;	//fraction of clock cycle sd crossing adjusted
  	reg sd_delay ;	
 
    always @ (*) begin// select sd time or cfd time
	if ((indet == 1'b1 ) & ( enefd > fdonlevel )& ( enefd[14] != 1'b1)  & (smed ==sed0 ) )fden = 1'b1 ;
	else if  ((indet == 1'b1 )& (evnten == 1'b0 ) )fden = fden ;	//event fd above enable level
	else fden = 1'b0 ;
		
  	if ((indet == 1'b1 ) & ( enesd > sdonlevel )& ( enesd[14] != 1'b1 )  & (smed ==sed0 ) )sden = 1'b1 ;
	else if  ((indet == 1'b1 )& (evnten == 1'b0 ) )sden = sden ;		//event sd above enable level
	else sden = 1'b0 ;
  
   	if ((indet == 1'b1 ) & ( fden == 1'b1) & ( sden == 1'b1 ) )evnten = 1'b1 ;
	else if  ((indet == 1'b1 )& ( smed == sed1))  evnten = evnten ;	//wait for sd to go negative
	else evnten = 1'b0 ;
	
	if (selecttime == 0 ) sel_evnttim  <= sd_evnttim ;
	else  sel_evnttim  <=  cfd_evnttim ;
	
	end

    always @ (*) begin

	sd_timadj <= { evnt_timsd, sd_timfrac[15:4] } + { 8'h00, sdtim0adj };
	sd_delay <= ( sd_timadj[12] != evnt_timsd[0] ) ;
    
	// determine size of enesd_dif to scale to inverse value and multiply for timing
	if (enesd_dif[13] == 1'b1)begin	  		sd_delt  <=  ( enesd_dif[13:6] );
		sd_timfrac <=   enesd_p[14:6] * invrt_deltw ; end
	else if (enesd_dif[12] == 1'b1) begin  	sd_delt  <=  ( enesd_dif[12:5] );
		sd_timfrac <=   enesd_p[13:5] * invrt_deltw ; end
	else if (enesd_dif[11] == 1'b1) begin  	sd_delt  <=  ( enesd_dif[11:4] );
		sd_timfrac <=   enesd_p[12:4] * invrt_deltw ; end
	else if (enesd_dif[10] == 1'b1) begin  	sd_delt  <=  ( enesd_dif[10:3] );
		sd_timfrac <=   enesd_p[11:3] * invrt_deltw ; end
	else if (enesd_dif[9] == 1'b1)  begin	sd_delt  <=  ( enesd_dif[9:2] );
		sd_timfrac <=   enesd_p[10:2] * invrt_deltw ; end
	else if (enesd_dif[8] == 1'b1)  begin  	sd_delt  <=  ( enesd_dif[8:1] );
		sd_timfrac <=   enesd_p[9:1] * invrt_deltw ; end
	else                     	begin	sd_delt  <=  ( enesd_dif[7:0] );
		sd_timfrac <=   enesd_p[8:0] * invrt_deltw ; end

	sdneg <= ( enesd[14] == 1'b1 );
	invrt_delt  <=  invrt_deltw;
	enesd_dif <=  enesd_p - enesd_n ;
	
	if 		(( selecttime == 0 )& ( sd_delay == 1'b0)) dyn_event <= ( smed == sed4 );
	else if 	(( selecttime == 0 )& ( sd_delay == 1'b1)) dyn_event <= ( smed == sed5 );
	else if 	( cfd_delay == 1'b1)	dyn_event <= ( smtm == stm6 );
	else 		dyn_event <= ( smtm == stm5 );
	
	// outputs
	dyn_indet <= indet ;
//	dyn_event 	        	//event detected
	dyn_pileup <= piledet ;		//pileup up event detected
	dyn_pudump <= pudmp ;		//pileup up event to close
	evntim <= sel_evnttim ;
	
	//output for simulation
//	fdo <= enefd ;
//	sdo <= enesd ;
//	smedo <= smed ;
//	smtmo <= smtm ;
//	fdeno <= fden ;
//	sdeno <= sden ;
//	evnteno <= evnten ;
//	enesdnego <=   enesd[14]  ;
//	enesd_difo <= enesd_dif ;
//	cfd_difo <= cfd_dif ;
//	enetot_mo <= enetot_m ;
//	sd_timfraco <= sd_timfrac ;
//	cfd_timfraco <= cfd_timfrac ;
//	enesmo_lasto <= enesmo_last ;
//	sd_delayo <= sd_delay ;
//	sd_timadjo <= sd_timadj ;

	end
		
	wire [7:0] sd_deltw ;
	assign sd_deltw  =  sd_delt;
	reg [7:0] sd_delt ;
	reg [15:0] invrt_delt ;
	wire [15:0] invrt_deltw ;
	
    inverse_lookup sdi(sd_deltw, invrt_deltw );
  
    localparam  // state machine for event detection
        sed0=0, sed1=1, sed2=2, 
        sed3=3, sed4=4, sed5=5;
	reg [2:0] smed ;
    always @ (posedge clk) begin
	if (reset) begin
	    smed <= 3'b0;
	end else begin
	    case(smed)
		sed0:			// wait for event
		  begin
		      smed <= evnten ? sed1 : sed0;
		      pudmp <= 1'b0 ; 
		      pucnt <= 3'b000 ;
		  end
		sed1:			//wait for sd to go negative
		  begin  
			pucnt <= pucnt + 1 ;
			if (!(pucnt >= pudetwide))begin
				smed <= sdneg ? sed2 : sed1;
				pudmp <= 1'b0 ; end
			else begin 
				smed <= sed0 ;
				pudmp <= 1'b1 ; end
		  end
		sed2:			// start calculation of sd time fraction
		  begin
			pucnt <= 3'b000 ;
		    smed <=  sed3 ;
		  end
		sed3:
		  begin
		      smed <=  sed4;
		  end
		sed4:
		  begin
		      smed <= sd_delay ? sed5 : sed0;
		  end
		sed5:
		  begin
			smed <= sed0 ;
		    //smed <= evnten ? sed1 : sed0;
		  end
	    endcase
	end
    end
    
 
    // Delay for timming test  
    reg [13:0] enesmo_d [15:0];
    reg [13:0] enesmo_last ;
    reg [3:0] cfdtimdly ;
    always @ (posedge clk) begin
	enesmo_d[0] <= enesmo;
	enesmo_d[1] <= enesmo_d[0];
	enesmo_d[2] <= enesmo_d[1];
	enesmo_d[3] <= enesmo_d[2];
	enesmo_d[4] <= enesmo_d[3];
	enesmo_d[5] <= enesmo_d[4];
	enesmo_d[6] <= enesmo_d[5];
	enesmo_d[7] <= enesmo_d[6];
	enesmo_d[8] <= enesmo_d[7];
	enesmo_d[9] <= enesmo_d[8];
	enesmo_d[10] <= enesmo_d[9];
	enesmo_d[11] <= enesmo_d[10];
	enesmo_d[12] <= enesmo_d[11];
	enesmo_d[13] <= enesmo_d[12];
	enesmo_d[14] <= enesmo_d[13];
	enesmo_d[15] <= enesmo_d[14];
	enesmo_last <= enesmo_d[cfdtimdly];
	
	
    end
   
      //sum 4 to find energy value save peak value
    reg [15:0] enetot ; 
    reg [15:0] enetot_d ; 
    reg [15:0] enetot_m ; 
    reg [15:0] enetot_f ;  // enetot right shifted for CFD crossing test
    reg [14:0] enetot_cfd ;  // CFD results
    reg [14:0] enetot_cfdd ;  // CFD results delayed
    reg [14:0] enetot_cfdp ;  // CFD results before crossing
    reg [14:0] enetot_cfdn ;  // CFD results after
    reg [14:0] cfd_dif ;  			// CFD dif p-n
    reg [7:0] evnt_timcfd ; // the vslue of event time at CFD  zero crossing
    reg [11:0] enetotfactor ;

    always @ (posedge clk) begin
   
          if ( selecttime == 1) begin enetot <=  enesmo + enesmo_d[0] + enesmo_d[1] + enesmo_d[2] ;
                cfdtimdly = cfdtim1dly ;  
		enetotfactor <= enetot1factor ; end
          else                  begin enetot <= enesmo_d[0] ; 
		cfdtimdly = cfdtim2dly ;
		enetotfactor <= enetot1factor ; end
		
          enetot_d <= enetot ;
	
	  if (( enetot > enetot_d )& (smtm == stm1))
		enetot_m <= enetot ;		// 4 sample integration energy value
			
			// subtract delayed enesmo from reduced enetot test for negative
	  if  ( enetotfactor == 3 )enetot_f <= {3'b000, enetot_m[15:3] };
  	  else if  ( enetotfactor == 4 )enetot_f <= {4'b0000, enetot_m[15:4] };
	  else if  ( enetotfactor == 5 )enetot_f <= {5'b00000, enetot_m[15:5] };
	  else if  ( enetotfactor == 6 )enetot_f <= {6'b000000, enetot_m[15:6] };
	  else if  ( enetotfactor == 7 )enetot_f <= {7'b0000000, enetot_m[15:7] };
	  else       enetot_f <= {8'b0000000, enetot_m[15:6] }; // other
	
	  enetot_cfdd  <= enetot_cfd ;  // enetot_cfd generated below not registered

	  if ( smtm ==  stm2) begin ; //sd neg  captures crossing
		enetot_cfdn <= enetot_cfd ;
		enetot_cfdp <= enetot_cfdd ;
		evnt_timcfd <= timcnt ;
    end	
	
	// generate CFD event time from counter input and cycle fraction
    if ( smtm == stm4 ) cfd_evnttim <= cfd_timadj;
	
    end
   
    reg [24:0] cfd_timfrac ;	//fraction of clock cycle cfd crossing occured
    reg [23:0] cfd_timadj ;	//fraction of clock cycle sd crossing adjusted
    reg cfd_delay ;	

    always @ (*) begin

          if ( selecttime == 1 ) cfd_timadj <= { evnt_timcfd, cfd_timfrac[15:4] } + { 8'h00, cfdtim1adj };
          else	cfd_timadj <= { evnt_timcfd, cfd_timfrac[15:4] } + { 8'h00, cfdtim2adj };
	  cfd_delay <= ( cfd_timadj[12] != evnt_timcfd[0] ) ;

	  // determine size of cfd_dif to scale to inverse value and multiply for timming
	  if (cfd_dif[13] == 1'b1)      begin	cfd_delt  <=  ( cfd_dif[13:6] );
	 	cfd_timfrac <=   enetot_cfdp[14:6] * invrtcfd_deltw ; end
	  else if (cfd_dif[12] == 1'b1) begin  	cfd_delt  <=  ( cfd_dif[12:5] );
		cfd_timfrac <=   enetot_cfdp[13:5] * invrtcfd_deltw ; end
      	  else if (cfd_dif[11] == 1'b1) begin  	cfd_delt  <=  ( cfd_dif[11:4] );
		cfd_timfrac <=   enetot_cfdp[12:4] * invrtcfd_deltw ; end
	  else if (cfd_dif[10] == 1'b1) begin  	cfd_delt  <=  ( cfd_dif[10:3] );
		cfd_timfrac <=   enetot_cfdp[11:3] * invrtcfd_deltw ; end
	  else if (cfd_dif[9] == 1'b1)  begin	cfd_delt  <=  ( cfd_dif[9:2] );
		cfd_timfrac <=   enetot_cfdp[10:2] * invrtcfd_deltw ; end
	  else if (cfd_dif[8] == 1'b1)  begin  	cfd_delt  <=  ( cfd_dif[8:1] );
		cfd_timfrac <=   enetot_cfdp[9:1] * invrtcfd_deltw ; end
	  else   			begin   cfd_delt  <=  ( cfd_dif[7:0] );
		cfd_timfrac <=   enetot_cfdp[8:0] * invrtcfd_deltw ; end
		
	cfd_dif <= enetot_cfdp - enetot_cfdn ;
	enetot_cfd  <= enetot_f[14:0] - { 1'b0, enesmo_last } ;  // crossing when bit 14 = 1

    end

	wire [7:0] cfd_deltw ;
	assign cfd_deltw  =  cfd_delt;
	reg [7:0] cfd_delt ;
	reg [15:0] invrtcfd_delt ;
	wire [15:0] invrtcfd_deltw ;
	
    inverse_lookup cfdi(cfd_deltw, invrtcfd_deltw );
  

    localparam  // state machine for event start time
      stm0=0, stm1=1, stm2=2, 
      stm3=3, stm4=4, stm5=5, stm6=6;
      reg [2:0] smtm ;
    always @ (posedge clk) begin
	if (reset) begin
	    smtm <= 3'b0;
	end else begin
	    case(smtm)
		stm0:			// wait for event
		  begin
		/*	if ( selecttime == 0 )smtm <= stm0 ;
		    else  */ smtm <= (smed == sed1) ? stm1 : stm0;
		  end
		stm1:			//look for max value of energy
		  begin
		     smtm <= !( enetot > enetot_d ) ? stm2 : stm1;
		  end
		stm2:			// wait for cfd to go negative 
		  begin
		      smtm <= ( enetot_cfd[14] == 1'b1 ) ? stm3 : stm2 ;
		  end
		stm3:			// start calculation of cfd time fraction
		  begin
		      smtm <=  stm4;
		  end
		stm4:
		  begin
		      smtm <=  stm5;
		  end
		stm5:
		  begin
		      smtm <= cfd_delay ? stm6 : stm0;
		  end
		stm6:
		  begin
		      smtm <= stm0;
		  end
	    endcase
	end
    end
    
endmodule

`default_nettype wire

