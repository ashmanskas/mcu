////////////////////////////////////////////////////////////////////////////////
// Project:	ow_slave						      
// Module:      iox                                                
// Path:	/custom/iox/src/iox.vb			    
// Designer:	Michael Haight
// Date:        01/11/01        
//
// Description: This is the behavioral model for the IOX block
//		data logger chip.	     
//////////////////////////////////////////////////////////////////////////////// 
module IOX ( 
  P_ROMID, CLK_IOX, IO_PD, IOX_RSTZ, IOX_WRDATA,
  IOX_CSR, IOX_RDDATA, IOX_READZ, 
  IO_BUF );

///// Port Declarations ////////////////////////////////////////////////////////

output  P_ROMID;		// Output the parameter of ROMID
output	CLK_IOX;		// The IOX output clock
output	IO_PD;			// IO pulldown (nch) for reading 1-Wire device
output	IOX_RSTZ;		// 1-Wire reset line (active-low)
output	IOX_WRDATA;		// Write-data from host to ow_slave

input	IOX_CSR;		// Causes acceptance of Conditional Search ROM
input	IOX_RDDATA;		// Read data from ow_slave to host
input	IOX_READZ;		// 1-Wire direction indicator
input	IO_BUF;			// Buffered IO (1-Wire data)

///// General Declarations /////////////////////////////////////////////////////
integer		bit;

event		clock_timeout;	
event		kickdown_timeout;
event		reset;
event		reset_timeout;

parameter [63:0] p_romid = 64'h3577_6655_4433_2211; 

parameter [7:0] READ_ROM	= 8'h33,
                MATCH_ROM	= 8'h55,
                SEARCH_ROM	= 8'hF0,
		COND_SEARCH_ROM = 8'hEC,
                SKIP_ROM	= 8'hCC,
                RESUME		= 8'hA5,
                OD_SKIP		= 8'h3C,
                OD_MATCH	= 8'h69,
                HD_SKIP		= 8'hC3,
                HD_MATCH	= 8'hCE,
		TEST_MATCH	= 8'h96,
		ENTER_TEST	= 8'hC3,
		EXIT_TEST	= 8'h3C,
		EN_TCLK		= 8'h5A,
		EN_OSC_OUT	= 8'hA5,
		BAT_TEST	= 8'hF0;

parameter t_time    = 30000,	// 15us <= T time    < 60us
	  od_t_time = 3000;	// 2us  <= T time    < 6us  


reg		overdrive;
reg		DATA_BIT;
reg	[7:0]	DATA_BYTE;
reg		CLK_IOX;
reg		IO_PD_PRE;
reg		IOX_RSTZ;
reg		IOX_WRDATA;
reg		MATCH_FAIL;
reg	[7:0]	OPCODE;
reg		POR;
reg		RESUME_FLAG;
reg		SEL_CLK_TEST;
reg		SEL_IO_PD;
reg		TEST;
reg		TPROT_OK;

wire	[63:0]	P_ROMID = p_romid;

wire		CLK_TEST_RX;
wire		IOX_PD;
wire		F4K_OR_TA_OUT;
wire		IOX_CSR;
wire		VCC;			// no functionality in this model (yet)

// Added for creating two different clk domains for IO_BUF/CLK_IOX and IO_BUF_DLY/IO_PD_PRE
wire #1 IO_BUF_DLY = IO_BUF;
reg CLK_IOX_NULL;


reg IO_PD_PRE_NULL;
reg IOX_WRDATA_NULL;
////////////////////// End add two clk domains/////////////////////////

////////////////////////////////////////////////////////////////////////////////

initial
begin
  bit = 8;
  CLK_IOX = 0;
  DATA_BIT = 0;
  DATA_BYTE = 8'h0;
  IO_PD_PRE = 0;
  IOX_RSTZ = 1;
  IOX_WRDATA = 0;
  MATCH_FAIL = 0;
  OPCODE = 8'h0;
  RESUME_FLAG = 0;
  SEL_IO_PD = 0;
  TEST = 0;
  TPROT_OK = 0;
  overdrive = 0;
end

assign IO_PD = IO_PD_PRE;




