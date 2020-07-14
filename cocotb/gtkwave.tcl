gtkwave::loadFile tb.lxt
gtkwave::forceOpenTreeNode tb.ml
set nfacs [gtkwave::getNumFacs]
for {set i 0} {$i < $nfacs} {incr i} {
    set facname [gtkwave::getFacName $i]
    puts "$i : $facname"
}
set siglist {
    tb.ml.A1in 
    tb.ml.A1out 
    tb.ml.B1in 
    tb.ml.B1out 
    tb.ml.baddr 
    tb.ml.brddata 
    tb.ml.bwrdata 
    tb.ml.bstrobe 
    tb.ml.bwr 
    tb.ml.clk 
    tb.ml.rst 
    tb.ml.coinc.singleA 
    tb.ml.coinc.singleB 
    tb.ml.coinc.ncoincA 
    tb.ml.coinc.pcoincA 
    tb.ml.coinc.ncoincB 
    tb.ml.coinc.pcoincB 
}
gtkwave::addSignalsFromList $siglist
gtkwave::presentWindow
gtkwave::setZoomRangeTimes 0 [gtkwave::getMaxTime]
