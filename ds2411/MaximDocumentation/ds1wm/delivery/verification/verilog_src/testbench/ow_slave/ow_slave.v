////////////////////////////////////////////////////////////////////////////////
// Project:     ds1wm                                              
// Module:      ow_slave                                               
// Path:        testbench/ow_slave/ow_slave.v                      
// Designer:    Michael Haight
// Date:        05/29/01        
//
// Description: This is the structural model for the top-level
//              data logger chip.                                            
//////////////////////////////////////////////////////////////////////////////// 
module ow_slave (IO, ROMID);



///// Port Declarations ////////////////////////////////////////////////////////


inout   IO;                             // 1-Wire pin

output [63:0] ROMID;

///// General Declarations /////////////////////////////////////////////////////

wire clk_iox;
wire iox_rstz;
wire iox_wrdata;
wire iox_rddata;
wire iox_readz;
wire io_pd;
wire io_buf;


wire [63:0] ROMID;


///// IO pin /////

assign  io_buf = IO;
//assign        (pull0, pull1) IO = io_pd ? 1'b0 : 1'b1;
assign  (pull0, pull1) IO = io_pd ? 1'b0 : 1'bz;

////////////////////////////////////////////////////////////////////////////////




cmd_ctrl  xcmd_ctrl (
  .CLK_MEM(clk_iox), 
  .IOX_RSTZ(iox_rstz),
  .IOX_WRDATA(iox_wrdata),
  .END_1WIRE(),
  .IOX_CSR(iox_csr),
  .IOX_RDDATA(iox_rddata),
  .IOX_READZ(iox_readz)
);

 
IOX  xiox (
  .P_ROMID(ROMID),
  .CLK_IOX(clk_iox),
  .IO_PD(io_pd),
  .IOX_RSTZ(iox_rstz),
  .IOX_WRDATA(iox_wrdata),

  .IOX_CSR(iox_csr),
  .IOX_RDDATA(iox_rddata),
  .IOX_READZ(iox_readz),
  .IO_BUF(io_buf)
);
  

///////////////////////////////////////////////////////////////////////////////
endmodule
