#!/bin/csh

rm -rf worklib
mkdir worklib

rm -rf logs
mkdir logs



###################Use for VHDL core simulation##########################
ncvhdl  -work worklib -V93 -f design_vhdl_src_files.lst -log logs/ncvhdl.log

##################Use for Verilog core simulation########################
#ncvlog  -work worklib -f design_verilog_src_files.lst -log logs/ncverilog.log

########################################################################
ncvlog  -work worklib -incdir ../. -f  tb_src_files.lst -log logs/ncvlog.log
ncelab  -work worklib tb_ds1wm -log logs/ncelab.log
ncsim   -messages tb_ds1wm -log logs/ncsim.log
