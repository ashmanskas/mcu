task run_owm_sequence;

begin
    //---------------------------------------------------------------------------------------------------

   
   $display("-----------------  SEARCH_ROM      ------------------------------------------");
    tb_ds1wm.xtc_ds1wm.xcpu_bfm.search_rom;
          $display("%t CPU      - ROM ID = %0h ",$time, ROMID);
    tb_ds1wm.xtc_ds1wm.xscoreboard.verify_romid(ROMID);
    $display("-----------------  END SEARCH_ROM  ------------------------------------------");
    $display("\n\n");
    
    
   //-----------------------------------------------------------------------------------------------

    $display("-----------------  OD_SKIP_ROM      ------------------------------------------");
   
    tb_ds1wm.xtc_ds1wm.xcpu_bfm.od_skip_rom;
    $display("-----------------  END OD_SKIP_ROM  ------------------------------------------");
    $display("\n\n");

    $display("-----------------  WRITE_SP      ------------------------------------------");
    tb_ds1wm.xtc_ds1wm.xcpu_bfm.write_sp;
    $display("-----------------  END WRITE_SP  ------------------------------------------");
    $display("\n\n");

    //---------------------------------------------------------------------------------------------------
    
    
    $display("-----------------  SKIP_ROM      ------------------------------------------");
    tb_ds1wm.xtc_ds1wm.xcpu_bfm.skip_rom;
    $display("-----------------  END SKIP_ROM  ------------------------------------------");
    $display("\n\n");

    $display("-----------------  READ_SP      ------------------------------------------");
    tb_ds1wm.xtc_ds1wm.xcpu_bfm.read_sp;
    $display("-----------------  END READ_SP  ------------------------------------------");
    $display("\n\n");

    $display("-----------------  RESET TO STD      ------------------------------------------");
    tb_ds1wm.xtc_ds1wm.xcpu_bfm.ow_reset_to_std;
    $display("-----------------  END RESET TO STD  ------------------------------------------");
    $display("\n\n");

    //---------------------------------------------------------------------------------------------------
    
    
    $display("-----------------  OD_MATCH_ROM  ------------------------------------------");
    tb_ds1wm.xtc_ds1wm.xcpu_bfm.od_match_rom(ROMID);
    $display("-----------------  END MATCH_ROM  ------------------------------------------");
    $display("\n\n");

    $display("-----------------  WRITE_SP      ------------------------------------------");
    tb_ds1wm.xtc_ds1wm.xcpu_bfm.write_sp;
    $display("-----------------  END WRITE_SP  ------------------------------------------");
    $display("\n\n");

 
     $display("-----------------  MATCH_ROM  ------------------------------------------");
    tb_ds1wm.xtc_ds1wm.xcpu_bfm.match_rom(ROMID);
    $display("-----------------  END MATCH_ROM  ------------------------------------------");
    $display("\n\n");

    $display("-----------------  READ_SP      ------------------------------------------");
    tb_ds1wm.xtc_ds1wm.xcpu_bfm.read_sp;
    $display("-----------------  END READ_SP  ------------------------------------------");
    $display("\n\n");
 
    $display("-----------------  RESET TO STD      ------------------------------------------");
    tb_ds1wm.xtc_ds1wm.xcpu_bfm.ow_reset_to_std;
    $display("-----------------  END RESET TO STD  ------------------------------------------");
    $display("\n\n");

                     
    //---------------------------------------------------------------------------------------------------

    $display("-----------------  SKIP_ROM      ------------------------------------------");
   
    tb_ds1wm.xtc_ds1wm.xcpu_bfm.skip_rom;
    $display("-----------------  END SKIP_ROM  ------------------------------------------");
    $display("\n\n");

    $display("-----------------  WRITE_SP      ------------------------------------------");
    tb_ds1wm.xtc_ds1wm.xcpu_bfm.write_sp;
    $display("-----------------  END WRITE_SP  ------------------------------------------");
    $display("\n\n");


    //---------------------------------------------------------------------------------------------------
    
    
    $display("-----------------  SKIP_ROM      ------------------------------------------");
    tb_ds1wm.xtc_ds1wm.xcpu_bfm.skip_rom;
    $display("-----------------  END SKIP_ROM  ------------------------------------------");
    $display("\n\n");

    $display("-----------------  READ_SP      ------------------------------------------");
    tb_ds1wm.xtc_ds1wm.xcpu_bfm.read_sp;
    $display("-----------------  END READ_SP  ------------------------------------------");
    $display("\n\n");
    
    //---------------------------------------------------------------------------------------------------
    
    $display("-----------------  SKIP_ROM      ------------------------------------------");
    tb_ds1wm.xtc_ds1wm.xcpu_bfm.skip_rom;
    $display("-----------------  END SKIP_ROM  ------------------------------------------");
    $display("\n\n");

    $display("-----------------  COPY_SP      ------------------------------------------");
    tb_ds1wm.xtc_ds1wm.xcpu_bfm.copy_sp;
    $display("-----------------  END COPY_SP  ------------------------------------------");
    $display("\n\n");

    //---------------------------------------------------------------------------------------------------

    
    $display("-----------------  SKIP_ROM      ------------------------------------------");
    tb_ds1wm.xtc_ds1wm.xcpu_bfm.skip_rom;
    $display("-----------------  END SKIP_ROM  ------------------------------------------");
    $display("\n\n");

    $display("-----------------  READ_MEM      ------------------------------------------");
    tb_ds1wm.xtc_ds1wm.xcpu_bfm.read_mem;
    $display("-----------------  END READ_MEM  ------------------------------------------");
    $display("\n\n");
    
    //---------------------------------------------------------------------------------------------------

    
    $display("-----------------  READ_ROM      ------------------------------------------");
   
    tb_ds1wm.xtc_ds1wm.xcpu_bfm.read_rom;
    tb_ds1wm.xtc_ds1wm.xscoreboard.verify_romid(ROMID);
    $display("-----------------  END READ_ROM  ------------------------------------------");
    $display("\n\n");

    $display("-----------------  WRITE_SP      ------------------------------------------");
    tb_ds1wm.xtc_ds1wm.xcpu_bfm.write_sp;
    $display("-----------------  END WRITE_SP  ------------------------------------------");
    $display("\n\n");

    //---------------------------------------------------------------------------------------------------
    
    $display("-----------------  READ_ROM      ------------------------------------------");
    tb_ds1wm.xtc_ds1wm.xcpu_bfm.read_rom;
    tb_ds1wm.xtc_ds1wm.xscoreboard.verify_romid(ROMID);
    $display("-----------------  END READ_ROM  ------------------------------------------");
    $display("\n\n");

    $display("-----------------  READ_SP      ------------------------------------------");
    tb_ds1wm.xtc_ds1wm.xcpu_bfm.read_sp;
    $display("-----------------  END READ_SP  ------------------------------------------");
    $display("\n\n");

    //---------------------------------------------------------------------------------------------------


    $display("-----------------  READ_ROM      ------------------------------------------");
   
    tb_ds1wm.xtc_ds1wm.xcpu_bfm.read_rom;
    tb_ds1wm.xtc_ds1wm.xscoreboard.verify_romid(ROMID);
    $display("-----------------  END READ_ROM  ------------------------------------------");
    $display("\n\n");

    $display("-----------------  COPY_SP      ------------------------------------------");
    tb_ds1wm.xtc_ds1wm.xcpu_bfm.copy_sp;
    $display("-----------------  END COPY_SP  ------------------------------------------");
    $display("\n\n");


    //---------------------------------------------------------------------------------------------------


    
    $display("-----------------  READ_ROM      ------------------------------------------");
    tb_ds1wm.xtc_ds1wm.xcpu_bfm.read_rom;
    tb_ds1wm.xtc_ds1wm.xscoreboard.verify_romid(ROMID);
    $display("-----------------  END READ_ROM  ------------------------------------------");
    $display("\n\n");

    $display("-----------------  READ_MEM      ------------------------------------------");
    tb_ds1wm.xtc_ds1wm.xcpu_bfm.read_mem;
    $display("-----------------  END READ_MEM  ------------------------------------------");
    $display("\n\n");



   //-----------------------------------------------------------------------------------------------
