////////////////////////////////////////////////////////////////////////////////
// Project:	ow_slave						      
// Module:      cmd_ctrl                                                
// Path:	/vefification/verilog_src/testbench/cmd_ctrl.vb			    
// Designer:	SWM
// Date:        08/28/08      
//
// Description: This is the behavioral model for the command control center.
//		
//////////////////////////////////////////////////////////////////////////////// 
module cmd_ctrl (
  CLK_MEM, IOX_RSTZ, IOX_WRDATA, END_1WIRE,
           IOX_CSR,  IOX_RDDATA, IOX_READZ);


///// Port Declarations ////////////////////////////////////////////////////////

input		CLK_MEM;
input		IOX_RSTZ;
input		IOX_WRDATA;

output		END_1WIRE;
output		IOX_CSR;
output		IOX_RDDATA;
output		IOX_READZ;


//-------------------------------
// JJG Debug
wire IOX_CSR = 1'b0;
wire WAKE = 1'b1;
//-------------------------------





///// General Declarations /////////////////////////////////////////////////////
event	start_cmd;

integer	                bit;
integer byte;
integer	i;

parameter [7:0] WRITE_SP     	= 8'h0F,
		READ_SP      	= 8'hAA,
		COPY_SP      	= 8'h55,
		READ_MEM	= 8'hF0;


reg write_sp_flag;
reg read_sp_flag;
reg copy_sp_flag;

reg		AA;
reg		BOR_FLAG;
reg		CLR_MEMZ;
reg		CLR_ON_SM;
reg		COMM_MEZ;
reg		COMM_OEZ;
reg		COMM_WEZ;
reg	[7:0]	COMM_WRDATA;
reg	[13:0]	DATA_ADDR;
reg	[23:0]	DEV_CNT;
reg	[7:0]	DEVICE_CONFIG;
reg	[7:0]	DEVICE_SAMPLE_L;
reg	[7:0]	DEVICE_SAMPLE_M;
reg	[7:0]	DEVICE_SAMPLE_H;
reg		EN_DATA_ADDR;
reg		EN_TEMP_ADDR;
reg		END_1WIRE;
reg	[7:0]	ES;
reg		INC_DEVICE;
reg		IOX_RDDATA;
reg		IOX_READ;
reg		LD_DATA_ADDR;
reg		LD_TEMP_ADDR;
reg	[23:0]	MSN_CNT;
reg	[5:0]	OFFSET;  
reg		OFST_FLAG;
reg	[7:0]	OPCODE;
reg		SLEEP;
reg	[7:0]	SFR_RDDATA;
reg	[4:0]	SP_ADDR;
reg		SP_MEZ;
reg		SP_OEZ;
reg		SP_WEZ;
reg	[7:0]	SP_WRDATA;
reg		START_DCONV;
reg		START_TCONV;
reg	[7:0]	STATUS1;
reg	[7:0]	STATUS2;
reg	[15:0]	TA;
reg	[13:0]	TEMP_ADDR;
reg	[7:0]	WORD;

wire		AD_VALID;
wire		CMD_MEZ;
wire		CMD_OEZ;
wire		CMD_WEZ;
wire		DHF;
wire		DLBS;
wire		DLF;
wire		EDL;
wire		EPCK;
wire		ETL;
//wire		IOX_CSR;
wire		IOX_READZ;
wire		RD_EN;
wire	[7:0]	RDDATA;
wire		RO;
wire		SFR_SPACE;
wire		TEST;


reg     [15:0] sp_mem [0:1023];

////////////////////////////////////////////////////////////////////////////////
assign	IOX_READZ = ~IOX_READ;

assign  SFR_SPACE = (TA >= 14'h0200 && TA <= 14'h023F);



//-------------------------------------------
//ADDED JJG

reg BOR;
initial begin 

   BOR = 1'b1;
   
end    
//-------------------------------------------

///// combinational model for status bits //////////////////////////////////////

always @(posedge BOR or negedge CLR_MEMZ or posedge BOR_FLAG)
begin
  if (BOR)
  begin
    BOR_FLAG <= 1;
  end
  if (~CLR_MEMZ)
  begin
    BOR_FLAG <= 0;


//-------------------------------------------
  end
end



initial
begin
  AA		= 0;
  CLR_MEMZ	= 1;
  COMM_MEZ	= 1;
  COMM_OEZ	= 1;
  COMM_WEZ	= 1;
  COMM_WRDATA	= 8'h0;
  END_1WIRE	= 1;
  ES		= 0;
  IOX_RDDATA	= 0;
  IOX_READ	= 0;
  OFFSET	= 5'h0;
  OFST_FLAG 	= 0;
  OPCODE	= 8'h0;
  SP_ADDR	= 5'b0;
  SP_MEZ	= 1;
  SP_OEZ	= 1;
  SP_WEZ	= 1;
  SP_WRDATA	= 8'h0;
  TA		= 16'h0;
  WORD		= 8'h0;

end




always @(posedge BOR or posedge AA or posedge CLK_MEM)
  if (BOR)
    ES[7] <= 0;
  else if (AA)
    ES[7] <= 1;
  else
    ES[7] <= AA;


// --------------------  Added JJG ---------------------------
always @(negedge IOX_RSTZ)	// Disable any current tasks running
begin
    IOX_RDDATA = 1;
    IOX_READ = 1;  
    

    disable start_1wire;
    #1;                      // Fixes simulation scheduling issue
    ->start_cmd;
end



