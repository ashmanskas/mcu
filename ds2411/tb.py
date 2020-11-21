import cocotb
import inspect
import os

from types import SimpleNamespace

class Tester:

    def __init__(self, dut):
        self.dut = dut
        self.verbose = False
        self.nchecks_ok = 0
        self.nchecks_failed = 0

    def check(self, expr):
        if expr:
            self.nchecks_ok += 1
            return
        self.nchecks_failed += 1
        callerframerecord = inspect.stack()[1]
        frame = callerframerecord[0]
        info = inspect.getframeinfo(frame)
        where = "{}:{}:{} :: {}".format(
            info.function, os.path.basename(info.filename),
            info.lineno, info.code_context[0].strip()
        )
        ns = self.ns()
        print("CHECKFAIL@{:.0f}".format(ns), where)

    def ns(self):
        """return current simulation time in nanoseconds"""
        return cocotb.utils.get_sim_time(units="ns")

    async def wclk(self, nclk = 1, rising = True):
        """shortcut for await ClockCycles"""
        await cocotb.triggers.ClockCycles(self.dut.clk, nclk, rising = rising)

    async def run_test(self):
        dut = self.dut
        dt = dut.rd2411

        await self.wclk(1000)

        dut.go <= 1;

        await self.wclk(80000)
        dut.din <= 0;
        await self.wclk(1000)
        dut.din <= 1;
        await cocotb.triggers.Edge(dt.smtm)
        await cocotb.triggers.Edge(dt.smtm)

        await cocotb.triggers.Edge(dut.din)
        await cocotb.triggers.Edge(dut.din)
        dut.din <= 0;
        await self.wclk()

        print("checks: {} ok, {} failed".format(
            self.nchecks_ok, self.nchecks_failed))
        if self.nchecks_failed:
            raise cocotb.result.TestFailure(
                "failed {} checks".format(self.nchecks_failed))


@cocotb.test()
async def tests(dut):
    """instantiate Tester class then run its test(s)"""
    tester = Tester(dut)
    await tester.run_test()
