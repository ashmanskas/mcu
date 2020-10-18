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
//  File:     one_wire_io.v                                               --
//  Date:     February 1, 2005                                            --
//  Version:  v2.100                                                      --
//  Authors:  Rick Downs and Charles Hill,                                --
//            Dallas Semiconductor Corporation                            --
//                                                                        --
//  Note:     This source code is available for use without license.      --
//            Dallas Semiconductor is not responsible for the             --
//            functionality or utility of this product.                   --
//                                                                        --
//  Rev:      Significant changes to improve synthesis - English          --
//            Ported to Verilog - Sandelin                                --
//--------------------------------------------------------------------------

module one_wire_io (
  CLK, DDIR, DOUT, DQ_CONTROL, MR, DIN, DQ_IN, DATA, DQ);

  input        CLK;
  input        DDIR;
  input [7:0]  DOUT;
  input        DQ_CONTROL;
  input        MR;

  output [7:0] DIN;
  output       DQ_IN;
   
  inout [7:0]  DATA;
  inout        DQ;
   
  reg         DQ_IN;  
  
  assign DATA = DDIR?DOUT:8'hzz;
  assign DIN=DATA;
  assign DQ =DQ_CONTROL==1?1'bz:1'b0;
  
  //
  // Synchronize DQ_IN
  //
  always @(posedge MR or negedge CLK)
    if (MR)
      DQ_IN <= 1'b1;
    else
      DQ_IN <= DQ;
endmodule // one_wire_io