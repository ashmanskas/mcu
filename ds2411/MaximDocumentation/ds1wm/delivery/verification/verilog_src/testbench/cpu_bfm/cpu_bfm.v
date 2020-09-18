//`define OW_SWITCH

module cpu_bfm (ADDR, ADS_N, CLKSEL, RD_N, WR_N, EN_N, INTR, DATA);

output [2:0] ADDR;
output       ADS_N;
output [7:0] CLKSEL;
output       RD_N;
output       WR_N;
output       EN_N;



inout        INTR;

inout  [7:0] DATA;



parameter div = 1;                      // division factor for timebase

// Data Bus Interface Timing
parameter tads     = 60,    //     60ns  <=     Tads
          tah      = 0,     //      0ns	 <=     Tah 
          tar      = 60,    //     60ns  <=     Tar 
          tas      = 60,    //     60ns  <=     Tas 
          taw      = 60,    //     60ns  <=     Taw 
          tdh      = 20,    //     20ns  <=     Tdh
          tds      = 30,    //     30ns  <=     Tds 
          tes      = 60,    //     60ns  <=     Tes 
          thz      = 100,   //      0ns  <=     Thz  <=  100ns
          tpdi     = 100,   //      0ns  <=     Tpdi <=  100ns
          trd      = 125,   //    125ns  <=     Trd
          tren     = 60,    //      0ns  <=     Tren <= 60ns
          trvd     = 60,    //      0ns  <=     Trvd <= 60ns
          twen     = 20,    //     20ns  <=     Twen 
          twr      = 100,   //    100ns  <=     Twr 
          twrst    = 100,   //                  Twrst  <=  100ns
          twrt     = 100;   //      0ns  <=     Twrt <=  100ns 

// OneWire Interface Timing
parameter trstl     = 501000,    //     500.8us  <=     Trstl  <= 626us
          tr        = 0,         //      0ns	 <=     Tah 
          trsth     = 510000;    //     508.8us  <=     Trsth  <= 636us     



// one wire command bytes
parameter [7:0] READ_ROM	= 8'h33,
                MATCH_ROM	= 8'h55,
                SEARCH_ROM	= 8'hF0,
		COND_SEARCH_ROM = 8'hEC,
                SKIP_ROM	= 8'hCC,
		OD_SKIP_ROM	= 8'h3C,
		OD_MATCH_ROM	= 8'h69;

// DS1WM memory functions
parameter [7:0] WRITE_SP        = 8'h0F,
                READ_SP         = 8'hAA,
                COPY_SP         = 8'h55,
                READ_MEM        = 8'hF0;
		
// DS1WM ADRESS MAPPED REGISTERS

parameter [2:0] COMMAND_REG     = 3'd0,
                TX_BUFFER       = 3'd1,
                RX_BUFFER       = 3'd1,
                IR              = 3'd2,
                IR_ENABLE       = 3'd3,
                CLK_DIV_REG     = 3'd4,
                CNTL_REG        = 3'd5;	

		
/////// General Declarations ///////////Added SWM////////
integer cnt;
integer next_branch_flag, d_bit_position, last_d_bit_position;

reg [7:0] sp_test_mem [0:255];
reg sp_mem_status;

////////////////////////////////////////////////////////		
	
reg ias;
reg [7:0] ir_en_reg;

reg [7:0] current_cmd ;
reg [7:0] dout;

reg [2:0] ADDR;
reg       ADS_N;
reg [7:0] CLKSEL;
reg       RD_N;
reg       WR_N;
reg       EN_N;
reg [127:0] search_write;    //Used for search ROM result
reg [127:0] last_search_write;
reg search_done_flag;

reg [7:0] ir_reg;
wire       INTR;
wire       intr_int = INTR ^ ias;

wire [7:0] DATA;


assign DATA = dout;
//-----------------------------------------------------------

