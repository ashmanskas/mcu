
import cocotb
from cocotb.triggers import ClockCycles


class Tester:

    def __init__(self, dut):
        self.dut = dut
        self.verbose = False

    async def wr(self, addr, data, verbose=None):
        """write 'addr' := 'data' on register-file bus"""
        dut = self.dut
        if verbose is None: verbose = self.verbose
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

    async def rd(self, addr, verbose=None):
        """read from regsiter-file bus at address 'addr'"""
        dut = self.dut
        if verbose is None: verbose = self.verbose
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

    async def run_test1(self):
        """initial very simple test of mcu_logic module"""
        dut = self.dut
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
        self.verbose = True
        await self.wr(0x0001, 0x0000)
        d = await self.rd(0x0000); assert d==0x1234
        d = await self.rd(0x0001); assert d==0x0000
        d = await self.rd(0x0000); assert d==0x1234
        await self.wr(0x0001, 0x4321)
        d = await self.rd(0x0000); assert d==0x1234
        d = await self.rd(0x0001); assert d==0x4321

        await ClockCycles(dut.clk, 10)


@cocotb.test()
async def test1(dut):
    """instantiate Tester class then run its test(s)"""
    tester = Tester(dut)
    await tester.run_test1()
