gtkwave::loadFile tb.lxt
gtkwave::forceOpenTreeNode tb.ml
set nfacs [gtkwave::getNumFacs]
set fp [open signames.txt w]
for {set i 0} {$i < $nfacs} {incr i} {
    set facname [gtkwave::getFacName $i]
    puts "$i : $facname"
    puts $fp $facname
}
close $fp
set siglist {
    tb.dtr.timcnt
    tb.dtr.dynadcdly
    tb.dtr.selecttime
    tb.dtr.smoothpmt
    tb.dtr.integcntl
    
    tb.dtr.data_in
    tb.dtr.MCU_trigger_out
    tb.dtr.event_trigger_out
    tb.dtr.event_time_out
    tb.dtr.enecor_load
    tb.dtr.dyn_evntim
    tb.dtr.pulookup
    tb.dtr.dyn_enecor
    tb.dtr.adc_delay
    tb.dtr.sum_integ

    tb.dtr.dyn_indet_sig
    tb.dtr.dyn_event_sig
    tb.dtr.dyn_pileup_sig
    tb.dtr.dyn_data_in_sig
    tb.dtr.dyn_blcor_sig
    tb.dtr.dyn_adcdly_sig
    tb.dtr.dyn_curval_sig
    tb.dtr.evntim_sig
    tb.dtr.dyn_pudump_sig
    tb.dtr.dyn_energy_sig
    tb.dtr.dyn_ingcnt_sig
    tb.dtr.ene_load_sig
    tb.dtr.dyn_evntim_sig
    tb.dtr.enecor_load_sig
    tb.dtr.dynadc_dly_sig

    tb.dtr.dynbl.stopbl
    tb.dtr.dynbl.eventpresent
    tb.dtr.dynbl.currentvalue
    tb.dtr.dynbl.enesum
    tb.dtr.dynbl.ene4sum[0]
    tb.dtr.dynbl.ene4sum[1]
    tb.dtr.dynbl.ene4sum[2]
    tb.dtr.dynbl.ene4sum[3]
    tb.dtr.dynbl.newvalue
    tb.dtr.dynbl.dyn_blcor
    tb.dtr.dynbl.dyn_blcor[11:4]

    tb.dtr.dyned.selecttime
    tb.dtr.dyned.smoothpmt
    tb.dtr.dyned.dyn_indet
    tb.dtr.dyned.dyn_event
    tb.dtr.dyned.dyn_pileup
    tb.dtr.dyned.dyn_pudump
    tb.dtr.dyned.evntim
    tb.dtr.dyned.dynblcor_d[0]
    tb.dtr.dyned.dynblcor_d[1]
    tb.dtr.dyned.dynblcor_d[2]
    tb.dtr.dyned.enesmo
    tb.dtr.dyned.enesmo_d[0]
    tb.dtr.dyned.enesmo_d[1]
    tb.dtr.dyned.enesmo_d[2]
    tb.dtr.dyned.enesmo_d[3]
    tb.dtr.dyned.enesmo_d[4]
    tb.dtr.dyned.enesmo_d[5]
    tb.dtr.dyned.enesmo_d[6]
    tb.dtr.dyned.enesmo_d[7]
    tb.dtr.dyned.enesmo_d[8]
    tb.dtr.dyned.enesmo_d[9]
    tb.dtr.dyned.enesmo_d[10]
    tb.dtr.dyned.enesmo_d[11]
    tb.dtr.dyned.enesmo_d[12]
    tb.dtr.dyned.enesmo_d[13]
    tb.dtr.dyned.enesmo_d[14]
    tb.dtr.dyned.enesmo_d[15]
    tb.dtr.dyned.indet
    tb.dtr.dyned.enefd
    tb.dtr.dyned.enefd_d
    tb.dtr.dyned.enesd
    tb.dtr.dyned.enesd_d
    tb.dtr.dyned.enesd_p
    tb.dtr.dyned.enesd_n
    tb.dtr.dyned.enesd_dif
    tb.dtr.dyned.evnt_timsd
    tb.dtr.dyned.piledet
    tb.dtr.dyned.evnt
    tb.dtr.dyned.pileup
    tb.dtr.dyned.pucnt
    tb.dtr.dyned.pudmp
    tb.dtr.dyned.sd_evnttim
    tb.dtr.dyned.cfd_evnttim
    tb.dtr.dyned.sel_evnttim
    tb.dtr.dyned.evnten
    tb.dtr.dyned.fden
    tb.dtr.dyned.sden
    tb.dtr.dyned.sd_timfrac
    tb.dtr.dyned.sd_timadj
    tb.dtr.dyned.sd_delay
    tb.dtr.dyned.sdneg
    tb.dtr.dyned.sd_delt
    tb.dtr.dyned.smed
    tb.dtr.dyned.smtm
    tb.dtr.dyned.invrt_delt
    tb.dtr.dyned.cfd_dif
    tb.dtr.dyned.cfd_delt
    tb.dtr.dyned.invrtcfd_deltw
    
    tb.pycount
    tb.baddr
    tb.bwr
    tb.bwrdata
    tb.brddata
    tb.dt.clk
    tb.dt.reset
    tb.adcdat
    tb.dt.energy_thresh_low
    tb.dt.energy_thresh_high
    tb.dt.over_thresh_tick
    tb.dt.over_thresh_d
    tb.dt.data_in
    tb.dt.data_in_d
    tb.dt.data_in_dd
    tb.dt.increasing
    tb.dt.increasing_d
    tb.dt.max_val
    tb.dt.found_max_tick
    tb.dt.timing_pickoff_level
    tb.dt.data_delay[0]
    tb.dt.data_delay[1]
    tb.dt.data_delay[2]
    tb.dt.data_delay[3]
    tb.dt.data_delay[4]
    tb.dt.data_delay[5]
    tb.dt.data_delay[6]
    tb.dt.data_delay[7]
    tb.dt.data_delay[8]
    tb.dt.data_delay[9]
    tb.dt.timing_data
    tb.dt.timing_data_d
    tb.dt.value_above
    tb.dt.value_below
    tb.dt.found_timing_value
    tb.dt.timing_value_large
    tb.dt.timing_value
    tb.dt.diff0
    tb.dt.diff0_inverse
    tb.dt.diff0_inverse_w
    tb.dt.diff1
    tb.dt.timing_latch
    tb.dt.over_thresh
    tb.dt.timeout_counter
    tb.dt.timing_latch_counter
    tb.dt.single
    tb.dt.offset
}
gtkwave::addSignalsFromList $siglist
gtkwave::presentWindow
gtkwave::setZoomRangeTimes 0 [gtkwave::getMaxTime]