always @(negedge IO_BUF)
begin : reset_timer
  if (overdrive)
    #(8*(od_t_time));
  else
    #(8*(t_time));
  -> reset_timeout;
  IOX_RSTZ = 0;
  disable command_chk;
  disable prot_ok;
  disable prot_ok_dly;
  #1;
  -> reset;
end

always @(negedge IO_BUF)
begin : kickdown_timer
  if (overdrive)
  begin
    #(8*od_t_time + 5*t_time);
    -> kickdown_timeout;
  end
end

always @(negedge IO_BUF)
begin : clock_timer
  if (overdrive)
    #(od_t_time);
  else
    #(t_time);
  -> clock_timeout;
end


///// Check for 1-Wire reset

always @(negedge IO_BUF)
begin : reset_seq
  if (overdrive)
  begin
    @(reset_timeout or posedge IO_BUF);
    if (IO_BUF)				//
    begin
      disable reset_timer;
      disable kickdown_timer;
    end
    else				// Had to be reset timeout
    begin
      @(kickdown_timeout or posedge IO_BUF);
      if (IO_BUF)			// we have od reset sequence
      begin
        bit = 8;
        #(od_t_time);			// 1 T high
        IO_PD_PRE = 1;			// turn on pulldown
        #1 disable reset_timer;		// Don't start timer again
	#1 disable kickdown_timer;
        #(4*(od_t_time));		// 4 T low
        IO_PD_PRE = 0;			// turn off pulldown
      end
      else				// We have kickdown case
      begin
	overdrive = 0;
        @(posedge IO_BUF);
        bit = 8;
        #(t_time);			// 1 T high
        IO_PD_PRE = 1;			// turn on pulldown
        #1 disable reset_timer;		// Don't start timer again
	#1 disable kickdown_timer;	
        #(4*(t_time));			// 4 T low
        IO_PD_PRE = 0;			// turn off pulldown
      end
    end      
  end
  else					// Standard mode reset
  begin
    @(reset_timeout or posedge IO_BUF);
    if (IO_BUF)
      disable reset_timer;
    else
    begin
      @(posedge IO_BUF);
      #(t_time);			// 1 T high
      IO_PD_PRE = 1;			// turn on pulldown
      #1 disable reset_timer;		// Don't start timer again
      #(4*(t_time));			// 4 T low
      IO_PD_PRE = 0;			// turn off pulldown
    end
  end
end


