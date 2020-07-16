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
    tb.ml.clk 
    tb.ml.rst 
    tb.rmA1.to_mcu
    tb.rmB1.to_mcu
    tb.ml.A1in
    tb.ml.B1in 
    tb.ml.A1out 
    tb.ml.B1out 
    tb.ml.coinc.singleA
    tb.rmA1.single
    tb.rmB1.single
    tb.ml.coinc.singleB 
    tb.ml.coinc.ncoincA 
    tb.ml.coinc.pcoincA
    tp.rmA1.ncoinc
    tp.rmA1.pcoinc
    tp.rmA1.dcoinc
    tb.ml.coinc.ncoincB 
    tb.ml.coinc.pcoincB 
    tp.rmB1.ncoinc
    tp.rmB1.pcoinc
    tp.rmB1.dcoinc
    tb.ml.baddr 
    tb.ml.bwr 
    tb.ml.bstrobe 
    tb.ml.bwrdata 
    tb.ml.brddata
    tb.ml.r0001.q
    tb.ml.spword
    tb.rmA1.spword
    tb.rmB1.spword
    tb.ml.do_spword
    tb.rmA1.sync_clk
    tb.rmA1.save_clk
    tb.rmA1.runmode
    tb.rmB1.sync_clk
    tb.rmB1.save_clk
    tb.rmB1.runmode
    tb.clkcnt_A1[7:0]
    tb.clkcnt_B1[7:0]
    tb.clksav_A1[15:0]
    tb.clksav_B1[15:0]
    tb.rmA1.fsm
    tb.rmB1.fsm
}
gtkwave::addSignalsFromList $siglist
gtkwave::presentWindow
gtkwave::setZoomRangeTimes 0 [gtkwave::getMaxTime]
