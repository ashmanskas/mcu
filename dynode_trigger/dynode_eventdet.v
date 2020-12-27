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
   input wire 	     clk,
   input wire 	     reset,
   input wire [7:0]  timcnt, //time counter   
   input wire [11:0] dyn_blcor, //baseline corrected ADC for event detection 
   output reg 	     dyn_indet, //event may be present
   output reg 	     dyn_event, //event detected
   output reg 	     dyn_pileup, //pileup up event detected
   output reg 	     dyn_pudump, //fd to wide
   output reg [23:0] evntim
  );
   
   localparam
     selecttime      = 0,    	// 0 = time from SD, 1 = time from cfd enetot 4 point, 2 = 1 pt
     smoothpmt	     = 3,     	// set number of points in smooth  
     sdtim0adj 	     = 12'b001100001001, 	// time adjust for sd time
     indetonlevel    = 14'b0000_0100_000000,    // indet turn on level
     indetofflevel   = 14'b0000_0010_000000,    // indet turn off level
     fdonlevel       = 15'b0_0000_1000_000000,  // fd minimum for event
     sdonlevel	     = 15'b0_0000_0110_000000,  // sd minimum for event
     pudetwide	     = 3'b100;                  // evenr to close os dump both
			  

   // Delay  to smooth data for 100 mhz sample 
   // rate to remove dead spots do to rise time less then 10 ns.
   reg [11:0] dynblcor_d [1:0];
   always @ (posedge clk) begin
      dynblcor_d[0] <= dyn_blcor;
      dynblcor_d[1] <= dynblcor_d[0];
   end

   

   reg [13:0] enesmo;
   
   // smooth dynode signal for event test 1, 2, 3, 4 and 5
   // 5 is a 3 point with the center point weighted twice
   // value times 4  for all except 3 is 3 times
   always @ (posedge clk) begin
      
      enesmo <= dyn_blcor + dynblcor_d[0] + dynblcor_d[1];

      if (indet == 1'b0)
        indet <= (enesmo > indetonlevel);
      else indet <= (enesmo > indetofflevel);

      piledet = ((indet == 1'b1) & (enefd > fdonlevel) & (enefd[14] != 1'b1));	
   end 

   
   reg [14:0]	enefd;		// first derivative signed	
   reg [14:0] 	enefd_d;	// first derivative delayed signed	
   reg [14:0] 	enesd;	        // second derivative signed
   reg [14:0] 	enesd_d;	// second derivative signed
   reg [14:0] 	enesd_p;
   reg [14:0] 	enesd_n;
   reg [14:0] 	enesd_dif;      // the change in sd at zero crossing
   reg [7:0] 	evnt_timsd;     // the vslue of event time at sd  zero crossing
   reg 		indet;		// event may be present enesmo greater then noise
   reg 		piledet;	// fd greater then noise
   reg 		evnt;		// event detected
   reg 		pileup;		// pileup up event detected
   reg [2:0] 	pucnt;		// pileup count for pileup to close
   reg 		pudmp;		// dump pileup count for pileup to close
   reg [23:0] 	sd_evnttim;     // time of sd crossing with fraction

   always @ (posedge clk) begin		 //gen fd and sd
      enefd <= enesmo - enesmo_d;
      enefd_d <= enefd;
      enesd <= enefd - enefd_d;
      enesd_d <= enesd;
      
      // generate SD event time from counter input and cycle fraction
      if (smed == sed3) sd_evnttim <= sd_timadj;
      
      if (evnten == 1'b1) begin ; //sd neg  captures crossing
	 enesd_n <= enesd;
	 enesd_p <= enesd_d;
	 evnt_timsd <= timcnt;
       end      
   end
   
   reg evnten;		        // start looking for sd neg to capture event data
   reg fden;			// fd reach enable level
   reg sden;		        // sd reach enable level
   reg sdneg;	
   reg [24:0] sd_timfrac;	// fraction of clock cycle sd crossing occured
   reg [23:0] sd_timadj;	// fraction of clock cycle sd crossing adjusted
   reg 	      sd_delay;
   reg [12:0] fraction;
   reg [11:0] whole_num;
   reg [11:0] whole_num_sum;
   
   
   always @ (*) begin // select sd time or cfd time
      if ((indet == 1'b1) & (enefd > fdonlevel) & (enefd[14] != 1'b1) & (smed ==sed0)) fden = 1'b1;
      else if ((indet == 1'b1) & (evnten == 1'b0)) fden = fden;  	//event fd above enable level
      else fden = 1'b0;
      
      if ((indet == 1'b1) & (enesd > sdonlevel) & (enesd[14] != 1'b1) & (smed ==sed0)) sden = 1'b1;
      else if ((indet == 1'b1) & (evnten == 1'b0)) sden = sden;		//event sd above enable level
      else sden = 1'b0;
      
      if ((indet == 1'b1) & (fden == 1'b1) & (sden == 1'b1)) evnten = 1'b1;
      else if ((indet == 1'b1) & (smed == sed1)) evnten = evnten;	//wait for sd to go negative
      else evnten = 1'b0;
      
   end

   always @ (*) begin

      if (sd_timfrac[15:4] <= sdtim0adj) begin
	 fraction <= {1'b0, sdtim0adj} - {1'b0, sd_timfrac[15:4]};
	 if (dynblcor_d[0] >= dynblcor_d[1]) begin
	    whole_num <= evnt_timsd - 1'b1; end
	 else begin
	    whole_num <= evnt_timsd + 1'b1; end 
      end else begin
	 fraction <= {1'b1, sdtim0adj} - {1'b0, sd_timfrac[15:4]};
	 whole_num <= evnt_timsd;
      end

      whole_num_sum <= whole_num + fraction[12];

      sd_timadj <= {3'b000, whole_num_sum, fraction[11:0]};
      sd_delay <= 1'b1; 
	 
      
      // determine size of enesd_dif to scale to inverse value and multiply for timing
      if (enesd_dif[13] == 1'b1) begin
	 sd_delt <= (enesd_dif[13:6]);
	 sd_timfrac <= enesd_p[14:6] * invrt_deltw; end
      else if (enesd_dif[12] == 1'b1) begin 
	 sd_delt <= (enesd_dif[12:5]);
	 sd_timfrac <= enesd_p[13:5] * invrt_deltw; end
      else if (enesd_dif[11] == 1'b1) begin  	
	 sd_delt <= (enesd_dif[11:4]);
	 sd_timfrac <= enesd_p[12:4] * invrt_deltw; end
      else if (enesd_dif[10] == 1'b1) begin  	
	 sd_delt <= (enesd_dif[10:3]);
	 sd_timfrac <= enesd_p[11:3] * invrt_deltw; end
      else if (enesd_dif[9] == 1'b1) begin
	 sd_delt <= (enesd_dif[9:2]);
	 sd_timfrac <= enesd_p[10:2] * invrt_deltw; end
      else if (enesd_dif[8] == 1'b1) begin
  	 sd_delt <= (enesd_dif[8:1]);
	 sd_timfrac <= enesd_p[9:1] * invrt_deltw; end
      else                           begin
	 sd_delt <= (enesd_dif[7:0]);
	 sd_timfrac <= enesd_p[8:0] * invrt_deltw; end

      sdneg <= (enesd[14] == 1'b1);
      invrt_delt <= invrt_deltw;
      enesd_dif <= enesd_p - enesd_n;
      
      dyn_event <= (smed == sed5);
      
      // outputs
      dyn_indet <= indet;
      dyn_pileup <= piledet;		// pileup up event detected
      dyn_pudump <= pudmp;		// pileup up event to close
      evntim <= sd_evnttim;

   end
   
   wire [7:0] sd_deltw;
   assign sd_deltw = sd_delt;
   reg [7:0]  sd_delt;
   reg [15:0] invrt_delt;
   wire [15:0] invrt_deltw;
   
   inverse_lookup sdi(sd_deltw, invrt_deltw);
   
   localparam                           // state machine for event detection
     sed0=0, sed1=1, sed2=2, 
     sed3=3, sed4=4, sed5=5;
   reg [2:0]   smed ;
   always @ (posedge clk) begin
      if (reset) begin
	 smed <= 3'b0;
      end else begin
	 case(smed)
	   sed0:			// wait for event
	     begin
		smed <= evnten ? sed1 : sed0;
		pudmp <= 1'b0; 
		pucnt <= 3'b000;
	     end
	   sed1:			//wait for sd to go negative
	     begin  
		pucnt <= pucnt + 1;
		if (!(pucnt >= pudetwide)) begin
		   smed <= sdneg ? sed2 : sed1;
		   pudmp <= 1'b0; end
		else begin 
		   smed <= sed0;
		   pudmp <= 1'b1; end
	     end
	   sed2:			// start calculation of sd time fraction
	     begin
		pucnt <= 3'b000;
		smed <=  sed3;
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
		smed <= sed0;
	     end
	 endcase
      end
   end
   
   
   // Delay for timming test  
   reg [13:0] enesmo_d;
   always @ (posedge clk) begin
      enesmo_d <= enesmo;
   end
      
endmodule

`default_nettype wire

