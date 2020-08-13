/*
 * mcu_logic.v
 * 
 * Algorithmic logic for prototype Master Coincidence Unit, omitting
 * the Xilinx-specific details to simplify simulation
 * 
 * begun 2020-06-25 by wja and sz
 */

`timescale 1ns / 1ps
`default_nettype none

module mcu_logic
  (
   // 100 MHz system-wide master clock (generated on MCU)
   input  wire        clk,
   // Register file "bus" for control & monitoring via network
   input  wire [15:0] baddr,
   input  wire [15:0] bwrdata,
   output wire [15:0] brddata,
   input  wire        bwr,
   input  wire        bstrobe,
   // For each ROCSTAR <-> MCU connector, 8 bits in and 4 bits out
   input  wire [7:0]  A1in, A2in, A3in, A4in,
   output wire [3:0]  A1out, A2out, A3out, A4out,
   input  wire [7:0]  B1in, B2in, B3in, B4in,
   output wire [3:0]  B1out, B2out, B3out, B4out
   );
    // Instantiate register file "bus" I/O
    wire [33:0] ibus = {clk, bwr, baddr, bwrdata};
    wire [15:0] obus;
    assign brddata = obus;
    bror #(16'h0000) r0000(ibus, obus, 16'h1234);  // read-only register
    wire [15:0] q0001;
    breg #(16'h0001) r0001(ibus, obus, q0001);  // dummy read/write register
    wire [15:0] spword;
    breg #(16'h0002) r0002(ibus, obus, spword);
    reg do_spword = 0;
    always @ (posedge clk) begin
        // Pulse 'do_spword' for one clk cycle upon write to 'spword'
        do_spword <= (baddr == 16'h0002 && bwr && bstrobe);
    end
    // Provide for output of fixed test pattern for testing data link
    wire [3:0] testpatt;
    breg #(16'h0003,4) r0003(ibus, obus, testpatt);
    wire [15:0] do_testpatt;
    breg #(16'h0004) r0004(ibus, obus, do_testpatt);
    wire [7:0] diffmax;
    breg #(16'h0005,8) r0005(ibus, obus, diffmax);
    // Allow "bad idle" counts to be read out over bus
    wire [15:0] badidle_A1, badidle_A2, badidle_A3, badidle_A4;
    wire [15:0] badidle_B1, badidle_B2, badidle_B3, badidle_B4;
    bror #(16'h0010) r0010(ibus, obus, badidle_A1);
    bror #(16'h0011) r0011(ibus, obus, badidle_A2);
    bror #(16'h0012) r0012(ibus, obus, badidle_A3);
    bror #(16'h0013) r0013(ibus, obus, badidle_A4);
    bror #(16'h0014) r0014(ibus, obus, badidle_B1);
    bror #(16'h0015) r0015(ibus, obus, badidle_B2);
    bror #(16'h0016) r0016(ibus, obus, badidle_B3);
    bror #(16'h0017) r0017(ibus, obus, badidle_B4);
    // We'll create some sort of reset logic later
    reg rst = 0;
    // Signals needed for coincidence-forming
    wire sA1, sA2, sA3, sA4, sB1, sB2, sB3, sB4;
    wire pcA1, pcA2, pcA3, pcA4, pcB1, pcB2, pcB3, pcB4;
    wire ncA1, ncA2, ncA3, ncA4, ncB1, ncB2, ncB3, ncB4;
    wire [5:0] offsetA1, offsetB1;
    coinc coinc(.clk(clk), .rst(rst), 
                .singleA(sA1), .singleB(sB1),
                .offsetA(offsetA1), .offsetB(offsetB1),
                .pcoincA(pcA1), .ncoincA(ncA1), 
                .pcoincB(pcB1), .ncoincB(ncB1));
    assign {pcA2, pcA3, pcA4, ncA2, ncA3, ncA4} = 6'b0;  // skip 2,3,4 for now
    assign {pcB2, pcB3, pcB4, ncB2, ncB3, ncB4} = 6'b0;
    // Instantiate a module to process each of the eight cables; this
    // is somewhat simplified for now
    cable A1 (.clk(clk), .rst(rst), .in(A1in), .out(A1out),
              .badidle(badidle_A1),
              .testpatt(testpatt), .do_testp(do_testpatt[0]),
              .spword(spword), .do_spw(do_spword),
              .single(sA1), .offset(offsetA1),
              .pcoinc(pcA1), .ncoinc(ncA1));
    cable A2 (.clk(clk), .rst(rst), .in(A2in), .out(A2out),
              .testpatt(testpatt), .do_testp(do_testpatt[1]),
              .badidle(badidle_A2),
              .spword(spword), .do_spw(do_spword),
              .single(sA2), .pcoinc(pcA2), .ncoinc(ncA2));
    cable A3 (.clk(clk), .rst(rst), .in(A3in), .out(A3out),
              .badidle(badidle_A3),
              .testpatt(testpatt), .do_testp(do_testpatt[2]),
              .spword(spword), .do_spw(do_spword),
              .single(sA3), .pcoinc(pcA3), .ncoinc(ncA3));
    cable A4 (.clk(clk), .rst(rst), .in(A4in), .out(A4out),
              .badidle(badidle_A4),
              .testpatt(testpatt), .do_testp(do_testpatt[3]),
              .spword(spword), .do_spw(do_spword),
              .single(sA4), .pcoinc(pcA4), .ncoinc(ncA4));
    cable B1 (.clk(clk), .rst(rst), .in(B1in), .out(B1out),
              .badidle(badidle_B1),
              .testpatt(testpatt), .do_testp(do_testpatt[4]),
              .spword(spword), .do_spw(do_spword),
              .single(sB1), .offset(offsetB1),
              .pcoinc(pcB1), .ncoinc(ncB1));
    cable B2 (.clk(clk), .rst(rst), .in(B2in), .out(B2out),
              .badidle(badidle_B2),
              .testpatt(testpatt), .do_testp(do_testpatt[5]),
              .spword(spword), .do_spw(do_spword),
              .single(sB2), .pcoinc(pcB2), .ncoinc(ncB2));
    cable B3 (.clk(clk), .rst(rst), .in(B3in), .out(B3out),
              .badidle(badidle_B3),
              .testpatt(testpatt), .do_testp(do_testpatt[6]),
              .spword(spword), .do_spw(do_spword),
              .single(sB3), .pcoinc(pcB3), .ncoinc(ncB3));
    cable B4 (.clk(clk), .rst(rst), .in(B4in), .out(B4out),
              .badidle(badidle_B4),
              .testpatt(testpatt), .do_testp(do_testpatt[7]),
              .spword(spword), .do_spw(do_spword),
              .single(sB4), .pcoinc(pcB4), .ncoinc(ncB4));
endmodule  // mcu_logic

/*
 * Module to form coincidences between cable A and cable B.  The
 * quiescent state for each cable is that 'single' is LOW, so 'pcoinc'
 * and 'ncoinc' are both LOW in response.  If 'singleA' goes HIGH for
 * one clock cycle, then N clocks later, either 'pcoincA' or 'ncoincA'
 * will go HIGH in response.  If a match is found on 'singleB' (either
 * in time or offset +1 or -1 clock), then the answer is 'pcoinc'.
 * Otherwise, the answer is 'ncoinc'.  And vice-versa for B.
 */

module coinc
  (
   input  wire       clk,      // 100 MHz clock
   input  wire       rst,      // synchronous reset
   input  wire       singleA,  // single trigger from A side
   input  wire       singleB,  // single trigger from B side
   input  wire [5:0] offsetA,  // trig A offset w.r.t. clk edge
   input  wire [5:0] offsetB,  // trig B offset w.t.t. clk edge
   input  wire [7:0] diffmax,  // largest allowed absolute time difference
   output reg        pcoincA,  // accept (prompt) to A, with proper latency
   output reg        ncoincA,  // reject to A side, with proper latency
   output reg        pcoincB,  // accept (prompt) to B, with proper latency
   output reg        ncoincB   // reject to B side, with proper latency
   );
    // Initialize registered outputs to avoid 'X' values in simulation at t=0
    initial begin
        {pcoincA, ncoincA, pcoincB, ncoincB} <= 4'b0;
    end
    reg [2:0] srA = 0;  // shift register for 3 successive clock cycles ..
    reg [2:0] srB = 0;  // .. of singleA or singleB data
    reg [5:0] ofsAdel0 = 0, ofsAdel1 = 0, ofsAdel2 = 0;
    reg [5:0] ofsBdel0 = 0, ofsBdel1 = 0, ofsBdel2 = 0;
    // Create sign-extended copies of the inputs to the subtraction
    wire [7:0] oAd1 = {ofsAdel1[5], ofsAdel1[5], ofsAdel1[5:0]};
    wire [7:0] oBd0 = {ofsBdel0[5], ofsBdel0[5], ofsBdel0[5:0]};
    wire [7:0] oBd1 = {ofsBdel1[5], ofsBdel1[5], ofsBdel1[5:0]};
    wire [7:0] oBd2 = {ofsBdel2[5], ofsBdel2[5], ofsBdel2[5:0]};
    // Calculated difference for match on same clock cycle
    wire [7:0] diff1 = oBd1 - oAd1;
    wire [7:0] absdiff1 = diff1[7] ? -diff1 : diff1;
    // Calculated diff for match when B one cycle later than A
    wire [7:0] diff0 = (oBd0 + 8'd32) - oAd1;
    wire [7:0] absdiff0 = diff0[7] ? -diff0 : diff0;
    // Calculated diff for match when B one cycle earlier than A
    wire [7:0] diff2 = (oBd2 - 8'd32) - oAd1;
    wire [7:0] absdiff2 = diff2[7] ? -diff2 : diff2;
    reg [7:0] coincdiff = 0;  // temporary: record difference for coinc
    always @ (posedge clk) begin
        srA[2:0] <= {srA[1:0], singleA};  // implement shift register
        srB[2:0] <= {srB[1:0], singleB};
        ofsAdel2 <= ofsAdel1;  // create delayed copies of offsetA
        ofsAdel1 <= ofsAdel0;
        ofsAdel0 <= offsetA;
        ofsBdel2 <= ofsBdel1;  // create delayed copies of offsetB
        ofsBdel1 <= ofsBdel0;
        ofsBdel0 <= offsetB;
        if (srA[1]) begin
            // response is needed (with proper latency) for singleA
            if (srB == 3'b000) begin
                // No matching "B" event is seen for -1,0,+1 clock cycles
                pcoincA <= 1'b0;
                ncoincA <= 1'b1;
                coincdiff <= 8'b0;
            end else if (srB[1] && absdiff1 <= diffmax) begin
                // match for same clock cycle
                // matching "B" event is seen (within allowed window)
                pcoincA <= 1'b1;
                ncoincA <= 1'b0;
                coincdiff <= absdiff1;
            end else if (srB[0] && absdiff0 <= diffmax) begin
                // B is one cycle later than A
                // matching "B" event is seen (within allowed window)
                pcoincA <= 1'b1;
                ncoincA <= 1'b0;
                coincdiff <= absdiff0;
            end else if (srB[2] && absdiff2 <= diffmax) begin  
                // B is one cycle earlier than A
                // matching "B" event is seen (within allowed window)
                pcoincA <= 1'b1;
                ncoincA <= 1'b0;
                coincdiff <= absdiff2;
            end else begin
                // This can happen if a coincidence would be found by
                // the presence of srB inputs, but the time offsets
                // are larger than diffmax.
                pcoincA <= 1'b0;
                ncoincA <= 1'b1;
                coincdiff <= 8'b0;
            end
        end else begin
            // no singleA => neither accept nor reject is issued to A
            pcoincA <= 1'b0;
            ncoincA <= 1'b0;
        end
        if (srB[1]) begin
            // response is needed (with proper latency) for singleB
            if (srA == 3'b000) begin
                // No matching "A" event is seen for -1,0,+1 clock cycles
                pcoincB <= 1'b0;
                ncoincB <= 1'b1;
            end else begin
                // matching "A" event is seen (within allowed window)
                pcoincB <= 1'b1;
                ncoincB <= 1'b0;
            end
        end else begin
            // no singleB => neither accept nor reject is issued to B
            pcoincB <= 1'b0;
            ncoincB <= 1'b0;
        end
    end
endmodule

/*
 * Module containing logic to process a given ROCSTAR <-> MCU cable.
 * The inputs/outputs will become more complicated once we start
 * trying to detect coincidences.
 */
module cable
  (
   input  wire        clk,       // 100 MHz clock
   input  wire        rst,       // synchronous reset
   input  wire [7:0]  in,        // 8-bit input data (from ROCSTAR)
   output reg  [3:0]  out,       // 4-bit output data (to ROCSTAR)
   output reg [15:0]  badidle,   // count IDLE words with unexpected contents
   input  wire [3:0]  testpatt,  // fixed 4-bit 'out' for testing data link
   input  wire        do_testp,  // enable fixed 'testpatt' output
   input  wire [15:0] spword,    // "special" command word to transmit
   input  wire        do_spw,    // pulse: emit a special word now
   output reg         single,    // single photon detected for this cable
   output reg  [5:0]  offset,    // single trig offset w.r.t. clk edge
   input  wire        pcoinc,    // prompt coincidence confirmed for cable
   input  wire        ncoinc     // no coincidence found for this cable
   );
    // Initialize registered outputs to avoid 'X' values in simulation at t=0
    initial begin
        out <= 4'b0000;
        badidle <= 16'b0;
        single <= 1'b0;
        offset <= 6'b0;
    end
    // Observe incoming data words and report single-photon triggers
    localparam I_TRIGMASK = 8'b10000000;
    localparam I_IDLEMASK = 8'b11001100;
    localparam I_IDLE0 = 8'b01000000;
    localparam I_IDLE1 = 8'b01000100;
    localparam I_IDLE2 = 8'b01001000;
    localparam I_IDLE3 = 8'b01001100;
    reg badidle_inc = 0;
    reg [7:0] inprev = 0;  // keep track of previous input word
    reg [15:0] idlecnt = 0, new_idlecnt = 0;
    always @ (posedge clk) begin
        // For the moment, this "single" signal will simply indicate
        // the presence of a single-photon trigger from this cable
        // during the corresponding clock cycle.  The result will be a
        // very coarse coincidence window: any overlap that matches
        // with -1,0,+1 clock cycles will qualify.  Once we get that
        // working to form coincidences between 2 rocstar boards, we
        // will make use of bits 6..0 ("time offset w.r.t. clock") to
        // form a less coarse concidence window (probably something
        // like +/- a few ns).
        if ((in & I_TRIGMASK) != 8'b0) begin
            // We got a single trigger
            single <= 1'b1;
            offset <= in[6:1];
        end else begin
            // We did not get a single trigger
            single <= 1'b0;
            offset <= 6'b0;
        end
        badidle_inc <= 1'b0;  // if 1, increment count of out-of-order idles
        if ((in & I_TRIGMASK) == 8'b0) begin
            if ((in & I_IDLEMASK) == I_IDLE0) begin
                new_idlecnt[3:2] <= in[5:4];
                new_idlecnt[1:0] <= in[1:0];
                if ((inprev & I_TRIGMASK) == 8'b0 &&
                    (inprev & I_IDLEMASK) != I_IDLE3)
                  badidle_inc <= 1'b1;
            end else if ((in & I_IDLEMASK) == I_IDLE1) begin
                new_idlecnt[7:6] <= in[5:4];
                new_idlecnt[5:4] <= in[1:0];
                if ((inprev & I_IDLEMASK) != I_IDLE0) 
                  badidle_inc <= 1'b1;
            end else if ((in & I_IDLEMASK) == I_IDLE2) begin
                new_idlecnt[11:10] <= in[5:4];
                new_idlecnt[9:8]   <= in[1:0];
                if ((inprev & I_IDLEMASK) != I_IDLE1) 
                  badidle_inc <= 1'b1;
            end else if ((in & I_IDLEMASK) == I_IDLE3) begin
                new_idlecnt[15:14] <= in[5:4];
                new_idlecnt[13:12] <= in[1:0];
                if ((inprev & I_IDLEMASK) != I_IDLE2) 
                  badidle_inc <= 1'b1;
            end else begin
                badidle_inc <= 1'b1;
            end
        end
        if ((inprev & I_IDLEMASK) == I_IDLE3) begin
            // The transmitted pattern should increment each time the
            // IDLE3 symbol is sent.
            if (new_idlecnt != ((idlecnt + 1'b1) & 16'hffff))
              badidle_inc <= 1'b1;
            idlecnt <= new_idlecnt;
        end
        if (badidle_inc) badidle <= badidle + 1'b1;
        inprev <= in;
    end
    // Mnemonic names for values written to cable (move to include file)
    localparam K_IDLE0 = 4'b0111;  // cycle through 4 IDLE words
    localparam K_IDLE1 = 4'b1011;
    localparam K_IDLE2 = 4'b1101;
    localparam K_IDLE3 = 4'b1110;
    localparam K_NCOIN = 4'b1001;  // no coincidence
    localparam K_PCOIN = 4'b0011;  // prompt coincidence
    localparam K_DCOIN = 4'b0110;  // delayed coincidence
    localparam K_SPECL = 4'b1100;  // begin "special word" sequence
    // Mnemonic names for Finite State Machine states
    localparam 
      START=0, IDLE1=1, IDLE2=2, IDLE3=3, NCOIN=4, PCOIN=5, SPECL=6, SPEC1=7,
      SPEC2=8, SPEC3=9, SPEC4=10;
    reg [3:0] fsm = START;  // flip-flop
    reg [3:0] fsm_prev = START;  // flip-flop: keep track of previous state
    reg [3:0] fsm_d = START;  // combinational logic
    reg [3:0] out_d;  // combinational logic
    reg [31:0] ticks = 0;  // useful to display time in units of 'clk'
    always @ (posedge clk) begin
        // Update 'fsm' FF from 'fsm_d' next-state value, except on reset
        if (rst) begin
            fsm <= START;
        end else begin
            fsm <= fsm_d;
        end
        // Update 'out' FF from 'out_d' next value
        if (do_testp) begin
            // Allows testing data link with fixed output pattern
            out <= testpatt;
        end else begin
            out <= out_d;
        end
        // Previous state on next clock is what 'fsm' is now
        fsm_prev <= fsm;
        // Increment 'ticks' counter
        ticks <= ticks + 1'd1;
    end
    // This COMBINATIONAL always block contains the next-state logic
    // and other state-dependent combinational logic.
    always @ (*) begin
        // Assign default values to avoid risk of implicit latches
        fsm_d = START;
        out_d = 4'b0000;
        if (0) $strobe("fsm_d=%1d fsm=%1d fsm_prev=%1d @%1d",
                       fsm_d, fsm, fsm_prev, ticks);
        case (fsm)
            START:
              begin
                  out_d = K_IDLE0;
                  fsm_d = IDLE1;
                  if (ncoinc) fsm_d = NCOIN;
                  if (pcoinc) fsm_d = PCOIN;
                  if (do_spw) fsm_d = SPECL;
              end
            IDLE1:
              begin
                  out_d = K_IDLE1;
                  fsm_d = IDLE2;
                  if (ncoinc) fsm_d = NCOIN;
                  if (pcoinc) fsm_d = PCOIN;
                  if (do_spw) fsm_d = SPECL;
              end
            IDLE2:
              begin
                  out_d = K_IDLE2;
                  fsm_d = IDLE3;
                  if (ncoinc) fsm_d = NCOIN;
                  if (pcoinc) fsm_d = PCOIN;
                  if (do_spw) fsm_d = SPECL;
              end
            IDLE3:
              begin
                  out_d = K_IDLE3;
                  fsm_d = START;
                  if (ncoinc) fsm_d = NCOIN;
                  if (pcoinc) fsm_d = PCOIN;
                  if (do_spw) fsm_d = SPECL;
              end
            NCOIN:
              begin
                  out_d = K_NCOIN;
                  fsm_d = START;
                  if (do_spw) fsm_d = SPECL;
              end
            PCOIN:
              begin
                  out_d = K_PCOIN;
                  fsm_d = START;
                  if (do_spw) fsm_d = SPECL;
              end
            SPECL:
              begin
                  out_d = K_SPECL;
                  fsm_d = SPEC1;
              end
            SPEC1:
              begin
                  out_d = spword[15:12];
                  fsm_d = SPEC2;
              end
            SPEC2:
              begin
                  out_d = spword[11:8];
                  fsm_d = SPEC3;
              end
            SPEC3:
              begin
                  out_d = spword[7:4];
                  fsm_d = SPEC4;
              end
            SPEC4:
              begin
                  out_d = spword[3:0];
                  fsm_d = START;
                  if (ncoinc) fsm_d = NCOIN;
                  if (pcoinc) fsm_d = PCOIN;
                  if (do_spw) fsm_d = SPECL;
              end
            default:
              begin
                  $strobe("INVALID STATE: fsm=%d fsm_prev=%d @%1d", 
                          fsm, fsm_prev, ticks);
                  fsm_d = START;
              end
        endcase
    end
endmodule  // cable

/*
 * A read-only register that lives on the register file "bus" at 16-bit
 * address 'MYADDR' with data width 'W' (W <= 16).
 */
module bror #( parameter MYADDR=0, W=16 ) 
  (
   input  wire [1+1+16+16-1:0] i,  // bus inputs, combined for concision
   output wire [15:0]          o,  // bus output, abbreviated for concision
   input  wire [W-1:0]         d   // data to place on bus at this address
   );
    wire        clk, wr;
    wire [15:0] addr, wrdata;
    wire [15:0] rddata;
    assign {clk, wr, addr, wrdata} = i;  // pick apart contents of 'i'
    assign o = {rddata};
    // The real work happens below
    wire addrok = (addr==MYADDR);  // Does requested addr match my address?
    // If address matches, put 'd' onto 'rddata' bus; else "high impedance".  
    // See "Three-state logic" in wikipedia, e.g.
    assign rddata = addrok ? d : 16'bz;
endmodule  // bror

/*
 * A read-write register that lives on the register file "bus" at 16-bit
 * address 'MYADDR' with data width 'W' (W <= 16), and power-up value 'PU'.
 */
module breg #( parameter MYADDR=0, W=16, PU=0 ) 
  (
   input  wire [1+1+16+16-1:0] i,  // bus inputs, combined for concision
   output wire [15:0]          o,  // bus output, abbreviated for concision
   output wire [W-1:0]         q   // copy of internal register value
   );
    wire        clk, wr;
    wire [15:0] addr, wrdata;
    wire [15:0] rddata;
    assign {clk, wr, addr, wrdata} = i;  // pick apart contents of 'i'
    assign o = {rddata};
    // The real work happens below
    reg [W-1:0] regdat = PU;  // Define register with power-up value 'PU'
    wire addrok = (addr==MYADDR);  // Does requested addr match my address?
    // If address matches, put current contents of 'reg' onto 'rddata' bus;
    // else "high impedance," i.e. this instance leaves 'rddata' undisturbed
    // unless the address matches.
    assign rddata = addrok ? regdat : 16'bz;
    // If address matches and a write cycle is requested, then update the
    // contents of register 'regdat' from the 'wrdata' contents of the bus.
    always @ (posedge clk)
      if (wr && addrok)
        regdat <= wrdata[W-1:0];
    // Let the outside world see the current contents of 'regdat'
    assign q = regdat;
endmodule  // breg

`default_nettype wire
