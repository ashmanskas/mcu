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
   input  wire        clk,
   input  wire        reset,
   input  wire [7:0] timcnt,				//time counter   
   input wire  [11:0]  dyn_blcor,		//baseline corrected ADC for event detection 
   input wire [1:0] selecttime,		// 0 = time from SD, 1 = time from cfd enetot 4 point, 2 = 1 pt
   input wire [3:0] smoothpmt, 			// set number of points in smooth 1, 2, 3, or 4 
  output  reg 	dyn_indet,		//event may be present
   output reg 	dyn_event,		//event detected
   output reg 	dyn_pileup,		//pileup up event detected
  output reg 		dyn_pudump,		//fd to wide
   output reg [23:0] evntim
   
   //output for simulation
//    , output reg [14:0] fdo,
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
//  output reg [24:0] sd_timfraco,
//  output reg [23:0] sd_timadjo,
//   output reg [24:0] cfd_timfraco,
//   output reg [15:0] enetot_mo
 
   );
   
   localparam
//  selecttime 			= 0, 	// 0 = time from SD, 1 = time from cfd enetot 4 point, 2 = 1 pt
//   smoothpmt		= 3, 	// set number of points in smooth  
   sdtim0adj 			= 12'hA00, 	// time adjust for sd time
   cfdtim1adj 		= 12'hE40, 	// time adjust for cfd 1 time
   cfdtim2adj 		= 12'h980, 	// time adjust for cfd 2 time
   cfdtim1dly 		= 6, 	// sets number of clk cyc delays for timming test 1
   cfdtim2dly 		= 5, 	// sets number of clk cyc delays for timming test 2
   enetot1factor	= 3, 	// set number of right shifts 3 , 4 or 5  for timing test 1
  enetot2factor		= 4, 	// set number of right shifts 3 , 4 or 5  for timing test 1
   indetonlevel		= 14'b      0000_0100_000000 , // indet turn on level
   indetofflevel		= 14'b      0000_0010_000000 , // indet turn off level
   fdonlevel			= 15'b 0_0000_1000_000000 , // fd minimum for event
   sdonlevel			= 15'b 0_0000_0110_000000,  // sd minimum for event
   pudetwide			= 3'b100  // evenr to close os dump both
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
		else enesmo <= dyn_blcor + dyn_blcor  + dyn_blcor + dyn_blcor ;

	if  ( indet == 1'b0 )
		indet  <= ( enesmo  > indetonlevel ) ;
	else   indet  <= ( enesmo  > indetofflevel ); //|  ( smed != sed0 ) ;

	piledet = ((indet == 1'b1 ) & ( enefd > fdonlevel )& ( enefd[14] != 1'b1)  );
	
	end
 
    reg [14:0]	enefd;		// first derivative signed	
    reg [14:0]	enefd_d	;	// first derivative delayedsigned	
    reg [14:0]	enesd	;	// second derivative	segned
    reg [14:0]	enesd_d	;	// second derivative	segned
	reg [14:0] enesd_p ;
	reg [14:0] enesd_n ;
	reg [14:0] enesd_dif ; // the change in sd at zero crossing
	reg [7:0] evnt_timsd ; // the vslue of event time at sd  zero crossing
	reg 	indet;				//event may be present enesmo greater then noise
	reg 	piledet;			//fd greater then noise
	reg 	evnt;				//event detected
	reg 	pileup;				//pileup up event detected
	reg [2:0] pucnt;				//pileup count for pileup to close
	reg  pudmp;				//dump pileup count for pileup to close
	reg [23:0] sd_evnttim ; // time of sd crossing with fraction
	reg [23:0] cfd_evnttim ; // time of cfd crossing with fraction
	reg [23:0] sel_evnttim ; // time of sd or cfd crossing to output

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
	end	
	
	end
    
	reg evnten ;		// start looking for sd neg to capture event data
	reg fden ;			//fd reach enable level
	reg sden ;		//sd reach enable level
	reg sdneg ;	
	reg [24:0] sd_timfrac ;	//fraction of clock cycle sd crossing occured
	reg [23:0] sd_timadj ;	//fraction of clock cycle sd crossing adjusted
  	reg sd_delay ;	
 
  always @ (*) begin
	
		// select sd time or cfd time
	if ((indet == 1'b1 ) & ( enefd > fdonlevel )& ( enefd[14] != 1'b1)  & (smed ==sed0 ) )fden = 1'b1 ;
	else if  ((indet == 1'b1 )& (evnten == 1'b0 ) )fden = fden ;	//event fd above enable level
	else fden = 1'b0 ;
		
  	if ((indet == 1'b1 ) & ( enesd > sdonlevel )& ( enesd[14] != 1'b1 )  & (smed ==sed0 ) )sden = 1'b1 ;
	else if  ((indet == 1'b1 )& (evnten == 1'b0 ) )sden = sden ;		//event sd above enable level
	else sden = 1'b0 ;
  
   	if ((indet == 1'b1 ) & ( fden == 1'b1) & ( sden == 1'b1 ) )evnten = 1'b1 ;
	else if  ((indet == 1'b1 )& ( smed == sed1))  evnten = evnten ;	//wait for sd to go negatige
	else evnten = 1'b0 ;
	
	if (selecttime == 0 ) sel_evnttim  <= sd_evnttim ;
	else  sel_evnttim  <=  cfd_evnttim ;
	
	end

  always @ (*) begin

	sd_timadj <= { evnt_timsd, sd_timfrac[15:4] } + { 2'h00, sdtim0adj };
	sd_delay <= ( sd_timadj[12] != evnt_timsd[0] ) ;
    
	// determine size of enesd_dif to scale to inverse value and multiply for timming
	if (enesd_dif[13] == 1'b1)begin	  		sd_delt  <=  ( enesd_dif[13:6] );
		sd_timfrac <=   enesd_p[14:6] * invrt_deltw ; end
	else if (enesd_dif[12] == 1'b1)begin  	sd_delt  <=  ( enesd_dif[12:5] );
		sd_timfrac <=   enesd_p[13:5] * invrt_deltw ; end
	else if (enesd_dif[11] == 1'b1)begin  	sd_delt  <=  ( enesd_dif[11:4] );
		sd_timfrac <=   enesd_p[12:4] * invrt_deltw ; end
	else if (enesd_dif[10] == 1'b1)begin  	sd_delt  <=  ( enesd_dif[10:3] );
		sd_timfrac <=   enesd_p[11:3] * invrt_deltw ; end
	else if (enesd_dif[9] == 1'b1)  begin	sd_delt  <=  ( enesd_dif[9:2] );
		sd_timfrac <=   enesd_p[10:2] * invrt_deltw ; end
	else if (enesd_dif[8] == 1'b1)begin  	sd_delt  <=  ( enesd_dif[8:1] );
		sd_timfrac <=   enesd_p[9:1] * invrt_deltw ; end
	else	  									begin		sd_delt  <=  ( enesd_dif[7:0] );
		sd_timfrac <=   enesd_p[8:0] * invrt_deltw ; end

	sdneg <= ( enesd[14] == 1'b1 );
	invrt_delt  <=  invrt_deltw;
	enesd_dif <=  enesd_p - enesd_n ;
	
	if 			(( selecttime == 0 )& ( sd_delay == 1'b0)) dyn_event <= ( smed == sed4 );
	else if 	(( selecttime == 0 )& ( sd_delay == 1'b1)) dyn_event <= ( smed == sed5 );
	else if 	( cfd_delay == 1'b1)	dyn_event <= ( smtm == stm6 );
	else 		dyn_event <= ( smtm == stm5 );
	
	// outputs
	dyn_indet <= indet ;
//	dyn_event 		//event detected
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
		
	assign sd_deltw  =  sd_delt;
	wire [7:0] sd_deltw ;
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
   
   if ( selecttime == 1 )begin enetot <=  enesmo + enesmo_d[0] + enesmo_d[1] + enesmo_d[2] ;
		cfdtimdly = cfdtim1dly ;  
		enetotfactor <= enetot1factor ; end
   else   begin enetot <= enesmo_d[0] ; 
		cfdtimdly = cfdtim2dly ;
		enetotfactor <= enetot1factor ; end
		
 	enetot_d <= enetot ;
	
	if (( enetot > enetot_d )& (smtm == stm1))
			enetot_m <= enetot ;		// 4 sample integration energy value
			
			// subtract delayed enesmo from reduced enetot test for negative
	if  ( enetotfactor == 3 )enetot_f <= {3'b000, enetot_m[15:3] };
	else if  ( enetotfactor == 4 )enetot_f <= {3'b0000, enetot_m[15:4] };
	else if  ( enetotfactor == 5 )enetot_f <= {3'b00000, enetot_m[15:5] };
	else if  ( enetotfactor == 6 )enetot_f <= {3'b000000, enetot_m[15:6] };
	else if  ( enetotfactor == 7 )enetot_f <= {3'b0000000, enetot_m[15:7] };
	else   	enetot_f <= {3'b0000000, enetot_m[15:6] }; // other
	
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

   if ( selecttime == 1 )	cfd_timadj <= { evnt_timcfd, cfd_timfrac[15:4] } + { 2'h00, cfdtim1adj };
  else	cfd_timadj <= { evnt_timcfd, cfd_timfrac[15:4] } + { 2'h00, cfdtim2adj };
	cfd_delay <= ( cfd_timadj[12] != evnt_timcfd[0] ) ;

	// determine size of cfd_dif to scale to inverse value and multiply for timming
	if (cfd_dif[13] == 1'b1)begin	  		cfd_delt  <=  ( cfd_dif[13:6] );
		cfd_timfrac <=   enetot_cfdp[14:6] * invrtcfd_deltw ; end
	else if (cfd_dif[12] == 1'b1)begin  	cfd_delt  <=  ( cfd_dif[12:5] );
		cfd_timfrac <=   enetot_cfdp[13:5] * invrtcfd_deltw ; end
	else if (cfd_dif[11] == 1'b1)begin  	cfd_delt  <=  ( cfd_dif[11:4] );
		cfd_timfrac <=   enetot_cfdp[12:4] * invrtcfd_deltw ; end
	else if (cfd_dif[10] == 1'b1)begin  	cfd_delt  <=  ( cfd_dif[10:3] );
		cfd_timfrac <=   enetot_cfdp[11:3] * invrtcfd_deltw ; end
	else if (cfd_dif[9] == 1'b1)  begin	cfd_delt  <=  ( cfd_dif[9:2] );
		cfd_timfrac <=   enetot_cfdp[10:2] * invrtcfd_deltw ; end
	else if (cfd_dif[8] == 1'b1)begin  	cfd_delt  <=  ( cfd_dif[8:1] );
		cfd_timfrac <=   enetot_cfdp[9:1] * invrtcfd_deltw ; end
	else	  									begin		cfd_delt  <=  ( cfd_dif[7:0] );
		cfd_timfrac <=   enetot_cfdp[8:0] * invrtcfd_deltw ; end
		
	cfd_dif <= enetot_cfdp - enetot_cfdn ;
	enetot_cfd  <= enetot_f[14:0] - { 1'b0, enesmo_last } ;  // crossing when bit 14 = 1

end

	assign cfd_deltw  =  cfd_delt;
	wire [7:0] cfd_deltw ;
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


module inverse_lookup
  (
   input  wire [7:0] value,
   output wire [15:0] inverse
   );
    reg[15:0] i;
    assign inverse = i;
    always @ (*) begin
	case(value)
	    0: i='hFFFF; 1: i='hFFFF; 2: i='h8000; 3: i='h5555;
	    4: i='h4000; 5: i='h3333; 6: i='h2AAA; 7: i='h2492;
	    8: i='h2000; 9: i='h1C71; 10: i='h1999; 11: i='h1745;
	    12: i='h1555; 13: i='h13B1; 14: i='h1249; 15: i='h1111;
	    16: i='h1000; 17: i='h0F0F; 18: i='h0E38; 19: i='h0D79;
	    20: i='h0CCC; 21: i='h0C30; 22: i='h0BA2; 23: i='h0B21;
	    24: i='h0AAA; 25: i='h0A3D; 26: i='h09D8; 27: i='h097B;
	    28: i='h0924; 29: i='h08D3; 30: i='h0888; 31: i='h0842;
	    32: i='h0800; 33: i='h07C1; 34: i='h0787; 35: i='h0750;
	    36: i='h071C; 37: i='h06EB; 38: i='h06BC; 39: i='h0690;
	    40: i='h0666; 41: i='h063E; 42: i='h0618; 43: i='h05F4;
	    44: i='h05D1; 45: i='h05B0; 46: i='h0590; 47: i='h0572;
	    48: i='h0555; 49: i='h0539; 50: i='h051E; 51: i='h0505;
	    52: i='h04EC; 53: i='h04D4; 54: i='h04BD; 55: i='h04A7;
	    56: i='h0492; 57: i='h047D; 58: i='h0469; 59: i='h0456;
	    60: i='h0444; 61: i='h0432; 62: i='h0421; 63: i='h0410;
	    64: i='h0400; 65: i='h03F0; 66: i='h03E0; 67: i='h03D2;
	    68: i='h03C3; 69: i='h03B5; 70: i='h03A8; 71: i='h039B;
	    72: i='h038E; 73: i='h0381; 74: i='h0375; 75: i='h0369;
	    76: i='h035E; 77: i='h0353; 78: i='h0348; 79: i='h033D;
	    80: i='h0333; 81: i='h0329; 82: i='h031F; 83: i='h0315;
	    84: i='h030C; 85: i='h0303; 86: i='h02FA; 87: i='h02F1;
	    88: i='h02E8; 89: i='h02E0; 90: i='h02D8; 91: i='h02D0;
	    92: i='h02C8; 93: i='h02C0; 94: i='h02B9; 95: i='h02B1;
	    96: i='h02AA; 97: i='h02A3; 98: i='h029C; 99: i='h0295;
	    100: i='h028F; 101: i='h0288; 102: i='h0282; 103: i='h027C;
	    104: i='h0276; 105: i='h0270; 106: i='h026A; 107: i='h0264;
	    108: i='h025E; 109: i='h0259; 110: i='h0253; 111: i='h024E;
	    112: i='h0249; 113: i='h0243; 114: i='h023E; 115: i='h0239;
	    116: i='h0234; 117: i='h0230; 118: i='h022B; 119: i='h0226;
	    120: i='h0222; 121: i='h021D; 122: i='h0219; 123: i='h0214;
	    124: i='h0210; 125: i='h020C; 126: i='h0208; 127: i='h0204;
	    128: i='h0200; 129: i='h01FC; 130: i='h01F8; 131: i='h01F4;
	    132: i='h01F0; 133: i='h01EC; 134: i='h01E9; 135: i='h01E5;
	    136: i='h01E1; 137: i='h01DE; 138: i='h01DA; 139: i='h01D7;
	    140: i='h01D4; 141: i='h01D0; 142: i='h01CD; 143: i='h01CA;
	    144: i='h01C7; 145: i='h01C3; 146: i='h01C0; 147: i='h01BD;
	    148: i='h01BA; 149: i='h01B7; 150: i='h01B4; 151: i='h01B2;
	    152: i='h01AF; 153: i='h01AC; 154: i='h01A9; 155: i='h01A6;
	    156: i='h01A4; 157: i='h01A1; 158: i='h019E; 159: i='h019C;
	    160: i='h0199; 161: i='h0197; 162: i='h0194; 163: i='h0192;
	    164: i='h018F; 165: i='h018D; 166: i='h018A; 167: i='h0188;
	    168: i='h0186; 169: i='h0183; 170: i='h0181; 171: i='h017F;
	    172: i='h017D; 173: i='h017A; 174: i='h0178; 175: i='h0176;
	    176: i='h0174; 177: i='h0172; 178: i='h0170; 179: i='h016E;
	    180: i='h016C; 181: i='h016A; 182: i='h0168; 183: i='h0166;
	    184: i='h0164; 185: i='h0162; 186: i='h0160; 187: i='h015E;
	    188: i='h015C; 189: i='h015A; 190: i='h0158; 191: i='h0157;
	    192: i='h0155; 193: i='h0153; 194: i='h0151; 195: i='h0150;
	    196: i='h014E; 197: i='h014C; 198: i='h014A; 199: i='h0149;
	    200: i='h0147; 201: i='h0146; 202: i='h0144; 203: i='h0142;
	    204: i='h0141; 205: i='h013F; 206: i='h013E; 207: i='h013C;
	    208: i='h013B; 209: i='h0139; 210: i='h0138; 211: i='h0136;
	    212: i='h0135; 213: i='h0133; 214: i='h0132; 215: i='h0130;
	    216: i='h012F; 217: i='h012E; 218: i='h012C; 219: i='h012B;
	    220: i='h0129; 221: i='h0128; 222: i='h0127; 223: i='h0125;
	    224: i='h0124; 225: i='h0123; 226: i='h0121; 227: i='h0120;
	    228: i='h011F; 229: i='h011E; 230: i='h011C; 231: i='h011B;
	    232: i='h011A; 233: i='h0119; 234: i='h0118; 235: i='h0116;
	    236: i='h0115; 237: i='h0114; 238: i='h0113; 239: i='h0112;
	    240: i='h0111; 241: i='h010F; 242: i='h010E; 243: i='h010D;
	    244: i='h010C; 245: i='h010B; 246: i='h010A; 247: i='h0109;
	    248: i='h0108; 249: i='h0107; 250: i='h0106; 251: i='h0105;
	    252: i='h0104; 253: i='h0103; 254: i='h0102; 255: i='h0101;
	endcase
    end
endmodule
