
TOPLEVEL_LANG = verilog
pwd = $(shell pwd)
VERILOG_SOURCES = \
  $(pwd)/tb.v \
  $(pwd)/ds1wm.v  \
  $(pwd)/onewiremaster.v \
  $(pwd)/one_wire_interface.v \
  $(pwd)/one_wire_io.v \
  $(pwd)/clk_prescaler.v
TOPLEVEL = tb  # this means the 'tb' in tb.v
MODULE = tb  # this means the 'tb' in tb.py

include $(shell cocotb-config --makefiles)/Makefile.sim
