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
    tb.dt.clk
    tb.dt.reset
    tb.baddr
    tb.bwr
    tb.bwrdata
    tb.brddata
    tb.dt.single
    tb.dt.offset
    tb.pycount
    tb.dt.diff0
    tb.dt.diff0_inverse
    tb.dt.diff0_inverse_w
    tb.dt.diff1
    tb.dt.energy_thresh_high
    tb.dt.energy_thresh_low
    tb.dt.found_max_tick
    tb.dt.found_timing_value
    tb.dt.increasing
    tb.dt.increasing_d
    tb.dt.max_val
    tb.dt.over_thresh
    tb.dt.over_thresh_d
    tb.dt.over_thresh_tick
    tb.dt.timeout_counter
    tb.dt.timing_data
    tb.dt.timing_data_d
    tb.dt.timing_latch
    tb.dt.timing_latch_counter
    tb.dt.timing_pickoff_level
    tb.dt.timing_value
    tb.dt.timing_value_large
    tb.dt.value_above
    tb.dt.value_below
}
gtkwave::addSignalsFromList $siglist
gtkwave::presentWindow
gtkwave::setZoomRangeTimes 0 [gtkwave::getMaxTime]
