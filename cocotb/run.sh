if [ -e $HOME/.local/bin/cocotb-config ]; then 
  export PATH=$HOME/.local/bin:$PATH; 
fi
export COCOTB_REDUCED_LOG_FMT=1
export PYTHONDONTWRITEBYTECODE=1
export IVERILOG_DUMPER=lxt2
make
