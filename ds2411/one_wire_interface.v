//--------------------------------------------------------------------------
//                                                                        --
//  OneWireMaster                                                         --
//   A synthesizable 1-wire master peripheral                             --
//   Copyright 1999-2005 Dallas Semiconductor Corporation                 --
//                                                                        --
//--------------------------------------------------------------------------
//                                                                        --
//  Purpose:  Provides timing and control of Dallas 1-wire bus            --
//            through a memory-mapped peripheral                          --
//  File:     one_wire_interface.v                                        --
//  Date:     February 1, 2005                                            --
//  Version:  v2.100                                                      --
//  Authors:  Rick Downs and Charles Hill,                                --
//            Dallas Semiconductor Corporation                            --
//                                                                        --
//  Note:     This source code is available for use without license.      --
//            Dallas Semiconductor is not responsible for the             --
//            functionality or utility of this product.                   --
//                                                                        --
//  REV:      Added BIT_CTL to COMMAND reg - GAG                          --
//            Added STPEN to COMMAND reg - GAG                            --
//            Combined CLK_DIV register bits into one block - GAG         --
//            Added CLK_EN to CLK_DIV reg - GAG                           --
//            Added CONTROL reg and moved appropriate bits into it - GAG  --
//            Added EN_FOW and changed dqz to FOW - GAG                   --
//            Added STP_SPLY - GAG                                        --
//            Significant changes to improve synthesis - English          --
//            Ported to Verilog - Sandelin                                --
//--------------------------------------------------------------------------

