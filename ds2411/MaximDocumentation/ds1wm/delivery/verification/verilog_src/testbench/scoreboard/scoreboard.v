//`define OW_SWITCH
`ifdef OW_SWITCH

module scoreboard (OWS_ROMID1, OWS_ROMID2, OWS_ROMID3, OWS_ROMID4, STPZ);

input [63:0] OWS_ROMID1;
input [63:0] OWS_ROMID2;
input [63:0] OWS_ROMID3;
input [63:0] OWS_ROMID4;

//Override the parameter in the ow_slave to make each have a unique ROMID.
defparam tb_ds1wm.xtc_ds1wm.xow_slave.xiox.p_romid = 64'h9507_6995_0483_5129;
defparam tb_ds1wm.xtc_ds1wm.xxow_slave.xiox.p_romid = 64'h0879_7695_8093_8271;
defparam tb_ds1wm.xtc_ds1wm.xxxow_slave.xiox.p_romid = 64'h2597_5695_5903_8281;
defparam tb_ds1wm.xtc_ds1wm.xxxxow_slave.xiox.p_romid = 64'h0879_7695_3493_8291;


`else
module scoreboard (OWS_ROMID, STPZ);

input [63:0] OWS_ROMID;
`endif

input	     STPZ;
//SWM Added so ow_slave would not pull low the ow when not selected

reg [7:0] exp_cmd_fifo   [0:15];


integer cmd_cnt;

reg [3:0] cmd_fifo_wptr;
reg [3:0] cmd_fifo_rptr;

reg status;
initial begin
   cmd_cnt = 0;
   cmd_fifo_wptr = 0;
   cmd_fifo_rptr = 0;
   status = 1;
end 
//-----------------------

task write_command_fifo (input [7:0] cmd);


begin

   exp_cmd_fifo[cmd_fifo_wptr] = cmd;
   cmd_cnt = cmd_cnt + 1;
   cmd_fifo_wptr = cmd_fifo_wptr + 1;

end

endtask

//-----------------------


task verify_command (input [7:0] cmd);

   reg [7:0] cmd;
begin
   if (cmd != exp_cmd_fifo[cmd_fifo_rptr]) begin
      $display("%t ERROR - Slave detected unexpected command:   expected command = %h, actual command = %h",$time, exp_cmd_fifo[cmd_fifo_rptr], cmd);
      status = 0;
   end
   cmd_cnt = cmd_cnt - 1;
   cmd_fifo_rptr = cmd_fifo_rptr + 1;
      
   
end

endtask

//-----------------------

`ifdef OW_SWITCH

task verify_romid(input [63:0] romid1, input [63:0] romid2, input [63:0] romid3, input [63:0] romid4);

integer romid1_cnt;   	//Make sure there is four distinct ROMIDs
integer romid2_cnt;
integer romid3_cnt;
integer romid4_cnt;

begin
romid1_cnt = 0;
romid2_cnt = 0;
romid3_cnt = 0;
romid4_cnt = 0;

