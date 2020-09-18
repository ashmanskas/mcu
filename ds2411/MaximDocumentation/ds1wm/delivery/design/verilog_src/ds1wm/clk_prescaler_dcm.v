//--------------------------------------------------------------------------
//                                                                        --
//  OneWireMaster                                                         --
//   A synthesizable 1-wire master peripheral                             --
//   Copyright 2010 Maxim Integrated Products                             --
//                                                                        --
//--------------------------------------------------------------------------
//                                                                        --
//  Purpose:  Provides timing and control of Dallas 1-wire bus            --
//            through a memory-mapped peripheral                          --
//  File:     clk_prescaler_dcm.v                                         --
//  Date:     May 17, 2010                                                --
//  Version:  v1.000                                                      --
//  Authors:  Stewart Merkel                                              --
//            Maxim Integrated Products                                   --
//                                                                        --
//  Note:     This source code is available for use without license.      --
//            Maxim Integrated Products is not responsible for the        --
//            functionality or utility of this product.                   --
//                                                                        --
//  REV:      Removal of gated clocks created in clk_prescaler for        --
//            use with Xilinx FPGA - English                              --
//            "CHANGE DCM ATTRIBUTES FOR YOUR CLOCK"                      --
//--------------------------------------------------------------------------

module clk_prescaler( 
   CLK, CLK_EN, div_1, div_2, div_3, MR, pre_0, pre_1, clk_1us);
   
   input  CLK;
   input  CLK_EN;              // enables the divide chain
   input  div_1;               // divider select bit 1
   input  div_2;               // divider select bit 2
   input  div_3;               // divider select bit 3
   input  MR;
   input  pre_0;               // prescaler select bit 0
   input  pre_1;               // prescaler select bit 1

   output clk_1us;             // OD, STD mode fsm clock
   
   wire   CLK;
   wire   MR;
	wire	CLKFB;
	wire CLK_EN;
	wire	CLKDV;
   
	   // BUFGCE: Global Clock Buffer with Clock Enable (active high)
   //         Virtex-II/II-Pro/4/5, Spartan-3/3E/3A
   // Xilinx HDL Language Template, version 10.1.3

   BUFGCE BUFGCE_inst (
      .O(clk_1us),   // Clock buffer output
      .CE(CLK_EN), // Clock enable input
      .I(CLKDV)    // Clock buffer input
   );

   // End of BUFGCE_inst instantiation
	
	
	
	
   // DCM_SP: Digital Clock Manager Circuit
   //         Spartan-3E/3A
   // Xilinx HDL Language Template, version 10.1.3

   DCM_SP #(
      .CLKDV_DIVIDE(16.0), // Divide by: 1.5,2.0,2.5,3.0,3.5,4.0,4.5,5.0,5.5,6.0,6.5
                          //   7.0,7.5,8.0,9.0,10.0,11.0,12.0,13.0,14.0,15.0 or 16.0
      .CLKFX_DIVIDE(1),   // Can be any integer from 1 to 32
      .CLKFX_MULTIPLY(4), // Can be any integer from 2 to 32
      .CLKIN_DIVIDE_BY_2("FALSE"), // TRUE/FALSE to enable CLKIN divide by two feature
      .CLKIN_PERIOD(62.5),  // Specify period of input clock
      .CLKOUT_PHASE_SHIFT("NONE"), // Specify phase shift of NONE, FIXED or VARIABLE
      .CLK_FEEDBACK("1X"),  // Specify clock feedback of NONE, 1X or 2X
      .DESKEW_ADJUST("SYSTEM_SYNCHRONOUS"), // SOURCE_SYNCHRONOUS, SYSTEM_SYNCHRONOUS or
                                            //   an integer from 0 to 15
      .DLL_FREQUENCY_MODE("LOW"),  // HIGH or LOW frequency mode for DLL
      .DUTY_CYCLE_CORRECTION("TRUE"), // Duty cycle correction, TRUE or FALSE
      .PHASE_SHIFT(0),     // Amount of fixed phase shift from -255 to 255
      .STARTUP_WAIT("FALSE")   // Delay configuration DONE until DCM LOCK, TRUE/FALSE
   ) DCM_SP_inst (
      .CLK0(CLKFB),     // 0 degree DCM CLK output
      .CLK180(), // 180 degree DCM CLK output
      .CLK270(), // 270 degree DCM CLK output
      .CLK2X(),   // 2X DCM CLK output
      .CLK2X180(), // 2X, 180 degree DCM CLK out
      .CLK90(),   // 90 degree DCM CLK output
      .CLKDV(CLKDV),   // Divided DCM CLK out (CLKDV_DIVIDE)
      .CLKFX(),   // DCM CLK synthesis out (M/D)
      .CLKFX180(), // 180 degree CLK synthesis out
      .LOCKED(), // DCM LOCK status output
      .PSDONE(), // Dynamic phase adjust done output
      .STATUS(), // 8-bit DCM status bits output
      .CLKFB(CLKFB),   // DCM clock feedback
      .CLKIN(CLK),   // Clock input (from IBUFG, BUFG or DCM)
      .PSCLK(),   // Dynamic phase adjust clock input
      .PSEN(1'b0),     // Dynamic phase adjust enable input
      .PSINCDEC(), // Dynamic phase adjust increment/decrement
      .RST(MS)        // DCM asynchronous reset input
   );

   // End of DCM_SP_inst instantiation
	
endmodule // clk_prescaler