module one_wire_interface (
   ADDRESS, ADS_bar, clear_interrupts, DIN, DQ_IN, EN_bar, FSM_CLK, MR,
   OneWireIO_eq_Load, pdr, OW_LOW, OW_SHORT, rbf,
   rcvr_buffer, RD_bar, reset_owr, rsrf, temt, WR_bar, BIT_CTL,
   CLK_EN, clr_activate_intr, DDIR, div_1, div_2, div_3, DOUT, EN_FOW, EOWL,
   EOWSH, epd, erbf, ersf, etbe, etmt, FOW, ias,
   LLM, OD, owr, pd, PPM, pre_0, pre_1, rbf_reset, sr_a, STP_SPLY, STPEN, tbe,
   xmit_buffer);

   input [2:0]  ADDRESS;
   input        ADS_bar;
   input        clear_interrupts;
   input [7:0]  DIN;
   input        DQ_IN;
   input        EN_bar;
   input        FSM_CLK;
   input        MR;
   input        OneWireIO_eq_Load;
   input        pdr;
   input        OW_LOW;          // ow bus low interrupt
   input        OW_SHORT;        // ow bus shorted interrupt
   input        rbf;             // receive buffer full int
   input [7:0]  rcvr_buffer;
   input        RD_bar;
   input        reset_owr;
   input        rsrf;            // receive shift reg full int
   input        temt;
   input        WR_bar;

   output       BIT_CTL;         // enable signle bit outputs
   output       CLK_EN;          // clock divider enable
   output       clr_activate_intr;
   output       DDIR;
   output       div_1;           // divider select bit 1
   output       div_2;           // divider select bit 2
   output       div_3;           // divider select bit 3
   output [7:0] DOUT;
   output       EN_FOW;          // enable force OW functionality
   output       EOWL;            // enable one wire bus low interrupt
   output       EOWSH;           // enable one wire short interrupt
   output       epd;             // enable presence detect interrupt
   output       erbf;            // enable receive buffer full interrupt
   output       ersf;            // enable receive shift register full int.
   output       etbe;            // enable transmit buffer empty interrupt
   output       etmt;            // enable transmit shift outputister empty int.
   output       FOW;             // force OW value to opposite value
   output       ias;             // INTR active state
   output       LLM;             // long line mode enable
   output       OD;              // enable overdrive
   output       owr;
   output       pd;
   output       PPM;             // presence pulse masking enable
   output       pre_0;           // prescaler select bit 0
   output       pre_1;           // prescaler select bit 1
   output       rbf_reset;       // clear signal for rbf
   output       sr_a;
   output       STP_SPLY;        // enable strong pull up supply mode
   output       STPEN;           // enable strong pull up output
   output       tbe;
   output [7:0] xmit_buffer;


   wire         read_op;
   wire         write_op;
   reg [2:0]    sel_addr;         // selected register address

   // command register
   reg       sr_a;                // search ROM accelerator command
   reg       owr;                 // 1W reset command
   reg       FOW;                 // Force OW value
   wire [7:0] CMD_REG = {4'b0, DQ_IN, FOW, sr_a, owr};

   reg       set_activate_intr;
   reg       clr_activate_intr;
   reg  xmit_buffer_full;

   reg [7:0] xmit_buffer;         // transmit buffer

   // Control register
   reg       OD;                  // enable overdrive
   reg       BIT_CTL;             // enable single bit transmitions
   reg       STP_SPLY;            // Strong Pullup supply mode enable
   reg       STPEN;               // enable strong pull up output
   reg       EN_FOW;              // enable force OW functionality
   reg       PPM;                 // Presence Pulse masking enable
   reg       LLM;                 // Long Line mode enable (stretch timing)
   wire [7:0] CONTRL_REG = {1'b0, OD, BIT_CTL, STP_SPLY, STPEN, EN_FOW,
             PPM, LLM};

   // interrupt register
   wire      OW_LOW;              // OW low interrupt
   wire      OW_SHORT;            // OW shorted interrupt
   reg       pd;                  // presence detect done flag
   wire      pdr;                 // presence detect result
   reg       tbe;                 // transmit buffer empty flag
   wire      rbf;                 // receive buffer full flag
   wire [7:0] INT_REG = {OW_LOW, OW_SHORT, rsrf, rbf, temt, tbe, pdr, pd};

   // interrupt enable register
   reg       EOWL;                // enable OW low interrupt
   reg       EOWSH;               // enable OW shorted interrupt
   reg       epd;                 // enable presence detect interrupt
   reg       ias;                 // INTR active state
   reg       etbe;                // enable transmit buffer empty interrupt
   reg       etmt;                // enable transmit shift register empty int.
   reg       erbf;                // enable receive buffer full interrupt
   reg       ersf;                // enable receive shift register full int.
   wire [7:0] INTEN_REG = {EOWL, EOWSH, ersf, erbf, etmt, etbe, ias, epd};

   // clock divisor register
   reg       pre_0;               // prescaler select bit 0
   reg       pre_1;               // prescaler select bit 1
   reg       div_1;               // divider select bit 1
   reg       div_2;               // divider select bit 2
   reg       div_3;               // divider select bit 3
   reg       CLK_EN;              // clock divider enable
   wire [7:0] CLKDV_REG = {CLK_EN, 2'b0, div_3, div_2, div_1, pre_1, pre_0};



  //--------------------------------------------------------------------------
  //  read/write process
  //--------------------------------------------------------------------------

  assign read_op = ~EN_bar && ~MR && ~RD_bar && WR_bar;
  wire      read_op_n=~read_op;

  assign write_op = ~EN_bar && ~MR && ~WR_bar && RD_bar;
  wire      write_op_n = ~write_op;

  always @(posedge MR or posedge WR_bar)
    if(MR)            // removed reset interrupt reg when chip not enabled
      begin
        EOWL = 1'b0;
        EOWSH = 1'b0;
        ersf = 1'b0;
        erbf = 1'b0;
        etmt = 1'b0;
        etbe = 1'b0;
        ias = 1'b0;
        epd = 1'b0;
        xmit_buffer=0;
      end
    else
      if(!EN_bar && RD_bar)
        case(sel_addr)
          3'b001:
            xmit_buffer = DIN;
          3'b011:             //removed ias to hard wire active low - GAG
                              //added ias to remove hardwire - SKH
            begin
              EOWL = DIN[7];
              EOWSH = DIN[6];
              ersf = DIN[5];
              erbf = DIN[4];
              etmt = DIN[3];
              etbe = DIN[2];
              ias = DIN[1];
              epd = DIN[0];
            end
        endcase

  assign DDIR =  read_op;

  //
  // Modified DOUT to always drive the current register value out
  // based on the address value
  //
  assign DOUT =
  (sel_addr == 3'b000)?{4'b0000,DQ_IN,FOW,sr_a,owr}:
  (sel_addr == 3'b001)?rcvr_buffer:
  (sel_addr == 3'b010)?{OW_LOW,OW_SHORT,rsrf,rbf,temt,tbe,pdr,pd}:
  (sel_addr == 3'b011)?{EOWL,EOWSH,ersf,erbf,etmt,etbe,ias,epd}:
  (sel_addr == 3'b100)?{CLK_EN,2'b00,div_3,div_2,div_1,pre_1,pre_0}:
  (sel_addr == 3'b101)?{1'b0,OD,BIT_CTL,STP_SPLY,STPEN,EN_FOW,PPM,LLM}:
  8'h00;


  //
  // Clock divisor register
  //
  // synopsys async_set_reset MR
  always @(posedge MR or posedge WR_bar)
    if(MR)
      begin
        pre_0 = 1'b0;
        pre_1 = 1'b0;
        div_1 = 1'b0;
        div_2 = 1'b0;
        div_3 = 1'b0;
        CLK_EN = 1'b0;
      end
    else
    if(!EN_bar && RD_bar)
      if(sel_addr == 3'b100)
        begin
          pre_0 = DIN[0];
          pre_1 = DIN[1];
          div_1 = DIN[2];
          div_2 = DIN[3];
          div_3 = DIN[4];
          CLK_EN = DIN[7];
        end


  wire CLR_OWR = MR || reset_owr;

  //
  // Command reg writes are handled in the next two sections
  // Bit 0 needs to be separate for the added clearing mechanism
  //
  always @(posedge CLR_OWR or posedge WR_bar)
    if(CLR_OWR)
      begin
        owr <= 1'b0;
      end
    else
      begin
        if(EN_bar == 0 && RD_bar == 1)
          if(sel_addr == 3'b000)
            owr <= DIN[0];
      end
  //
  // Bits 1-7's write routine
  //
  always @(posedge MR or posedge WR_bar)
    if(MR)
      begin
        FOW     <= 1'b0;
        sr_a    <= 1'b0;
      end
    else
      begin
        if(EN_bar == 0 && RD_bar == 1)
          if(sel_addr == 3'b000)
            begin
              sr_a    <= DIN[1];
              FOW     <= DIN[2];
            end
      end

  //
  // The Control reg writes are handled here
  //
  always @(posedge MR or posedge WR_bar)
    if(MR)
      begin
        OD      <= 1'b0;
        BIT_CTL <= 1'b0;
        STP_SPLY<= 1'b0;
        STPEN   <= 1'b0;
        EN_FOW  <= 1'b0;
        PPM     <= 1'b0;
        LLM     <= 1'b0;
      end
    else
      begin
        if(EN_bar == 0 && RD_bar == 1)
          if(sel_addr == 3'b101)
            begin
              OD      <= DIN[6];
              BIT_CTL <= DIN[5];
              STP_SPLY<= DIN[4];
              STPEN   <= DIN[3];
              EN_FOW  <= DIN[2];
              PPM     <= DIN[1];
              LLM     <= DIN[0];
            end
      end


  //--------------------------------------------------------------------------
  //  Transparent address latch
  //--------------------------------------------------------------------------

  always @(ADS_bar or ADDRESS or EN_bar)
    if(!ADS_bar && !EN_bar)
      sel_addr = ADDRESS;

  //--------------------------------------------------------------------------
  // Interrupt flag register clearing (What is not handled in onewiremaster.v)
  //--------------------------------------------------------------------------

  wire acint_reset = MR || (clear_interrupts); // synchronized
                                               // set_activate_intr - SDS

  always @(posedge acint_reset or posedge RD_bar)
    if(acint_reset)
      clr_activate_intr <= 1'b0;
    else
      if(EN_bar == 0 && WR_bar == 1)
        if(sel_addr == 3'b010)
          clr_activate_intr <= 1'b1;

  wire rbf_reset = (read_op && (sel_addr == 3'b001));

  always @(posedge MR or posedge FSM_CLK)
    if (MR)
      pd <= 1'b0;
    else if (reset_owr)
      pd <= 1'b1;
    else if (clr_activate_intr)  // This causes pd to wait for a clk to clear
      pd <= 1'b0;
    else
      pd <= pd;

  //
  // The following two blocks handle tbe
  // The lower is the psuedo asynch portion which is synched up
  //  in the upper section.
  //
  always @(posedge FSM_CLK or posedge MR)
    if (MR)
      tbe <= 1'b1;
    else
      tbe <= ~xmit_buffer_full;

  always @(posedge MR or posedge WR_bar or posedge OneWireIO_eq_Load)
    if(MR)
      xmit_buffer_full <= 1'b0;
    else if (OneWireIO_eq_Load)
      xmit_buffer_full <= 1'b0;
    else
      if(EN_bar == 0 && RD_bar == 1)
        if(sel_addr == 3'b001)
          xmit_buffer_full <= 1'b1;

endmodule // one_wire_interface

