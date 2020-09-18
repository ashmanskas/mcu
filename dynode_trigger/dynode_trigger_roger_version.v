/* This is a module used in the file ROCSTAR.v the top of the project
	It calculates the event start time from the dynode ADC signals for coincident
	testing and calculates the event energy for windowing.
	Started on 08/15/2018 by Roger E Arseneau for U of PENN ROCSTAR project
	This file replaces the file "dynode_triger" 
	
Rev.  00	09/24/2018	Start design for ROCSYAR detector board 
Rev.  00	10/12/2018	Ready for simulation 
Rev.  00	10/15/2018	Compile with full ROCSTAR.v 


*/
	
module dynode_trg 
  (
   // dynode trigger I/O
   input  wire        clk,
   input  wire        reset,
   input  wire [33:0] ibus,  //nu
   output wire [15:0] obus,	//nu
   input  wire [7:0]  data_in,
   output reg  [7:0]  MCU_trigger_out,  //coin trigger with time
   output wire  event_trigger_out,  //coin trigger
   output wire  [23:0]  event_time_out,  //coin time
   output wire  enecor_load,				// energy integrationcorrection  ready
   output wire [23:0] dyn_evntim,   	// event start time for event correction
   output wire [7:0] pulookup,  		 	// integ samples and phase
   output wire  [11:0]  dyn_enecor, 	// energy integration value corrected
   
   // control inputs set by register if not in simulation
   input  wire [7:0] timcnt,				//time counter   
   input wire [3:0] dynadcdly, 		// sets number of clk cyc delays to integrations and bsleline 
   input wire [1:0] selecttime,		// 0 = time from SD, 1 = time from cfd enetot 4 point, 2 = 1 pt
   input wire [3:0] smoothpmt, 			// set number of points in smooth 1, 2, 3, or 4 
 //  input wire [3:0] integcount,			// number of samples in a ful integration 
   input wire [11:0] integcntl,   			// Controls filter on sample count and phase of events passed
  
   // outputs for simulatton test
   output wire  [7:0]  adc_delay, 	// adc dlayed
   output wire  [11:0]  sum_integ, 	// integ sum

   // dynode data I/O
   input  wire [1:0]  trigger_data_mode,			// sets the number and type of data worde to load to fifo
   input  wire [3:0]  integration_pipeline_len, // sets the number of samples in the integration 
   input  wire [4:0]  data_pipeline_len,			// sets the delay to the ADC data loaded to the FIFO
   input  wire [1:0]  trigger_channel_select,
 //  input  wire [7:0]  trigger_channel_mux,
   input  wire        trigger,
   input  wire        trigger_data_fifo_ren,
   output wire [15:0] trigger_data_fifo_q,
   output wire        trigger_data_fifo_ne,
   output wire        trigger_data_fifo_full

   );
   
   localparam
   pileupdly= 4'h0011  // delay adc for time of pileup
   ;
   
  // control inputs set by breg register in the module ROCSTAR.v 
 //   bror #('h0002) r0002(ibus, obus, register);   // read register
 //   breg #('h0003) r0003(ibus, obus, register);    // write register
//   wire [7:0] timcnt,				//time counter   
//    breg #('h1D01) r1D91(ibus, obus, timcnt);    // write register
//   wire [3:0] dynadcdly, 		// sets number of clk cyc delays to integrations and bsleline 
//     breg #('h1D02) r1D91(ibus, obus, dynadcdly);    // write register
//  wire [1:0] selecttime,		// 0 = time from SD, 1 = time from cfd enetot 4 point, 2 = 1 pt
//     breg #('h1D03) r1D91(ibus, obus, selecttime);    // write register
//  wire [3:0] smoothpmt, 			// set number of points in smooth 1, 2, 3, or 4 
//     breg #('h1D04) r1D91(ibus, obus, smoothpmt);    // write register
//  wire [11:0] integcntl,   			// Controls filter on sample count and phase of events passed
//     breg #('h1D06) r1D91(ibus, obus, integcntl);    // write register
  
   // simulation outputs
   	always @ (*) begin