initial begin
   ADDR = 3'd0;
   ADS_N = 1'b1;
   RD_N  = 1'b1;
   WR_N  = 1'b1;
   EN_N  = 1'b1;   
   search_write = 128'h0000_0000_0000_0000_0000_0000_0000_0000;
   last_search_write = 128'h0000_0000_0000_0000_0000_0000_0000_0000;
   next_branch_flag = 0;
   search_done_flag = 0;
   d_bit_position = 0;
   last_d_bit_position = 0;
   
   dout = 8'hz;
   ias = 0;
   sp_mem_status = 1;
end


task ow_reset;            // 1-Wire Reset ////////////////////////////////////////

	
begin

  ir_en_reg = 8'h01 ^ {6'b000000,ias,1'b0};
  
  cpu_write(IR_ENABLE,ir_en_reg);
  
  ADS_N = 1'b0;
  
  # (tads - tas);
  
  ADDR = 3'b000;
  
  # (tas - tes);
  
  EN_N =  1'b0;
  
  # tes;
  
  ADS_N = 1'b1;
  
  # taw;
  
  WR_N = 1'b0;
  
  # (twr - tds);
  
  dout = 8'h01;
  
  # tds;
  
  WR_N = 1'b1;
  
  # tdh;
  
  dout = 8'hz;
  
  # (twen - tdh);
  
  EN_N = 1'b1;
  
  @(negedge intr_int);
  read_ir;

end
endtask

//-----------------------------------------------------------

task cpu_write(input [2:0] address, input [7:0] din);      

	
begin
  
  ADS_N = 1'b0;
  
  # (tads - tas);
  
  ADDR = address;
  
  # (tas - tes);
  
  EN_N =  1'b0;
  
  # tes;
  
  ADS_N = 1'b1;

  # taw;
  
  WR_N = 1'b0;
  
  # (twr - tds);
  
  dout = din;
  
  # tds;
  
  WR_N = 1'b1;
  
  # twen;
  
  EN_N = 1'b1;
  
  # (tdh - twen);

  dout = 8'hz;
  
  
end
endtask

//-----------------------------------------------------------



task ow_write_byte(input [2:0] address, input [7:0] din);      

reg [7:0] temp, temp1;
	