always @(reset)
begin : command_chk
  SEL_CLK_TEST = 0;
  SEL_IO_PD = 0;
  TPROT_OK = 0;
  @(negedge IO_BUF);
  for (bit=0; bit < 8; bit=bit+1)
  begin
    @(negedge IO_BUF);
    if (overdrive)
      #(od_t_time);
    else
      #(t_time);
    OPCODE[bit] = IO_BUF;
  end
  
  tb_ds1wm.xtc_ds1wm.xscoreboard.verify_command(OPCODE);
  
  case (OPCODE)
    READ_ROM:
      begin
        $display("%t OW_SLAVE - READ_ROM command received",$time);
	RESUME_FLAG = 0;
        for (bit=0; bit <64; bit=bit+1)
	  read_bit(p_romid[bit]);
	IOX_RSTZ = 1;
      end
      
    MATCH_ROM:
      begin
        $display("%t OW_SLAVE - MATCH_ROM command received",$time);
	MATCH_FAIL = 0;
	RESUME_FLAG = 0;
	for (bit=0; bit<64; bit=bit+1)
	begin  
	  if(MATCH_FAIL == 0)              //SWM Added so ow_slave would not match when this is the wrong slave
	  begin
	  write_bit(DATA_BIT);
	  if (DATA_BIT != p_romid[bit])
	    MATCH_FAIL = 1;
	  end
	end
	if (~MATCH_FAIL)
	begin
	  IOX_RSTZ = 1;
	  RESUME_FLAG = 1;
	end
      end

    SEARCH_ROM:
      begin
        $display("%t OW_SLAVE - SEARCH_ROM command received",$time);
	MATCH_FAIL = 0;
	RESUME_FLAG = 0;
	for (bit=0; bit<64; bit=bit+1)
	begin
	  if(MATCH_FAIL == 0)         //SWM Added so ow_slave would not pull low the ow when not selected
	  begin
	  read_bit(p_romid[bit]);
	  read_bit(~p_romid[bit]);
	  write_bit(DATA_BIT);
	  if (DATA_BIT != p_romid[bit])
	    MATCH_FAIL = 1;
	  end
	end
	if (~MATCH_FAIL)
	begin
	  IOX_RSTZ = 1;
	  RESUME_FLAG = 1;
	end	
      end

    COND_SEARCH_ROM:
      begin
	MATCH_FAIL = 0;
	RESUME_FLAG = 0;
	if (IOX_CSR)
	begin
	  for (bit=0; bit<64; bit=bit+1)
	  begin
	    if(MATCH_FAIL == 0)      //SWM Added so ow_slave would not pull low the ow when not selected
	    begin
	    read_bit(p_romid[bit]);
	    read_bit(~p_romid[bit]);
	    write_bit(DATA_BIT);
	    if (DATA_BIT != p_romid[bit])
	      MATCH_FAIL = 1;
	    end
	  end  
	  if (~MATCH_FAIL)
	  begin
	    IOX_RSTZ = 1;
	    RESUME_FLAG = 1;
	  end	
	end
	else
	  IOX_RSTZ = 0;
      end

    SKIP_ROM:
      begin
        $display("%t OW_SLAVE - SKIP_ROM command received",$time);
	RESUME_FLAG = 0;
        IOX_RSTZ = 1;
      end

    RESUME:
      begin
	if (RESUME_FLAG)
	  IOX_RSTZ = 1;
      end

    OD_SKIP:
      begin
	overdrive = 1;
	RESUME_FLAG = 0;
        IOX_RSTZ = 1;
      end

    OD_MATCH:
      begin
	overdrive = 1;
	MATCH_FAIL = 0;
	RESUME_FLAG = 0;
	for (bit=0; bit<64; bit=bit+1)
	begin
	  if(MATCH_FAIL == 0)     //SWM Added so ow_slave would not match when this is not the right slave selected
	  begin
	  write_bit(DATA_BIT);
	  if (DATA_BIT != p_romid[bit])
	    MATCH_FAIL = 1;
	  end
	end  
	if (~MATCH_FAIL)
	begin
	  IOX_RSTZ = 1;
	  RESUME_FLAG = 1;
	end
      end

   //
   // Removed match portion for A2
   //
    TEST_MATCH:
      begin
	MATCH_FAIL = 0;
	RESUME_FLAG = 0;
	//for (bit=0; bit<64; bit=bit+1)
	//begin
	//  write_bit(DATA_BIT);
	//  if (DATA_BIT != p_romid[bit])
	//    MATCH_FAIL = 1;
	//end
	//if (~MATCH_FAIL)
	//begin
	  TPROT_OK = 1;
	  for (bit=0; bit<8; bit=bit+1)
	  begin
	    write_bit(DATA_BIT);
	    DATA_BYTE[bit] = DATA_BIT;
	  end
	  case (DATA_BYTE)
	    ENTER_TEST: TEST = 1;
	    EXIT_TEST : TEST = 0;
	    EN_TCLK   : SEL_CLK_TEST =1;
	    EN_OSC_OUT: SEL_IO_PD  = 1;
	    BAT_TEST  : TEST = TEST;		// do nothing for now!
	    default   : TEST = TEST;
	  endcase
	//end
      end

    default:
      begin
	IOX_RSTZ = 0;
      end

  endcase
end


// Clock generation of CLK_IOX domain. Dummy of IO_PD_PRE/IOX_WR_DATA_NULL
///// IOX signal generation after PROT_OK (IOX_RSTZ = 1) ///////////////////////
always @(negedge IO_BUF)				// Start at every bit
begin : prot_ok
//  $display( "%t  IOX:  negedge IO_BUF - check prot_ok",$time);
  if (IOX_RSTZ)					// Verify PROT_OK
    if (~IOX_READZ)				// READ case
    begin
      CLK_IOX = 0;
      #1000;				// Wait 1 us to sample
      if (IOX_RDDATA)
        IO_PD_PRE_NULL = 0;
      else

	IO_PD_PRE_NULL = 1;
	
      if (overdrive)
        #(od_t_time);				// Wait 1-Wire od osc time
      else
        #(t_time);

				// Wait 1-Wire std osc time
      if (~IO_BUF && IOX_RDDATA)		// Verify read slot sent
        CLK_IOX = 0;
      else					// line low too long for rd slot
	CLK_IOX = 1;
	
      IO_PD_PRE_NULL = 0;				
    end
    else					// WRITE case
    begin
      CLK_IOX = 0;

      IOX_WRDATA_NULL = 0;	
