task run_owm_sequence;

begin
    //---------------------------------------------------------------------------------------------------

   
   $display("-----------------  SEARCH_ROM TEST  ------------------------------------------");
    tb_ds1wm.xtc_ds1wm.xcpu_bfm.search_rom;
    ROMID1=ROMID;
      $display("%t CPU      - ROM ID found = %0h ",$time, ROMID1);
    tb_ds1wm.xtc_ds1wm.xcpu_bfm.search_rom;
    ROMID2=ROMID;
     $display("%t CPU      - ROM ID found = %0h ",$time, ROMID2);
    tb_ds1wm.xtc_ds1wm.xcpu_bfm.search_rom;
    ROMID3=ROMID;
     $display("%t CPU      - ROM ID found = %0h ",$time, ROMID3);
    tb_ds1wm.xtc_ds1wm.xcpu_bfm.search_rom;
    ROMID4=ROMID; 
     $display("%t CPU      - ROM ID found= %0h ",$time, ROMID4);       
    tb_ds1wm.xtc_ds1wm.xscoreboard.verify_romid(ROMID1, ROMID2, ROMID3, ROMID4);
    $display("-----------------  END SEARCH_ROM TEST------------------------------------------");
    $display("\n\n");
    

   //-----------------------------------------------------------------------------------------------
end

endtask

initial begin:gosim


    
      
    reset;


    
    //  Set Interrupts Active Low 
    
    tb_ds1wm.xtc_ds1wm.xcpu_bfm.set_ias(1'b0);  //Set Interrupts active low
    

    tb_ds1wm.xtc_ds1wm.xcpu_bfm.set_clock_divisor(8'd4);
    run_owm_sequence;
    


    tb_ds1wm.xtc_ds1wm.xscoreboard.report_status;
    #100;  
    $finish();
end    
