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
//  File:     OWM.v                                                       --
//  Date:     February 1, 2005                                            --
//  Version:  v2.100                                                      --
//  Authors:  Rick Downs and Charles Hill,                                --
//            Dallas Semiconductor Corporation                            --
//                                                                        --
//  Note:     This source code is available for use without license.      --
//            Dallas Semiconductor is not responsible for the             --
//            functionality or utility of this product.                   --
//                                                                        --
//  Rev:      Added Overdrive, Bit control, and strong pullup control     --
//            along with many other features described in the new spec    --
//            released version 2.0  9/5/01 - Greg Glennon                 --
//            Significant changes to improve synthesis - English          --
//            Ported to Verilog - Sandelin                                --
//--------------------------------------------------------------------------

module ds1wm (
  ADDRESS, ADS_bar, CLK, EN_bar, MR, RD_bar, WR_bar, /*DDIR, DOUT,*/ INTR,
  STPZ, DATA, DQ);

  input  [2:0] ADDRESS;  // SFR address
  input  ADS_bar;        // address latch control (active low)
  input  CLK;            // system clock
  input  EN_bar;         // SFR access enable (active low)
  input  MR;             // master reset
  input  RD_bar;         // SFR read (active low)
  input  WR_bar;         // SFR write (active low)

  //output DDIR;
  //output [7:0] DOUT;
  output INTR;           // one wire master interrupt
  output STPZ;           // strong pullup (active low)

  inout  [7:0] DATA;     // bidirectional DATA bus
  inout  DQ;             // OW pin

  wire  [7:0] DIN;
  wire  [7:0] DOUT;
  wire  [7:0] rcvr_buffer;
  wire  [7:0] xmit_buffer;
  wire  [2:0] ADDRESS;

    wire DDIR;
    wire DQ_CONTROL;
    wire CLK_EN;
    wire DQ_IN, LLM, OD, PPM, STP_SPLY, STPEN;
    wire div_1, div_2, div_3, ias, owr, pd, tbe;
    wire pre_0, pre_1, epd, erbf, ersf, etbe, etmt;
    wire clk_1us, clear_interrupts, rbf_reset;
    wire FSM_CLK, OneWireIO_eq_Load;
    wire pdr, rbf, reset_owr, rsrf, temt, sr_a;
    wire OW_LOW, OW_SHORT, BIT_CTL, EN_FOW, EOWL, EOWSH, FOW;
    wire clr_activate_intr, one_wire_interface;

  one_wire_io xone_wire_io(
    CLK, DDIR, DOUT, DQ_CONTROL, MR, DIN, DQ_IN, DATA, DQ);

  clk_prescaler xclk_prescaler(
    CLK, CLK_EN, div_1, div_2, div_3, MR, pre_0, pre_1, clk_1us);

  one_wire_interface xone_wire_interface(
    ADDRESS, ADS_bar, clear_interrupts, DIN, DQ_IN, EN_bar, FSM_CLK, MR,
    OneWireIO_eq_Load, pdr, OW_LOW, OW_SHORT, rbf, rcvr_buffer, RD_bar,
    reset_owr, rsrf, temt, WR_bar, BIT_CTL, CLK_EN, clr_activate_intr, DDIR,
    div_1, div_2, div_3, DOUT, EN_FOW, EOWL, EOWSH, epd, erbf, ersf,
    etbe, etmt, FOW, ias, LLM, OD, owr, pd, PPM, pre_0, pre_1, rbf_reset,
    sr_a, STP_SPLY, STPEN, tbe, xmit_buffer);

  onewiremaster xonewiremaster(
    BIT_CTL, clk_1us, clr_activate_intr, DQ_IN, EN_FOW, EOWL,
    EOWSH, epd, erbf, ersf, etbe, etmt, FOW, ias, LLM, MR, OD,
    owr, pd, PPM, rbf_reset, sr_a, STP_SPLY, STPEN, tbe, xmit_buffer,
    clear_interrupts, DQ_CONTROL, FSM_CLK, INTR, OneWireIO_eq_Load, OW_LOW,
    OW_SHORT, pdr, rbf, rcvr_buffer, reset_owr, rsrf, STPZ, temt);

endmodule
