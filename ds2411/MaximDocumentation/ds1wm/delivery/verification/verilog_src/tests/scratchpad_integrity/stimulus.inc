task run_owm_sequence;

  
begin
    //---------------------------------------------------------------------------------------------------


    $display("-----------------  SKIP_ROM      ------------------------------------------");
   
    tb_ds1wm.xtc_ds1wm.xcpu_bfm.skip_rom;
    $display("-----------------  END SKIP_ROM  ------------------------------------------");
    $display("\n\n");

    $display("-----------------  WRITE_SP      ------------------------------------------");
    tb_ds1wm.xtc_ds1wm.xcpu_bfm.write_sp;
    tb_ds1wm.xtc_ds1wm.xcpu_bfm.ow_reset;   
    $display("-----------------  END WRITE_SP  ------------------------------------------");
    $display("\n\n");

    
    $display("-----------------  SKIP_ROM      ------------------------------------------");
    tb_ds1wm.xtc_ds1wm.xcpu_bfm.skip_rom;
    $display("-----------------  END SKIP_ROM  ------------------------------------------");
    $display("\n\n");

    $display("-----------------  READ_SP      ------------------------------------------");
    tb_ds1wm.xtc_ds1wm.xcpu_bfm.read_sp;
    tb_ds1wm.xtc_ds1wm.xcpu_bfm.ow_reset;   
    $display("-----------------  END READ_SP  ------------------------------------------");
    $display("\n\n");
   

end

endtask

initial begin:gosim


    
      
    reset;


    
    //  Set Interrupts Active Low 
    
    tb_ds1wm.xtc_ds1wm.xcpu_bfm.set_ias(1'b0);  //Set Interrupts active low
    
    tb_ds1wm.xtc_ds1wm.xcpu_bfm.set_clock_divisor(8'd4);
    run_owm_sequence;
    


    tb_ds1wm.xtc_ds1wm.xcpu_bfm.report_sp_mem_status;
    tb_ds1wm.xtc_ds1wm.xscoreboard.report_status;
    #100;  
    $finish();
end    
