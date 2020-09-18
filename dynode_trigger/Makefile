
TOPLEVEL_LANG = verilog
pwd = $(shell pwd)
VERILOG_SOURCES = \
  $(pwd)/tb.v \
  $(pwd)/dynode_trigger.v \
  $(pwd)/dynode_trigger_roger_version.v \
  $(pwd)/dynode_baseline.v \
  $(pwd)/dynode_eventdet.v \
  $(pwd)/dynode_integrate.v \
  $(pwd)/dynode_pileup.v
TOPLEVEL = tb  # this means the 'tb' in tb.v
MODULE = tb  # this means the 'tb' in tb.py

include $(shell cocotb-config --makefiles)/Makefile.sim