begin

  
  cpu_write(address,din);
  
  ir_en_reg = 8'h04 ^ {6'b000000,ias,1'b0};
  cpu_write(IR_ENABLE,ir_en_reg);

  @(negedge intr_int);
  read_ir;
  
  ir_en_reg = 8'h08 ^ {6'b000000,ias,1'b0};
  cpu_write(IR_ENABLE,ir_en_reg);
  
  @(negedge intr_int);
  read_ir;

  ir_en_reg = 8'h10 ^ {6'b000000,ias,1'b0};  //Flush Rx Buffer and Rx Shift Reg after each 1-wire write
  cpu_write(IR_ENABLE,ir_en_reg);
  
  	   
  @(negedge intr_int); 
  read_ir;               
  
  if(ir_reg[5:4] == 2'b11) begin
  cpu_read(RX_BUFFER, temp);
  cpu_read(RX_BUFFER, temp1);
//  $display("%t CPU      - rx buffer/rx-shift reg flush = %0h/%0h  | IR reg = %0h",$time, temp, temp1, ir_reg);
  end
  if(ir_reg[5:4] == 2'b01) begin
  cpu_read(RX_BUFFER, temp);
//  $display("%t CPU      - rx buffer only flush = %0h  | IR reg = %0h",$time, temp, ir_reg);
  end


end
endtask

//-----------------------------------------------------------


task ow_read_byte(input [2:0] address, output [7:0] dout);      

reg [7:0] temp;
reg [7:0] temp1;	

begin

  cpu_write(TX_BUFFER,8'hff);

  ir_en_reg = 8'h04 ^ {6'b000000,ias,1'b0};
  cpu_write(IR_ENABLE,ir_en_reg);



  @(negedge intr_int);
  read_ir;
  
  ir_en_reg = 8'h08 ^ {6'b000000,ias,1'b0};
  cpu_write(IR_ENABLE,ir_en_reg);
  
  @(negedge intr_int);
  read_ir;
  
  ir_en_reg = 8'h10 ^ {6'b000000,ias,1'b0};
  cpu_write(IR_ENABLE,ir_en_reg);
  
  	   
  @(negedge intr_int); 
  read_ir;
  
  if (ir_reg[4] == 1'b1) //RX_BUFFER received data from the shift register
  	begin
 	cpu_read(address, dout);   
  end
 

  ir_en_reg = 8'h00 ^ {6'b000000,ias,1'b0};   //Disable ERBF after read
  cpu_write(IR_ENABLE,ir_en_reg);	

end
endtask


//-----------------------------------------------------------
// Accelerated ROM Search (ars) read byte

task ow_read_byte_ars (input [2:0] address, input [7:0] din, output [7:0] dout);      

reg [7:0] temp, temp1;

begin

  cpu_write(address, din);  // Write tx data with discripancies if needed during an ARS.


  ir_en_reg = 8'h04 ^ {6'b000000,ias,1'b0};  //Enable ETBE (enable tx buffer empty) interrupt
  cpu_write(IR_ENABLE,ir_en_reg);

  @(negedge intr_int);  //Wait until TBE (Tx buffer empty) flag is set causing an interrupt which means the tx buffer is empty
  read_ir;		//Read clearing the TBE to zero and the int pin
  

  ir_en_reg = 8'h08 ^ {6'b000000,ias,1'b0};  //Enable ETMT (enable tx shift register empty) interrupt
  cpu_write(IR_ENABLE,ir_en_reg);
  
  @(negedge intr_int);  //Wait until TEMT flag is set causes an interrupt and means the tx shift reg is empty
  read_ir;		//Read clearing the TEMT flag to zero and ready for tx data again while clearing the int pin

  ir_en_reg = 8'h10 ^ {6'b000000,ias,1'b0};  //Enable ERBF (Enable Rx Buffer Full) interupt
  cpu_write(IR_ENABLE,ir_en_reg);
  		
  @(negedge intr_int);   //Wait until ERBF (Receive Buffer Full) flag is set
  read_ir;
  
  
  if (ir_reg[4] == 1'b1) //RX_BUFFER received data from the shift register
  begin
  cpu_read(address, dout);   
    end
  
  ir_en_reg = 8'h00 ^ {6'b000000,ias,1'b0};   //Disable ERBF after read
  cpu_write(IR_ENABLE,ir_en_reg);

end
endtask


//-----------------------------------------------------------

task cpu_read(input [2:0] address, output [7:0] dout);      

	
begin
  
  ADS_N = 1'b0;
  
  # (tads - tas);
  
  ADDR = address;
  
  # (tas - tes);
  
  EN_N =  1'b0;
  
  # tes;
  
  ADS_N = 1'b1;
  
  # tar;
  
  RD_N = 1'b0;
  
  # trvd;
  
  dout = DATA;
  
  # (trd - trvd);
  
  RD_N = 1'b1;
  
  # tren;
  
  EN_N = 1'b1;
  
  # (thz - tren);

end
endtask

//-----------------------------------------------------------



task read_ir;
//reg [7:0] ir_reg;
begin
  cpu_read(IR, ir_reg);  
end
endtask

//-----------------------------------------------------------

task set_clock_divisor;		
input [7:0] ratio;
reg [7:0] val;
begin
  $display("%t CPU      - Setting clock divisor = %0d ",$time, ratio);

   case (ratio)
      4:         val = 8'h88;
      5:         val = 8'h82;
      6:         val = 8'h85;
      7:         val = 8'h83;
      8:         val = 8'h8c;
      10:        val = 8'h86;
      12:        val = 8'h89;
      14:        val = 8'h87;
      16:        val = 8'h90;
      20:        val = 8'h8a;
      24:        val = 8'h8d;
      28:        val = 8'h8b;
      32:        val = 8'h94;
      40:        val = 8'h8e;
      48:        val = 8'h91;
      56:        val = 8'h8f;
      64:        val = 8'h98;
      80:        val = 8'h92;
      96:        val = 8'h95;
      112:       val = 8'h93;
      default: begin
                  val = 8'h00;
		  $display("%t  ERROR: Invalid Clock Divisor %d", $time, ratio);
               end
   endcase   
   
   cpu_write(CLK_DIV_REG,val);
   
   CLKSEL = ratio;
   
end
endtask

//-----------------------------------------------------------


task read_rom;		// Read ROM ////////////////////////////////////////////
begin
  $display("%t CPU      - READ_ROM command issued",$time);
  
  current_cmd = READ_ROM;
  
  tb_ds1wm.xtc_ds1wm.xscoreboard.write_command_fifo(READ_ROM);

  ow_reset;
  
  ow_write_byte(TX_BUFFER, READ_ROM);
 
  ow_read_byte(RX_BUFFER, tb_ds1wm.xtc_ds1wm.ROMID[7:0]);
   
  ow_read_byte(RX_BUFFER, tb_ds1wm.xtc_ds1wm.ROMID[15:8]); 
  ow_read_byte(RX_BUFFER, tb_ds1wm.xtc_ds1wm.ROMID[23:16]);
  
  ow_read_byte(RX_BUFFER, tb_ds1wm.xtc_ds1wm.ROMID[31:24]);
  
  ow_read_byte(RX_BUFFER, tb_ds1wm.xtc_ds1wm.ROMID[39:32]);
  
  ow_read_byte(RX_BUFFER, tb_ds1wm.xtc_ds1wm.ROMID[47:40]);
  
  ow_read_byte(RX_BUFFER, tb_ds1wm.xtc_ds1wm.ROMID[55:48]);
  ow_read_byte(RX_BUFFER, tb_ds1wm.xtc_ds1wm.ROMID[63:56]);        // CRC-8 byte (not calculated)

end
endtask


//-----------------------------------------------------------

task match_rom;		// Match ROM ///////////////////////////////////////////
input [63:0] match_id;
begin
  $display("%t CPU      - MATCH_ROM command issued",$time);
  
  current_cmd = MATCH_ROM;
  
  tb_ds1wm.xtc_ds1wm.xscoreboard.write_command_fifo(MATCH_ROM);
  
  ow_reset;
  ow_write_byte(TX_BUFFER, MATCH_ROM);
  
  ow_write_byte(TX_BUFFER, match_id[7:0]);
  ow_write_byte(TX_BUFFER, match_id[15:8]);
  ow_write_byte(TX_BUFFER, match_id[23:16]);
  ow_write_byte(TX_BUFFER, match_id[31:24]);
  ow_write_byte(TX_BUFFER, match_id[39:32]);
  ow_write_byte(TX_BUFFER, match_id[47:40]);
  ow_write_byte(TX_BUFFER, match_id[55:48]);
  ow_write_byte(TX_BUFFER, match_id[63:56]);

end
endtask

//--------------------------------------------------------------

task search_rom;	// Search ROM //////////////////////////////////////////


integer loop, n, k;
reg [127:0] result;

begin


  $display("\n-----------Search rom command issued; at time %0t -----------",$time/div);
  
  current_cmd = SEARCH_ROM;
  
  tb_ds1wm.xtc_ds1wm.xscoreboard.write_command_fifo(SEARCH_ROM);
  
  ow_reset;
  ow_write_byte(TX_BUFFER, SEARCH_ROM);

  
  cpu_write(COMMAND_REG, 8'h02);    //Turn on Search Rom Accelerator mode


        $display("%t CPU      - Search Write = %0h ",$time, search_write);   
  for (loop=1; loop <= 16; loop=loop+1)
  case(loop)
  5'd1:	ow_read_byte_ars(RX_BUFFER, search_write[7:0], result[7:0]);
  5'd2:	ow_read_byte_ars(RX_BUFFER, search_write[15:8], result[15:8]);
  5'd3:	ow_read_byte_ars(RX_BUFFER, search_write[23:16], result[23:16]);
  5'd4:	ow_read_byte_ars(RX_BUFFER, search_write[31:24], result[31:24]);
  5'd5:	ow_read_byte_ars(RX_BUFFER, search_write[39:32], result[39:32]);
  5'd6:	ow_read_byte_ars(RX_BUFFER, search_write[47:40], result[47:40]);
  5'd7:	ow_read_byte_ars(RX_BUFFER, search_write[55:48], result[55:48]);
  5'd8:	ow_read_byte_ars(RX_BUFFER, search_write[63:56], result[63:56]);
  5'd9:	ow_read_byte_ars(RX_BUFFER, search_write[71:64], result[71:64]);
  5'd10:ow_read_byte_ars(RX_BUFFER, search_write[79:72], result[79:72]);
  5'd11:ow_read_byte_ars(RX_BUFFER, search_write[87:80], result[87:80]);
  5'd12:ow_read_byte_ars(RX_BUFFER, search_write[95:88], result[95:88]);
  5'd13:ow_read_byte_ars(RX_BUFFER, search_write[103:96], result[103:96]);
  5'd14:ow_read_byte_ars(RX_BUFFER, search_write[111:104], result[111:104]);
  5'd15:ow_read_byte_ars(RX_BUFFER, search_write[119:112], result[119:112]);
  5'd16:ow_read_byte_ars(RX_BUFFER, search_write[127:120], result[127:120]);
  endcase
        $display("%t CPU      - RESULT = %0h ",$time, result);
  search_write=result;         //Store result for next search of discrepancy
   
  
  k=0;				//De-interleave the result to get the search rom
  for (n=1; n <= 127; n=n+2)
  begin
  tb_ds1wm.xtc_ds1wm.ROMID[k] = result[n];
  k=k+1;
  end


  k=1;
  for (n=0; n<=126; n=n+1)         //Shift over discrepancy from even to odd for next search.
  begin
  search_write[k] = result[n];
  k=k+1;
  end
  
  for (n=0; n<=126; n=n+2)         //Zero all even don't care bit positions for next search
  begin
  search_write[n] = 1'b0;
  end

 
 
  if(next_branch_flag == 1)
  begin
	if (search_write == last_search_write) begin
	search_done_flag = 1;
	$display("%t All ROMIDs found!",$time);
	end
	else
	begin
		result = last_search_write^search_write;	//Find new highest descrepancy not set to '1'
		for (n=1; n<=127; n=n+2)		
		begin
		if (result[n] == 1'b1)
		d_bit_position = n;
		end
		
		if (d_bit_position > last_d_bit_position) begin
		search_write = last_search_write;
		search_write[d_bit_position] = 1'b1;
		last_search_write = search_write;
		last_d_bit_position = d_bit_position;
		end
		
		if (d_bit_position < last_d_bit_position) begin
		search_write[d_bit_position] = 1'b1;
		for(n=127; n>d_bit_position; n=n-2)
		begin
		search_write[n] = 1'b0;
		end
		last_search_write = search_write;
		last_d_bit_position = d_bit_position;
		end					
	end	
	
  end
   
  if(next_branch_flag == 0)       		//Search for highest discrepancy and store into d_bit_position
  begin
  	for (n=1; n<=127; n=n+2)
	begin
	if (search_write[n] == 1'b1)
	d_bit_position = n;
	end
	for (n=1; n<d_bit_position; n=n+2)	//All discrepancies path choosen should be zero except for the highest discrepancy.
	begin
	search_write[n] = 1'b0;
	end
  last_d_bit_position = d_bit_position;	//Store last d_bit position for a compare later
  last_search_write = search_write;	//Store last search write for checking if search is don
  next_branch_flag = 1;
  end

  cpu_write(COMMAND_REG, 8'h00);   //Turn off Search Rom Accelerator mode
end
endtask

//-----------------------------------------------------------

task skip_rom;		// Skip ROM ////////////////////////////////////////////
begin
  $display("%t CPU      - SKIP_ROM command issued",$time);
  current_cmd = SKIP_ROM;
  tb_ds1wm.xtc_ds1wm.xscoreboard.write_command_fifo(SKIP_ROM);
  ow_reset;
  ow_write_byte(TX_BUFFER, SKIP_ROM);
end
endtask


task od_skip_rom;		// Skip ROM ////////////////////////////////////////////
begin
  $display("%t CPU      - OD_SKIP_ROM command issued",$time);
  current_cmd = OD_SKIP_ROM;
  tb_ds1wm.xtc_ds1wm.xscoreboard.write_command_fifo(OD_SKIP_ROM);
  ow_reset;
  ow_write_byte(TX_BUFFER, OD_SKIP_ROM);
  cpu_write(CNTL_REG,8'h40);		//Set DS1WM to OD timing
end
endtask


task od_match_rom;	// Overdrive Match ROM /////////////////////////////////
input [63:0] match_id;
begin
  $display("\nOverdrive match command at time %0t",$time/div);
  current_cmd = OD_MATCH_ROM;
    tb_ds1wm.xtc_ds1wm.xscoreboard.write_command_fifo(OD_MATCH_ROM);
  ow_reset;
  ow_write_byte(TX_BUFFER, OD_MATCH_ROM);
  cpu_write(CNTL_REG,8'h40);		//Set DS1WM to OD timing
  ow_write_byte(TX_BUFFER, match_id[7:0]);
  ow_write_byte(TX_BUFFER, match_id[15:8]);
  ow_write_byte(TX_BUFFER, match_id[23:16]);
  ow_write_byte(TX_BUFFER, match_id[31:24]);
  ow_write_byte(TX_BUFFER, match_id[39:32]);
  ow_write_byte(TX_BUFFER, match_id[47:40]);
  ow_write_byte(TX_BUFFER, match_id[55:48]);
  ow_write_byte(TX_BUFFER, match_id[63:56]);
end  
endtask

task ow_reset_to_std;	// Kickdown to STD mode ////////////////////////////////
begin
  $display("\n slow down by standard mode reset at time %0t",$time/div);
  cpu_write(CNTL_REG,8'h00);		//Set DS1WM to STD timing 
  ow_reset;
end
endtask


/////  RAM commands. ///////////////////////////////////////////////////////

//-----------------------------------------------------------

task write_sp;		// Write Scratchpad ////////////////////////////////////
  
reg [7:0] tx_random;  

begin

  $display("%t CPU      - Write_Scratchpad command issued",$time);
  current_cmd = WRITE_SP;
  
  tb_ds1wm.xtc_ds1wm.xscoreboard.write_command_fifo(WRITE_SP);
  ow_write_byte(TX_BUFFER, WRITE_SP);
  ow_write_byte(TX_BUFFER, 8'h00);  	// Write TA1
  ow_write_byte(TX_BUFFER, 8'h02);  	// Write TA2
  
  for (cnt = 0; cnt <= 31; cnt=cnt+1)
  	begin
	tx_random = $random;
  	ow_write_byte(TX_BUFFER, tx_random);  //Write TX data byte
	sp_test_mem[cnt] = tx_random;         //Store expected scratchpad data
	end
  
end
endtask         

//-----------------------------------------------------------

task read_sp;		// Read Scratchpad /////////////////////////////////////

reg [7:0] rx_byte;

begin
  $display("%t CPU      - Read_Scratchpad command issued",$time);
  current_cmd = READ_SP;
  
  tb_ds1wm.xtc_ds1wm.xscoreboard.write_command_fifo(READ_SP);
//  check_protok;				
  ow_write_byte(TX_BUFFER, READ_SP);
  $display("%t CPU      - Read_Scratchpad Memory Beginning",$time);    
  ow_write_byte(TX_BUFFER, 8'h00);  	// Write TA1
  ow_write_byte(TX_BUFFER, 8'h02);  	// Write TA2


  for (cnt = 0; cnt <= 31; cnt=cnt+1)
  	begin
  	ow_read_byte(RX_BUFFER, rx_byte);

   	if (rx_byte != sp_test_mem[cnt]) 
   		begin
      		$display("%t ERROR - Master received unexpected scratchpad data: expected sp data = %h, actual sp data  = %h",$time, sp_test_mem[cnt], rx_byte);
      		sp_mem_status = 0;
   		end 
   	end   
    
end
endtask 


//-----------------------------------------------------------

task copy_sp;		// Copy Scratchpad /////////////////////////////////////
      
begin
  $display("%t CPU      - Copy_Scratchpad command issued", $time);
  current_cmd = COPY_SP;
  
  tb_ds1wm.xtc_ds1wm.xscoreboard.write_command_fifo(COPY_SP);
//  check_protok;				// Check if ROM command succeeded.
  ow_write_byte(TX_BUFFER, COPY_SP);
//  prot_ok = 0;				// Reset prot_ok
end
endtask


//-----------------------------------------------------------

task read_mem;		// Read Memory /////////////////////////////////////////

begin

  $display("%t CPU      - Read_Memory command issued",$time);
  current_cmd = READ_MEM;
  
  tb_ds1wm.xtc_ds1wm.xscoreboard.write_command_fifo(READ_MEM);
//  check_protok;				// Check if ROM command succeeded.
  ow_write_byte(TX_BUFFER, READ_MEM);
end
endtask

//-----------------------------------------------------------

task test_stpz;           // Strong Pullup Enable/Disable during OW IDLE wiggle test //////////////////////
	
begin
	cpu_write(CNTL_REG,8'b00011000);     // Enable STPEN,and STP_SPLY
	$display("%t CPU      - Set STPZ active low during IDLE OW",$time);
	#124;                               //Wait at least the slowest clock cycle
	tb_ds1wm.xtc_ds1wm.xscoreboard.verify_stpz_low;
	#1;
	
	$display("%t CPU      - Set STPZ active high during IDLE OW",$time);
	cpu_write(CNTL_REG,8'b00001000);     // Enable STPEN
	#124;                                //Wait at least the slowest clock cycle
	tb_ds1wm.xtc_ds1wm.xscoreboard.verify_stpz_high;
	#1;	
	
	$display("%t CPU      - Set STPZ active low during IDLE OW",$time);
	cpu_write(CNTL_REG,8'b00011000);     // Enable STPEN,and STP_SPLY
	#124;                                //Wait at least the slowest clock cycle
	tb_ds1wm.xtc_ds1wm.xscoreboard.verify_stpz_low;
	#1;
	
	$display("%t CPU      - Set STPZ active high during IDLE OW",$time);
	cpu_write(CNTL_REG,8'b00001000);     // Enable STPEN
	#124;                                //Wait at least the slowest clock cycle
	tb_ds1wm.xtc_ds1wm.xscoreboard.verify_stpz_high;
	#1;	
     
end
endtask


//-----------------------------------------------------------

task set_ias(input val);		

begin
   if (val == 1) 
      $display("%t CPU      - Setting Interrupt Active High",$time);
   else
      $display("%t CPU      - Setting Interrupt Active Low",$time);
     
   #1 ias = val;
end
endtask

task report_sp_mem_status();

begin   
     
  $display("------------------------");
     
  if (sp_mem_status ==  1)
     $display("\t Scratchpad Memory Test Passed");
  else    
     $display("\t Scratchpad Memory Test Failed");
     
     
  $display("------------------------");
end
endtask

endmodule
