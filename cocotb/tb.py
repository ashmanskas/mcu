
import cocotb
from cocotb.triggers import ClockCycles

async def wr(dut, addr, data, verbose=False):
    """write 'addr' := 'data' on register-file bus"""
    await ClockCycles(dut.clk, 1, rising=False)
    dut.baddr <= addr
    dut.bwrdata <= data
    dut.bwr <= 1
    dut.bstrobe <= 1
    await ClockCycles(dut.clk, 1, rising=False)
    dut.baddr <= 0
    dut.bwrdata <= 0
    dut.bwr <= 0
    dut.bstrobe <= 0
    await ClockCycles(dut.clk, 1, rising=False)
    if verbose:
        print("wr {:04x} := {:04x}".format(addr, data))

async def rd(dut, addr, verbose=False):
    """read from regsiter-file bus at address 'addr'"""
    await ClockCycles(dut.clk, 1, rising=False)
    dut.baddr <= addr
    dut.bwr <= 0
    dut.bstrobe <= 0
    await ClockCycles(dut.clk, 1, rising=False)
    dut.bstrobe <= 1
    await ClockCycles(dut.clk, 1, rising=False)
    data = dut.brddata.value.integer
    dut.bstrobe <= 0
    dut.baddr <= 0
    await ClockCycles(dut.clk, 1, rising=False)
    if verbose:
        print("rd {:04x} -> {:04x}".format(addr, data))
    return data

@cocotb.test()
async def test1(dut):
    """put description here"""

    # From cocotb's perspective, our 'tb' verilog module is the 'dut',
    # even though from our perspective the actual D.U.T. is the
    # 'mcu_logic' module instantiated therein.
    ml = dut.ml

    # Wait a while, then reset, then wait a while
    await ClockCycles(dut.clk, 20, rising=False)
    dut.ml.rst <= 1
    await ClockCycles(dut.clk, 1, rising=False)
    dut.ml.rst <= 0
    await ClockCycles(dut.clk, 10, rising=False)

    # Let everything run for a while
    await ClockCycles(dut.clk, 100)

    # Try some register-file "bus" I/O
    d = await rd(dut, 0x0000, verbose=True)
    d = await rd(dut, 0x0001, verbose=True)
    d = await rd(dut, 0x0000, verbose=True)
    d = await wr(dut, 0x0001, 0x4321, verbose=True)
    d = await rd(dut, 0x0000, verbose=True)
    d = await rd(dut, 0x0001, verbose=True)
    
    
