
TOPLEVEL_LANG = verilog
pwd = $(shell pwd)
VERILOG_SOURCES = \
  $(pwd)/tb.v \
  $(pwd)/read_ds2411.v
TOPLEVEL = tb  # this means the 'tb' in tb.v
MODULE = tb  # this means the 'tb' in tb.py

include $(shell cocotb-config --makefiles)/Makefile.sim