$display("----------------Verifing that one of the four ROMIDs match expected!------------------");

	case(romid1)
	  OWS_ROMID1: begin
	              $display("First ROMID found is %h", OWS_ROMID1);
	              romid1_cnt = romid1_cnt+1;
		      end
	  OWS_ROMID2: begin
	  	      $display("First ROMID found is %h", OWS_ROMID2);
	              romid2_cnt = romid2_cnt+1;
		      end
	  OWS_ROMID3: begin
	              $display("First ROMID found is %h", OWS_ROMID3);
	              romid3_cnt = romid3_cnt+1;
		      end
	  OWS_ROMID4: begin
	              $display("First ROMID found is %h", OWS_ROMID4);
	  	      romid4_cnt = romid4_cnt+1;
		      end
	  default:   begin
	              $display("%t ERROR - Invalid First ROMID  - actual = %h",$time,  romid1);
		      status = 0;
		      end
	endcase
	
	case(romid2)
	  OWS_ROMID1: begin
	              $display("Second ROMID found is %h", OWS_ROMID1);
	              romid1_cnt = romid1_cnt+1;
		      end
	  OWS_ROMID2: begin 
	              $display("Second ROMID found is %h", OWS_ROMID2);
	              romid2_cnt = romid2_cnt+1;
		      end
	  OWS_ROMID3: begin
	              $display("Second ROMID found is %h", OWS_ROMID3);
	              romid3_cnt = romid3_cnt+1;
		      end
	  OWS_ROMID4: begin
	              $display("Second ROMID found is %h", OWS_ROMID4);
	              romid4_cnt = romid4_cnt+1;
		      end
	  default:   begin
	              $display("%t ERROR - Invalid Second ROMID  - actual = %h",$time,  romid2);
		      status = 0;
		      end
	endcase

	case(romid3)
	  OWS_ROMID1: begin
	              $display("Third ROMID found is %h", OWS_ROMID1);
	              romid1_cnt = romid1_cnt+1;
		      end
	  OWS_ROMID2: begin
	              $display("Third ROMID found is %h", OWS_ROMID2);
	              romid2_cnt = romid2_cnt+1;
		      end
	  OWS_ROMID3: begin
	              $display("Third ROMID found is %h", OWS_ROMID3);
	              romid3_cnt = romid3_cnt+1;
		      end
	  OWS_ROMID4: begin
	              $display("Third ROMID found is %h", OWS_ROMID4);
	              romid4_cnt = romid4_cnt+1;
		      end
	  default:   begin
	              $display("%t ERROR - Invalid Third ROMID  - actual = %h",$time,  romid3);
		      status = 0;
		      end
	endcase
   
	case(romid4)
	  OWS_ROMID1: begin
	              $display("Forth ROMID found is %h", OWS_ROMID1);
	              romid1_cnt = romid1_cnt+1;
		      end
	  OWS_ROMID2: begin 
	              $display("Forth ROMID found is %h", OWS_ROMID2);
	              romid2_cnt = romid2_cnt+1;
		      end
	  OWS_ROMID3: begin
	              $display("Forth ROMID found is %h", OWS_ROMID3);
	              romid3_cnt = romid3_cnt+1;
		      end
	  OWS_ROMID4: begin
	              $display("Forth ROMID found is %h", OWS_ROMID4);
	              romid4_cnt = romid4_cnt+1;
		      end
	  default:   begin
	              $display("%t ERROR - Invalid Forth ROMID  - actual = %h",$time,  romid4);
		      status = 0;
		      end
	endcase
   
   if (romid1_cnt!=1)
   begin
   status = 0;
   $display("%t ERROR - There was not four distinct ROMIDs",$time);
   end 
   if (romid2_cnt!=1)
   begin
   status = 0;
   $display("%t ERROR - There was not four distinct ROMIDs",$time);
   end 
   if (romid3_cnt!=1)
   begin
   status = 0;
   $display("%t ERROR - There was not four distinct ROMIDs",$time);
   end    
   if (romid4_cnt!=1)
   begin
   status = 0;
   $display("%t ERROR - There was not four distinct ROMIDs",$time);
   end 
end

endtask

`else

task verify_romid (input [63:0] romid);

begin

   if (romid != OWS_ROMID) begin
      $display("%t ERROR - Invalid ROMID  - expected  = %h, actual = %h",$time,  OWS_ROMID, romid);
      status = 0;
   end
end

endtask

`endif
//-----------------------

task verify_stpz_low;

begin
  if (STPZ == 1) begin
  	$display("%t ERROR - Signal STPZ expected was not set low",$time);
	status = 0;
  end
end

endtask  
	 
//-----------------------

task verify_stpz_high;

begin
  if (STPZ == 0) begin
  	$display("%t ERROR - Signal STPZ expected was not set high",$time);
	status = 0;
  end
end

endtask  

//-----------------------


task report_status();

begin

  if (cmd_cnt > 0) begin
     status = 0;
  end   
     
  $display("------------------------");
     
  if (status ==  1)
     $display("\t Test Passed");
  else    
     $display("\t Test Failed");
     
     
  $display("------------------------");
end
endtask
endmodule
