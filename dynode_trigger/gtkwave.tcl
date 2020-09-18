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
