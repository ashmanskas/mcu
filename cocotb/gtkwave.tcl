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
    tb.ml.A1in 
    tb.ml.B1in 
    tb.ml.A1out 
    tb.ml.B1out 
    tb.ml.coinc.singleA 
    tb.ml.coinc.singleB 
    tb.ml.coinc.ncoincA 
    tb.ml.coinc.pcoincA 
    tb.ml.coinc.ncoincB 
    tb.ml.coinc.pcoincB 
    tb.ml.baddr 
    tb.ml.bwr 
    tb.ml.bstrobe 
    tb.ml.bwrdata 
    tb.ml.brddata
    tb.ml.r0001.q
    tb.ml.spword
    tb.ml.do_spword
    tb.clkcnt_A1[7:0]
    tb.clkcnt_B1[7:0]
    tb.clksav_A1[15:0]
    tb.clksav_B1[15:0]
}
gtkwave::addSignalsFromList $siglist
gtkwave::presentWindow
gtkwave::setZoomRangeTimes 0 [gtkwave::getMaxTime]