//	dyn_ingcnt <=  dyn_ingcnt_sig ;
	end

  // connection signals
   wire 		dyn_indet_sig;		//event may be present
   wire 		dyn_event_sig;		//event detected
   wire 		dyn_pileup_sig;		//pileup up event detected
   reg [7:0]  dyn_data_in_sig;		//dynode ADC data
  wire  [11:0]  dyn_blcor_sig;		//baseline corrected ADC for event detection 
  wire [7:0] 	dyn_adcdly_sig;		//delayed ADC data for energy integration 
  wire [15:0] dyn_curval_sig	;	//baseline for energy integration baseline correction 
  wire [23:0] evntim_sig	;			//event time from eventdet 
  wire dyn_pudump_sig ;	// indicates event was dumped because it was two
  wire [11:0] dyn_energy_sig ;	// dynode integrated energy uncorrected
  wire [3:0] dyn_ingcnt_sig ;		// number of samples in the integrated value
  wire ene_load_sig ;	// output  dyn_ene_load_sig
  wire  [23:0] dyn_evntim_sig ; 	// event start time of integrated event
  wire enecor_load_sig ;	// output  dyn_ene_load_sig
   wire [7:0] 	dynadc_dly_sig;		//delayed ADC data from energy integration 

  assign enecor_load = enecor_load_sig ;
  assign event_trigger_out = dyn_event_sig ;
  assign event_time_out = evntim_sig ;
   
dynode_baseline dynbl
(
	.clk(clk) ,	// input  clk_sig
	.reset(reset) ,	// input  reset_sig
	.dyn_indet(dyn_indet_sig) ,	// input  dyn_indet_sig
	.dyn_event(dyn_event_sig) ,	// input  dyn_event_sig
	.dyn_pileup(dyn_pileup_sig) ,	// input  dyn_pileup_sig
	.dyn_pudump(dyn_pudump_sig) ,	// input  dyn_pudump_sig
	.dyn_data_in(data_in) ,			// input [7:0] dyn_data_in_sig
	.dynadcdly(dynadcdly) ,				// input [3:0] sets number of clk cyc delays to integrations and bsleline 
	.dyn_blcor(dyn_blcor_sig) ,	// output [11:0] dyn_blcor_sig
	.dyn_adcdly(dyn_adcdly_sig) ,	// output [7:0] dyn_adcdly_sig
	.dyn_curval(dyn_curval_sig) 	// output [15:0] dyn_curval_sig
);

		// delay baseline corrected adc 
    reg [11:0] blcor_dly [15:0];
    always @ (posedge clk) begin
	blcor_dly[0] <= dyn_blcor_sig;
	blcor_dly[1] <= blcor_dly[0];
	blcor_dly[2] <= blcor_dly[1];
	blcor_dly[3] <= blcor_dly[2];
	blcor_dly[4] <= blcor_dly[3];
	blcor_dly[5] <= blcor_dly[4];
	blcor_dly[6] <= blcor_dly[5];
	blcor_dly[7] <= blcor_dly[6];
	blcor_dly[8] <= blcor_dly[7];
	blcor_dly[9] <= blcor_dly[8];
	blcor_dly[10] <= blcor_dly[9];
	blcor_dly[11] <= blcor_dly[10];
	blcor_dly[12] <= blcor_dly[11];
	blcor_dly[13] <= blcor_dly[12];
	blcor_dly[14] <= blcor_dly[13];
	blcor_dly[15] <= blcor_dly[14]; end