//  $display( "%t  IOX:  wait for clock_timeout",$time);
      @(clock_timeout or posedge IO_BUF);
      if (IO_BUF)				// Write 1
      begin
//  $display( "%t  IOX:  posedge IO_BUF",$time);
        IOX_WRDATA_NULL = 1;
	@(clock_timeout);			// Clock fires at timeout
	CLK_IOX = 1;
      end
      else					// Write 0
      begin
//  $display( "%t  IOX:  clock_timeout",$time);
        disable clock_timer;			// Clock follows IO_BUF now
	@(posedge IO_BUF);
	CLK_IOX = 1;
      end
    end
  else	
    begin					// NOT PROT_OK (no CLK_IOX now)
//      $display( "%t  IOX:  PROT_OK Failed",$time);
      CLK_IOX = 0;
    end   
     
end



// Uses IO_BUF_DLY to set IO_PD_PRE/IOX_WR_DATA_NULL for slave simulation correction
///// IOX signal generation after PROT_OK_DLY (IOX_RSTZ = 1) ///////////////////////
always @(negedge IO_BUF_DLY)				// Start at every bit
begin : prot_ok_dly
//  $display( "%t  IOX:  negedge IO_BUF - check prot_ok",$time);
  if (IOX_RSTZ)					// Verify PROT_OK
    if (~IOX_READZ)				// READ case
    begin
      CLK_IOX_NULL = 0;
      #1000;				// Wait 1 us to sample
      if (IOX_RDDATA)
        IO_PD_PRE = 0;
      else
	IO_PD_PRE = 1;
	
      if (overdrive)
        #(od_t_time);				// Wait 1-Wire od osc time
      else
        #(t_time);

				// Wait 1-Wire std osc time
      if (~IO_BUF && IOX_RDDATA)		// Verify read slot sent
        CLK_IOX_NULL = 0;
      else					// line low too long for rd slot
	CLK_IOX_NULL = 1;
	
      IO_PD_PRE = 0;				
    end
    else					// WRITE case
    begin
      CLK_IOX_NULL = 0;

      IOX_WRDATA = 0;	
//  $display( "%t  IOX:  wait for clock_timeout",$time);
      @(clock_timeout or posedge IO_BUF);
      if (IO_BUF)				// Write 1
      begin
//  $display( "%t  IOX:  posedge IO_BUF",$time);
        IOX_WRDATA = 1;
	@(clock_timeout);			// Clock fires at timeout
	CLK_IOX_NULL = 1;
      end
      else					// Write 0
      begin
//  $display( "%t  IOX:  clock_timeout",$time);
        disable clock_timer;			// Clock follows IO_BUF now
	@(posedge IO_BUF);
	CLK_IOX = 1;
      end
    end
  else	
    begin					// NOT PROT_OK (no CLK_IOX now)
//      $display( "%t  IOX:  PROT_OK Failed",$time);
      CLK_IOX_NULL = 0;
    end   
     
end

///// Low-level read/write-bit tasks ///////////////////////////////////////////
    
task read_bit;					// From Master perspective
input i;
begin
  @(negedge IO_BUF);				// Begin TX bit
  IO_PD_PRE = ~i;
  if (overdrive)
    #(od_t_time);
  else
    #(t_time);
  IO_PD_PRE = 0;
end
endtask

task write_bit;					// From Master perspective
output i;
begin
  @(negedge IO_BUF);
  if (overdrive)
    #(od_t_time);				// Wait for od sample time
  else
    #(t_time);					// Wait for std sample time
  i = IO_BUF;
end
endtask
   

endmodule

