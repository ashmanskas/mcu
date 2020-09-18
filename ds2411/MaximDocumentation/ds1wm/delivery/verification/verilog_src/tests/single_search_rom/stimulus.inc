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