dynode_eventdet dyned
(
	.clk(clk) ,	// input  clk_sig
	.reset(reset) ,	// input  reset_sig
	.timcnt(timcnt) ,	// input [7:0] timcnt_sig
	.dyn_blcor(dyn_blcor_sig) ,	// input [11:0] dyn_blcor_sig
	.selecttime(selecttime) ,	// input [1:0] selecttime_sig
	.smoothpmt(smoothpmt) ,	// input [3:0] smoothpmt_sig
	.dyn_indet(dyn_indet_sig) ,	// output  dyn_indet_sig
	.dyn_event(dyn_event_sig) ,	// output  dyn_event_sig
	.dyn_pileup(dyn_pileup_sig) ,	// output  dyn_pileup_sig
	.dyn_pudump(dyn_pudump_sig) ,	// output  dyn_pudump_sig
	.evntim(evntim_sig) 	// output [23:0] evntim_sig
);

   always @ (posedge clk) begin		 //send coin trigger time
 	if (dyn_event_sig == 1'b0 ) MCU_trigger_out <= 8'b11111111 ;
	else if (dyn_event_sig == 1'b1 )begin
		if  (evntim_sig[11:6] == 6'b111111 == evntim_sig[11:6]) MCU_trigger_out <= 2'hF8 ;
		else MCU_trigger_out <= evntim_sig[11:4] ; end
	end

dynode_integrate dynintg
(
	.clk(clk) ,	// input  clk_sig
	.reset(reset) ,	// input  reset_sig
	.integcount(integration_pipeline_len) ,	// input [3:0] integcount_sig
	.dyn_adcdly(dyn_adcdly_sig) ,	// input [7:0] dyn_adcdly_sig
	.dyn_curval(dyn_curval_sig) ,	// input [15:0] dyn_curval_sig
	.dyn_event(dyn_event_sig) ,	// input  dyn_event_sig
	.evntim(evntim_sig) ,	// input [23:0] evntim_sig
	.dyn_energy(dyn_energy_sig) ,	// output [11:0] dyn_energy_sig
	.dyn_ingcnt(dyn_ingcnt_sig) ,	// output [3:0] dyn_ingcnt_sig
	.ene_load(ene_load_sig) ,	// output  dyn_ene_load_sig
	.dyn_evntim(dyn_evntim_sig), 	// output [23:0] dyn_evntim_sig
	.adc_delay(adc_delay), 	// output [7:0] delayse adc
	.sum_integ(sum_integ), 	// output [11:0] integ sum
	.dynadc_dly(dynadc_dly_sig) 	// output [7:0] dynadc_dly_sig
);

dynode_pileup dynpiup
(
	.clk(clk) ,	// input  clk_sig
	.reset(reset) ,	// input  reset_sig
	.integcount(integration_pipeline_len) ,	// input [3:0] integcount_sig
	.dyn_ingcnt(dyn_ingcnt_sig) ,	// input [3:0] dyn_ingcnt_sig
	.dyn_energy(dyn_energy_sig) ,	// input [11:0] dyn_energy_sig
	.ene_load(ene_load_sig) ,	// input  ene_load_sig
	.evntim(dyn_evntim_sig) ,	// input [23:0] evntim_sig
	.integcntl(integcntl) ,	// input [11:0] integcntl_sig
	.dyn_enecor(dyn_enecor) ,	// output [11:0] dyn_enecor_sig
	.enecor_load(enecor_load_sig ) ,	// output  enecor_load_sig
	.dyn_evntim(dyn_evntim) ,	// output [23:0] dyn_evntim_sig
	.pulookup(pulookup) 	// output [7:0] pulookup_sig
);

 // load fifo with energy or ADC raw or ADC baseline corrected.
 
      always @ (posedge clk) begin
	if ( trigger_data_mode == 2'b01 )
			data_dly[0] <= { 4'b0000, dynadc_dly_sig }; //raw ADC data
	else data_dly[0] <=   blcor_dly[14] ;	// baseline corrected delayed
	end
		// delay selected adc data 
    reg [11:0] data_delay [15:0];
    reg [11:0] data_dly [7:0];
    reg [11:0] data_dlylast ;
    always @ (posedge clk) begin
	data_dly[1] <= data_dly[0];
	data_dly[2] <= data_dly[1];
	data_dly[3] <= data_dly[2];
	data_dly[4] <= data_dly[3];
	data_dly[5] <= data_dly[4];
	data_dly[6] <= data_dly[5];
	data_dly[7] <= data_dly[6];
	data_delay[0] <= data_dly[pileupdly];
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
	data_dlylast <= data_delay[data_pipeline_len[3:0]];
    end
    
   reg [15:0] dynode_energy;
   reg trigger_fifo_load ;

    always @ (posedge clk) begin
	if  ( enecor_load_sig == 1'b1)begin
		dynode_energy <= {4'b0000, dyn_enecor } ;
		trigger_fifo_load <= enecor_load_sig ;
	end
	else trigger_fifo_load <= trigger ;
	end
    
    // trigger data fifo
    reg tdf_wen;
    reg [15:0] trigger_data = 16'b0;
       
	fifo33 #(.W(16)) trigger_data_fifo 
      (.clk(clk), .rst(reset), .d(trigger_data), 
       .wen(tdf_wen),
       .ren(trigger_data_fifo_ren), .q(trigger_data_fifo_q),
       .nempty(trigger_data_fifo_ne), .nearlyfull(trigger_data_fifo_full));

    // trigger spy data fifo write controls
    // no flow control at present.
    reg [5:0] tdf_count = 6'b0;
    reg [2:0] fsm = 3'b0;
    localparam 
      FSM_IDLE=0, FSM_PREAMBLE=1, FSM_NWORDS=2, 
      FSM_MASK=3, FSM_DATA=4, FSM_EOF=5;
    reg [15:0] nwords = 0;
    always @ * begin
	case(trigger_data_mode)
	    2'b00: nwords = 16'h0001;
	    2'b01: nwords = 16'h0021;
	    2'b10: nwords = 16'h0021;
	    2'b11: nwords = 16'h0011;
	endcase
    end
    reg [15:0] trigger_data_mask = 16'b0;
    always @ * begin
	case(trigger_channel_select)
	    2'b00: trigger_data_mask = 16'h0001;
	    2'b01: trigger_data_mask = 16'h0002;
	    2'b10: trigger_data_mask = 16'h0004;
	    2'b11: trigger_data_mask = 16'h0008;
	endcase
    end
    always @ (posedge clk) begin
	if (reset) begin
	    fsm <= 3'b0;
	    trigger_data <= 16'b0;
	    tdf_wen <= 1'b0;
	    tdf_count <= 6'b0;
	end else begin
	    case(fsm)
		FSM_IDLE:
		  begin
		      tdf_wen <= 1'b0;
		      tdf_count <=  nwords ;
		      fsm <= trigger_fifo_load ? FSM_PREAMBLE : FSM_IDLE;
		  end
		FSM_PREAMBLE:
		  begin
		      trigger_data <= 16'hA5A5;
		      tdf_wen <= 1;
		      fsm <= FSM_NWORDS;
		  end
		FSM_NWORDS:
		  begin
		      trigger_data <= nwords;
		      tdf_wen <= 1;
		      fsm <= FSM_MASK;
		  end
		FSM_MASK:
		  begin
		      trigger_data <= trigger_data_mask;
		      tdf_wen <= 1;
		      fsm <= FSM_DATA;
		  end
		FSM_DATA:
		  begin
		      if (tdf_count == 6'b000000 ) begin
				tdf_wen <= 0;
				fsm <= FSM_IDLE;
		      end 
		      else if (tdf_count == 6'b000001 ) begin
				tdf_wen <= 1;
				fsm <= FSM_IDLE;
				trigger_data <= dynode_energy;
		      end
		      else begin
				tdf_wen <= 1;
				fsm <= FSM_DATA;
				trigger_data <= { 4'b0000, data_dlylast } ;
		      end
		      tdf_count <=  tdf_count - 1 ;
		  end
		FSM_EOF:
		  begin
		      tdf_wen <= 0;
		      fsm <= FSM_IDLE;
		  end
	    endcase
	end
    end
    
endmodule

module MCU_trigger_tx 
  (
   input wire clk,
   input wire clk_4x,
   input wire serdesstrobe,
   input wire rst,
   input wire [7:0] mcu_trigger_data,
   output wire [1:0] trigger_serial
   );

    MCU_tx tx0 (.clk(clk), .clk_4x(clk_4x),
		.serdesstrobe(serdesstrobe), .rst(rst),
		.data_in(mcu_trigger_data[3:0]),
		.serial_out(trigger_serial[0]));

    MCU_tx tx1 (.clk(clk), .clk_4x(clk_4x),
		.serdesstrobe(serdesstrobe), .rst(rst),
		.data_in(mcu_trigger_data[7:4]),
		.serial_out(trigger_serial[1])); 
endmodule


// this module is a placeholder for a future module which should be
// imported from Bill.
module MCU_trigger_rx 
  (
   input wire clk,
   input wire clk_4x,
   input wire serdesstrobe,
   input wire rst,
   input wire mcu_trigger_inp,
   input wire mcu_trigger_inn,
   input wire [7:0] data_delay,
   output wire [3:0] trigger_MCU,
   output wire out_valid,
   output wire [15:0] bitslip_cycles
   );

    // Framing alignment: bitslips until output is all zeros
    reg slip = 0;

    // receive and buffer differential serial data
    wire mcu_trigger_in,mcu_trigger_in_delay;
    IBUFDS #(.IOSTANDARD("DEFAULT"), .DIFF_TERM("TRUE")) 
    ibufds_lane1 
      (.O(mcu_trigger_in), .I(mcu_trigger_inp), .IB(mcu_trigger_inn));

    // delay data signal.  xilinx user guide says to use separate
    // delays for master and slave when cascading iserdes blocks.
    // calibration seems to only be of use when using
    // VARIABLE_FROM_HALF_MAX as the purpose of the calibration is
    // to calculate how many taps correspond to the incoming clock
    // period.  This information is not made available to the fabric.

    reg cal = 1'b0;
    reg [5:0] cal_counter = 6'b0;
    reg iodelay2_reset = 1'b1;
    wire iodelay2_m_busy, iodelay2_s_busy;
    reg [7:0] delay_setting = 8'b0;
    reg inc = 1'b0;
    reg clkena = 1'b0;
    reg [3:0] iod_fsm = 4'b0;

    // fsm to increment/decrement iodelay setting to match the
    // requested value.
    always @ (posedge clk) begin
	if (rst) begin
	    iod_fsm <= 4'b0;
	    inc <= 1'b0;
	    clkena <= 1'b0;
	    delay_setting <= 8'b0;
	end else begin
	    case (iod_fsm)
		0: iod_fsm <= delay_setting == data_delay ? 0 : 1;
		1:
		  begin
		      inc <= delay_setting < data_delay ? 1'b1 : 1'b0;
		      clkena <= 1'b1;
		      iod_fsm <= 2;
		  end
		2:
		  begin
		      delay_setting <= 
                        inc ? delay_setting + 1 : delay_setting - 1;
		      inc <= 1'b0;
		      clkena <= 1'b0;
		      iod_fsm <= 3;
		  end
		3: iod_fsm <= 4;
		4: iod_fsm <= 5;
		6: iod_fsm <= 0;
	    endcase
	end
    end

IODELAY2 #(.IDELAY_VALUE(0), .IDELAY_TYPE("VARIABLE_FROM_ZERO"),
	   .DELAY_SRC("IDATAIN"), .DATA_RATE("SDR")) 
    iodelay2_data_m
      (.IDATAIN(mcu_trigger_in), .CAL(cal), .IOCLK0(clk_4x),
       .IOCLK1(), .CLK(clk), .INC(inc), .CE(clkena),
       .RST(iodelay2_reset), .BUSY(iodelay2_m_busy),
       .DATAOUT(mcu_trigger_in_delay));


    reg bitslip = 1'b0;
    ISERDES2 #(.DATA_RATE("SDR"), .DATA_WIDTH(4), .BITSLIP_ENABLE("TRUE"),
	       .SERDES_MODE("MASTER"), .INTERFACE_TYPE("RETIMED")) 
    iserdes2_lane1 
      (.CLK0(clk_4x), .CLK1(), .CLKDIV(clk),
       .CE0(1'b1), .BITSLIP(bitslip), .D(mcu_trigger_in_delay),
       .RST(rst), .IOCE(serdesstrobe), .SHIFTOUT(),
       .Q4(trigger_MCU[0]), .Q3(trigger_MCU[1]),
       .Q2(trigger_MCU[2]), .Q1(trigger_MCU[3]));

	// Bitslip state machine
    localparam
      IDLE0=00, IDLE1=01, IDLE2=02, IDLE3=03,
      IDLE4=04, IDLE5=05, IDLE6=06, IDLE7=07,
      CHECK=08, BSLIP=09, WAIT0=10, WAIT1=11,
      WAIT2=12, WAIT3=13, WAIT4=14, HALT =15;
    reg [3:0] fsm = 0;
    reg [3:0] fsmnext = 0;
    reg [15:0] bitslip_cycles_reg = 16'b0;
    assign bitslip_cycles = bitslip_cycles_reg;
    always @ (posedge clk) begin
	if (rst) bitslip_cycles_reg <= 16'b0;
	else bitslip_cycles_reg <= 
             bitslip ? bitslip_cycles_reg + 1 : bitslip_cycles_reg;
    end
    always @ (posedge clk)
      fsm <= (rst ? IDLE0 : fsmnext);
    always @* begin
        fsmnext = IDLE0;
        case (fsm)
            IDLE0 : fsmnext = IDLE1;
            IDLE1 : fsmnext = IDLE2;
            IDLE2 : fsmnext = IDLE3;
            IDLE3 : fsmnext = IDLE4;
            IDLE4 : fsmnext = IDLE5;
            IDLE5 : fsmnext = IDLE6;
            IDLE6 : fsmnext = IDLE7;
            IDLE7 : fsmnext = CHECK;
            CHECK : fsmnext = (trigger_MCU[3] ? HALT : BSLIP);
            BSLIP : fsmnext = WAIT0;
            WAIT0 : fsmnext = WAIT1;
            WAIT1 : fsmnext = WAIT2;
            WAIT2 : fsmnext = WAIT3;
            WAIT3 : fsmnext = WAIT4;
            WAIT4 : fsmnext = CHECK;
            HALT  : fsmnext = (trigger_MCU[3] ? HALT : IDLE0);
        endcase  // case (fsm)
    end
    // Bitslip signal
    always @ (posedge clk)
      bitslip <= (fsm==BSLIP) && !rst;
    // Channel-aligned signal: indicates that word alignment is completed
    reg aligned = 0;
    always @ (posedge clk)
      aligned <= (fsm==HALT) && !rst;
    assign out_valid = aligned;
endmodule



