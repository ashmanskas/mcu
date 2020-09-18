
import cocotb
import inspect
import os
import random

from collections import deque
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
            info.lineno, info.code_context[0].strip())
        # https://stackoverflow.com/questions/6810999/
        #   how-to-determine-file-function-and-line-number
        ns = self.ns()
        print("CHECKFAIL@{:.0f}:".format(ns), where)

    def ns(self):
        """return current simulation time in nanoseconds"""
        return cocotb.utils.get_sim_time(units="ns")
        
    async def wclk(self, nclk=1, rising=True):
        """shortcut for await ClockCycles(self.dut.clk, ...)"""
        await cocotb.triggers.ClockCycles(self.dut.clk, nclk, rising=rising)

                
    async def run_test1(self):
        """initial very simple test of dynode_trigger module"""
        dut = self.dut
        # From cocotb's perspective, our 'tb' verilog module is the 'dut',
        # even though from our perspective the actual D.U.T. is the
        # 'read_adt7320' module instantiated therein.
        dt = dut.dt

        # Wait a while, then reset, then wait a while
        await self.wclk(20)
        dut.reset <= 1
        await self.wclk()
        dut.reset <= 0
        await self.wclk()
        dut.reset <= 1
        await self.wclk(1000)


        print("checks: {} ok, {} failed".format(
            self.nchecks_ok, self.nchecks_failed))
        if self.nchecks_failed:
            raise cocotb.result.TestFailure(
                "failed {} checks".format(self.nchecks_failed))


@cocotb.test()
async def test1(dut):
    """instantiate Tester class then run its test(s)"""
    tester = Tester(dut)
    await tester.run_test1()