end

endtask

initial begin:gosim


    
      
    reset;


    
    //  Set Interrupts Active Low 
    
    tb_ds1wm.xtc_ds1wm.xcpu_bfm.set_ias(1'b0);  //Set Interrupts active low
    

    tb_ds1wm.xtc_ds1wm.xcpu_bfm.set_clock_divisor(8'd4);
    $display("\n\n");
    $display("-----------------  START TEST STRONG PULLUP -----------------------------------------");    
    tb_ds1wm.xtc_ds1wm.xcpu_bfm.test_stpz;
    $display("-----------------  END TEST STRONG PULLUP  ------------------------------------------");     
    $display("\n\n");
    run_owm_sequence;
    
    tb_ds1wm.xtc_ds1wm.xcpu_bfm.set_clock_divisor(8'd5);
    run_owm_sequence;
    
    tb_ds1wm.xtc_ds1wm.xcpu_bfm.set_clock_divisor(8'd6);
    run_owm_sequence;
    
    tb_ds1wm.xtc_ds1wm.xcpu_bfm.set_clock_divisor(8'd7);
    run_owm_sequence;
    
    tb_ds1wm.xtc_ds1wm.xcpu_bfm.set_clock_divisor(8'd8);
    run_owm_sequence;
    
    tb_ds1wm.xtc_ds1wm.xcpu_bfm.set_clock_divisor(8'd10);
    run_owm_sequence;
    
    
    tb_ds1wm.xtc_ds1wm.xcpu_bfm.set_clock_divisor(8'd12);
    run_owm_sequence;
    
    tb_ds1wm.xtc_ds1wm.xcpu_bfm.set_clock_divisor(8'd14);
    run_owm_sequence;
    
    tb_ds1wm.xtc_ds1wm.xcpu_bfm.set_clock_divisor(8'd16);
    run_owm_sequence;




    //  Set Interrupts Active High 


    tb_ds1wm.xtc_ds1wm.xcpu_bfm.set_ias(1'b1);  //Set Interrupts active high
    
    tb_ds1wm.xtc_ds1wm.xcpu_bfm.set_clock_divisor(8'd20);
    run_owm_sequence;
    
    tb_ds1wm.xtc_ds1wm.xcpu_bfm.set_clock_divisor(8'd24);
    run_owm_sequence;
    
    tb_ds1wm.xtc_ds1wm.xcpu_bfm.set_clock_divisor(8'd28);
    run_owm_sequence;
    
    tb_ds1wm.xtc_ds1wm.xcpu_bfm.set_clock_divisor(8'd32);
    run_owm_sequence;
    
    tb_ds1wm.xtc_ds1wm.xcpu_bfm.set_clock_divisor(8'd40);
    run_owm_sequence;
    
    tb_ds1wm.xtc_ds1wm.xcpu_bfm.set_clock_divisor(8'd48);
    run_owm_sequence;
    
    tb_ds1wm.xtc_ds1wm.xcpu_bfm.set_clock_divisor(8'd56);
    run_owm_sequence;
    
    tb_ds1wm.xtc_ds1wm.xcpu_bfm.set_clock_divisor(8'd64);
    run_owm_sequence;
    
    tb_ds1wm.xtc_ds1wm.xcpu_bfm.set_clock_divisor(8'd80);
    run_owm_sequence;
    
    tb_ds1wm.xtc_ds1wm.xcpu_bfm.set_clock_divisor(8'd96);
    run_owm_sequence;
    
    tb_ds1wm.xtc_ds1wm.xcpu_bfm.set_clock_divisor(8'd112);
    run_owm_sequence;


    tb_ds1wm.xtc_ds1wm.xcpu_bfm.report_sp_mem_status;
    tb_ds1wm.xtc_ds1wm.xscoreboard.report_status;
    #100;  
    $finish();
end    
