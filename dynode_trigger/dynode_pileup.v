`default_nettype none

/* This is a module used in the file dynode_trg.v which is under the project ROCSTAR
	It corrects the energy sum of the dynode ADC signals for
	pileup and start phasen..
	Started on 09/12/2018 by Roger E Arseneau for U of PENN ROCSTAR project
	
Rev.  00	09/12/2018	Start design for ROCSYAR detector board 
Rev.  00	10/15/2018	Compile with full ROCSTAR.v 

*/
	
module dynode_pileup 
  (
   input  wire        clk,
   input  wire        reset,
   input wire [3:0] integcount,			// number of samples in a ful integration 
   input wire [3:0]  dyn_ingcnt,		// number of integration samples in event
   input wire 	[11:0]  dyn_energy, 	// energy integration value
   input wire ene_load,					// energy integration ready
   input wire [23:0] evntim,   			// event start time to correct integration value
   input wire [11:0] integcntl,   			// Controls filter on sample count and phase of events passed
   output reg  [11:0]  dyn_enecor, 	// energy integration value corrected
   output reg  enecor_load,				// energy integrationcorrection  ready
   output reg [23:0] dyn_evntim,   	// event start time for event correction
   output reg [7:0] pulookup  		 	// integ samples and phase
 
    //output for simulation
 //  , 
//   input wire [3:0] integstartdly, 
//   input wire [3:0] integcount, 
//   output reg [2:0] smiao, 
//   output reg [2:0] smibo, 
//   output reg dyna_evento, 
//   output reg dynb_evento, 
// 	output reg  [27:0] enetailo ,
//	output reg [15:0] pucorrwo 

   );

	// integcntl first hex word 	// all 0 pass all events, bit 0 =1 only full integration
										// bit 1 =1 pass only samples = integcntl[7:4]
										// bit 2 =1 pass only phase = integcntl[11:8]
										// bit 2 and 3 may both be set together
										// bit 3 =1 do not correct event
	wire [3:0] integcntcntl ;	// set number of event samples to pass 
	wire [3:0] integphase ; 	// set the event phase to pass
  	assign integcntcntl 	= integcntl[7:4] ;
 	assign integphase 	= integcntl[11:8] ;   

  

	reg [11:0] energy ;		// integ_sum -  bl_cor/16 = the uncorrected energy
	reg [23:0] evnttim ;		// bits [11:8] divide the clock into 16 phases.
	reg [3:0] ingcnt ;			// number of integration samples in event
	reg [7:0] pulokup ;		// bits 7:4 nu of samples bits 3:0 phase 1/6 cycle
	reg [11:0] enecor ;		// corrected energy value

    // latch event data
    
    always @ (posedge clk) begin
	
	if ( reset == 1'b1 )begin
		energy <= 12'h000 ;		
		evnttim <= 20'h00000 ;	
		pulokup <= 8'h00 ;	
		enecor	 <= 12'h000 ;	
		ingcnt <= 4'h0 ; end
	else if ((ene_load == 1'b1 )& ( smpu == spu0 )) begin
		energy <= dyn_energy ;		
		evnttim <= evntim ;		
		pulokup <= { dyn_ingcnt, evntim[11:8]} ;	
		enecor	<= dyn_energy ;	
		ingcnt  <= dyn_ingcnt ; end
	else if ( smpu == spu2) 
		if (integcntl[3] == 1'b0 ) enecor <= energy +  enetail[23:12] ;	//add tail correvtion for pileup and phase
		else enecor <= energy ;
	end

	wire [7:0] pulokupw ;
	assign pulokupw  =  pulokup ;
	wire [15:0] pucorrw ;
	reg [27:0] enetail ;		// corrected energy tail value 12 bits * 16 bits 12 bit fraction

    pileup_lookup pulup(pulokupw , pucorrw );
    
	always @ (*) begin
		enetail <=   energy * pucorrw ; 
		if ( smpu == spu3) begin  		//output event
			dyn_enecor  <= enecor ;
			dyn_evntim  <=  evnttim ;
			enecor_load  <= 1'b1 ;
			pulookup  =  pulokupw ;	end
		else begin
			dyn_enecor  <= enecor ;
			dyn_evntim  <=  evnttim ;
			enecor_load  <= 1'b0 ;
			pulookup  =  pulokupw ;	end

	end
	
//	always @ (*) begin	// output for simulation
//	pucorrwo <= pucorrw ;
//	enetailo <= enetail ;
//	
//	end

   localparam  // state machine for energy correction
      spu0=0, spu1=1, spu2=2, 
      spu3=3, spu4=4, spu5=5;
	reg [2:0] smpu ;
    always @ (posedge clk) begin
	if (reset) begin
	    smpu <= 3'b0;
	end else begin
	    case(smpu)
		spu0:			// wait for event
		  begin
		      smpu <= ene_load ? spu1 : spu0;
		  end
		spu1:			//test to see if event should be passed
		  begin  
			if (integcntl[2:0] == 3'b000)smpu <= spu2 ;
			else if (integcntl[2:0] == 3'b001)smpu <= ( integcount == ingcnt )   ? spu2 : spu0;
			else if (integcntl[2:0] == 3'b010)smpu <= ( integcntcntl == ingcnt )   ? spu2 : spu0;
			else if (integcntl[2:0] == 3'b100)smpu <= ( integphase == evnttim[11:8] )? spu2 : spu0;
			else if (integcntl[2:0] == 3'b110)
				smpu <= (( integphase == evnttim[11:8]) & ( integcntcntl == ingcnt ) )? spu2 : spu0;
			else  smpu <= spu2 ; 
			end
		spu2:			// correct integration value
		  begin
		    smpu <=  spu3 ;
		  end
		spu3:
		  begin
		      smpu <=  spu0;
		  end
		spu4:
		  begin
		      smpu <=  spu0;
		  end
		spu5:
		  begin
			smpu <= spu0 ;
		 end
	    endcase
	end
    end
    
// load fifo

    
    
    
endmodule

/*
0000	0000	0017	002E	003A	0046	005E	0076	0082	008E	0076	005E	003A	0017	000B	0000
02EC	025F	0206	01B0	016B	0128	0100	00DA	00B4	008E	0076	005E	003A	0017	000B	0000
2441	1EB0	1A31	167C	1360	10BC	0E9F	0CC4	0B1F	09A8	083D	06F7	05E8	04F0	0432	0381
15.7	    14.8	    13.7	    12.4	    10.8	     9.0	    7.6	    6.5	     5.6	     4.8	      4.0	      3.2	      2.6	      1.9	      1.2	     0.5

*/


module pileup_lookup
  (
   input  wire [7:0] value,
   output wire [15:0] inverse
   );
    reg [15:0] i;
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
	    28: i='h0924; 29: i='h08D3; 30: i='h0888; 31: i='h2441;
	    // integrate sample count = 2
	    32: i='h0381; 33: i='h0432; 34: i='h04F0; 35: i='h05E8;
	    36: i='h06F7; 37: i='h083D; 38: i='h09A8; 39: i='h0B1F;
	    40: i='h0CC4; 41: i='h0E9F; 42: i='h10BC; 43: i='h1360;
	    44: i='h167C; 45: i='h1A31; 46: i='h1EB0; 47: i='h2441;
	    // integrate sample count = 3
	    48: i='h0000; 49: i='h000B; 50: i='h0017; 51: i='h003A;
	    52: i='h005E; 53: i='h0076; 54: i='h008E; 55: i='h00B4;
	    56: i='h00DA; 57: i='h0100; 58: i='h0128; 59: i='h016B;
	    60: i='h01B0; 61: i='h0206; 62: i='h025F; 63: i='h02EC;
	    // integrate sample count = 4
	    64: i='h0000; 65: i='h000B; 66: i='h0017; 67: i='h003A;
	    68: i='h005E; 69: i='h0076; 70: i='h008E; 71: i='h0082;
	    72: i='h0076; 73: i='h005E; 74: i='h0046; 75: i='h003A;
	    76: i='h002E; 77: i='h0017; 78: i='h0000; 79: i='h0000;
	    
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

`default_nettype wire