always @(start_cmd)			// Start processing commands
begin : start_1wire
  COMM_MEZ = 1;
  COMM_OEZ = 1;
  COMM_WEZ = 1;
  IOX_READ = 0;
  OFST_FLAG  = 0;
  SP_ADDR = 5'b0;
  SP_MEZ = 1;
  SP_OEZ = 1;
  SP_WEZ = 1;
  SP_WRDATA = 8'h0;

  @(posedge IOX_RSTZ);
  END_1WIRE = 0;

  for (bit = 0; bit <=7; bit=bit+1)
  begin
    @(posedge CLK_MEM);
    OPCODE[bit] = IOX_WRDATA;
  end

  tb_ds1wm.xtc_ds1wm.xscoreboard.verify_command(OPCODE);
  
  case (OPCODE)
    WRITE_SP:		begin
			  write_sp_flag = 1'b1;
                          write_sp;
			end  
    READ_SP:		begin
			   read_sp_flag = 1'b1;
			   read_sp;
			end   
    COPY_SP:		begin
			   copy_sp_flag = 1'b1;
                           copy_sp;
			end   
    READ_MEM:		read_mem;
    default:            report_invalid_opcode(OPCODE);
  endcase
  
  #1;
  write_sp_flag = 1'b0;
  read_sp_flag = 1'b0;
  copy_sp_flag = 1'b0;
  
end

///// Write scratchpad definition //////////////////////////////////////////////

task write_sp;

begin
  $strobe("%t OW_SLAVE - Write Scratchpad command received",$time);
//  IOX_RDDATA = 1;				// Send ones from now till rst
//  END_1WIRE = 1;				// 1-Wire is done
  
  for (bit = 0; bit <= 15; bit=bit+1)
  begin
    @(posedge CLK_MEM);
    TA[bit] = IOX_WRDATA;			// Receive Target Address 
  end
  
  OFFSET = TA[4:0];				// Set up Ending offset
  SP_ADDR = OFFSET[4:0];
  
  OFST_FLAG = 0;
  
  while (~OFST_FLAG && IOX_RSTZ)
  begin
  
    for (bit = 0; bit <= 7; bit=bit+1)
    begin:wdata_loop
         if (IOX_RSTZ) begin 
            @(posedge CLK_MEM or negedge IOX_RSTZ);
            if (IOX_RSTZ) 
           	WORD[bit] = IOX_WRDATA; 
	    else 
	   	disable wdata_loop;  
	 end 
    end
    
    if (IOX_RSTZ) begin
       SP_ADDR = OFFSET[4:0];
       SP_WRDATA = WORD;
    
       sp_mem[SP_ADDR] = SP_WRDATA;
    
    
       if (OFFSET == 6'h1f)
         OFST_FLAG = 1;
       else
         OFFSET = OFFSET + 1;
    end	 
  end
  
  IOX_RDDATA = 1;				// Send ones from now till rst
  END_1WIRE = 1;				// 1-Wire is done
  $strobe("%t OW_SLAVE - Write Scratchpad exit",$time);
end
endtask


///// Read scratchpad definition ///////////////////////////////////////////////

task read_sp;

begin
  $strobe("%t OW_SLAVE - Read_Scratchpad command received",$time);

  for (bit = 0; bit <= 15; bit=bit+1)
  begin
    @(posedge CLK_MEM);
    TA[bit] = IOX_WRDATA;			// Receive Target Address
  end
  
  OFFSET = TA[4:0];				// Set up Ending offset
  
  OFST_FLAG = 0;
  
  while (~OFST_FLAG && IOX_RSTZ)
  begin
  
    
    if (IOX_RSTZ) begin
       SP_ADDR = OFFSET[4:0];
       WORD = sp_mem[SP_ADDR];
//       $display("READ_SP OW_SLAVE internal memory fetch: addr = %h, data = %h",SP_ADDR,WORD);
       
       for (bit = 0; bit <= 7; bit=bit+1)
       begin:rdata_loop
         if (IOX_RSTZ) begin 
            @(negedge CLK_MEM or negedge IOX_RSTZ);
            if (IOX_RSTZ) begin
	        IOX_READ   = 1; 
            	IOX_RDDATA = WORD[bit];
	    end else 
	    	disable rdata_loop;  
	 end	
       end
    
       if (OFFSET == 6'h1f)
         OFST_FLAG = 1;
       else
         OFFSET = OFFSET + 1;
    end	 
  end
  
  @(posedge CLK_MEM);				// Wait one more clock edge
  
  IOX_RDDATA = 1;				// Send ones from now till rst 
  END_1WIRE = 1;				// 1-Wire is done 
  $strobe("%t OW_SLAVE - Read Scratchpad exit",$time);
end
endtask

///// Copy scratchpad definition ///////////////////////////////////////////////

task  copy_sp;

begin
    $strobe("%t OW_SLAVE - Copy_Scratchpad command received",$time);
    IOX_RDDATA = 1;
    IOX_READ = 1;
end
endtask


///// Read Memory definition ///////////////////////////////////////////////////

task read_mem;
begin
    $strobe("%t OW_SLAVE - Read_Memory command received",$time);
  IOX_RDDATA = 1;				// Send ones from now till rst  
  END_1WIRE = 1;				// 1-Wire is done
end
endtask


///// Report Invlid Opcode definition ///////////////////////////////////////////////////
task report_invalid_opcode(input [7:0] opcode);
begin

  $strobe("%t OW_SLAVE CMD_CTRL: INVALID OPCODE %h",$time,opcode);
    
  IOX_RDDATA = 1;				// Send ones from now till rst  
  END_1WIRE = 1;				// 1-Wire is done
end
endtask
endmodule
