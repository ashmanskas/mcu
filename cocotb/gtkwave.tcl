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
    #tb.rmA1.to_mcu
    #tb.rmB1.to_mcu
    tb.ml.A1in
    tb.ml.B1in 
    tb.ml.A1out 
    tb.ml.B1out 
    tb.ml.coinc.singleA
    tb.ml.coinc.offsetA
    #tb.rmA1.single
    #tb.rmB1.single
    tb.ml.coinc.singleB 
    tb.ml.coinc.offsetB 
    tb.ml.coinc.ncoincA 
    tb.ml.coinc.pcoincA
    tb.ml.coinc.ofsAdel0
    tb.ml.coinc.ofsAdel1
    tb.ml.coinc.ofsAdel2
    tb.ml.coinc.ofsBdel0
    tb.ml.coinc.ofsBdel1
    tb.ml.coinc.ofsBdel2
    tb.ml.coinc.oAd1
    tb.ml.coinc.oBd0
    tb.ml.coinc.0Bd1
    tb.ml.coinc.0Bd2
    tb.ml.coinc.diff0
    tb.ml.coinc.diff1
    tb.ml.coinc.diff2
    tb.ml.coinc.coincdiff
    tb.coinc_t_offset
    #tp.rmA1.ncoinc
    #tp.rmA1.pcoinc
    #tp.rmA1.dcoinc
    tb.ml.coinc.ncoincB 
    tb.ml.coinc.pcoincB 
    #tp.rmB1.ncoinc
    #tp.rmB1.pcoinc
    #tp.rmB1.dcoinc
    tb.ml.A1.badidle
    tb.ml.B1.badidle
    tb.rmA1.badidle
    tb.rmB1.badidle
    tb.rmA1.numsingl
    tb.rmA1.numcoinc
    tb.rmA1.latency
    tb.rmB1.numsingl
    tb.rmB1.numcoinc
    tb.rmB1.latency
    tb.ml.baddr 
    tb.ml.bwr 
    tb.ml.bstrobe 
    tb.ml.bwrdata 
    tb.ml.brddata
    tb.ml.r0001.q
    #tb.ml.spword
    tb.rmA1.spword
    #tb.rmB1.spword
    tb.ml.do_spword
    tb.rmA1.sync_clk
    tb.rmA1.save_clk
    tb.rmA1.runmode
    #tb.rmB1.sync_clk
    #tb.rmB1.save_clk
    #tb.rmB1.runmode
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
