
TOPLEVEL_LANG = verilog
pwd = $(shell pwd)
VERILOG_SOURCES = \
  $(pwd)/tb.v \
  $(pwd)/mcu_logic.v \
  $(pwd)/rocstar_mcu_link.v
TOPLEVEL = tb  # this means the 'tb' in tb.v
MODULE = tb  # this means the 'tb' in tb.py

include $(shell cocotb-config --makefiles)/Makefile.sim
