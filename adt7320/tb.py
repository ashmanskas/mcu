
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

    async def adt7320_emulator(self):
        """emulate one ADT7320 chip"""
        IDLE = 0
        CMD = 1
        CMD1 = 2
        PRERESP = 3
        RESP = 4
        RESP1 = 5
        POSTRESP = 6
        ra = self.dut.ra
        # Create a place to store this coroutine's internal state, so
        # that it can be accessed from the enclosing 'Tester'
        # instance.  I'll give it the absurdly short name 'o' (short
        # for "object") to avoid clutter below.
        o = SimpleNamespace()
        o.state = IDLE
        o.count = 0
        o.cmd = 0
        while True:
            await self.wclk()  # This loop executes once per clk cycle
            if o.state==IDLE:
                ra.dout <= 1
                if ra.cs.value.integer == 0:
                    o.state = CMD
                    o.count = 0
                    o.cmd = 0
            elif o.state==CMD:
                ra.dout <= 0
                if ra.sclk.value.integer == 0:
                    o.state = CMD1
                    o.count += 1
            elif o.state==CMD1:
                if ra.sclk.value.integer == 1:
                    o.cmd = (o.cmd<<1) | ra.din.value.integer
                    if o.count==8:
                        o.state = PRERESP
                    else:
                        o.state = CMD
            elif o.state==PRERESP:
                o.respout = 0
                r_wbar = o.cmd>>6 & 1
                addr = o.cmd>>3 & 7
                if r_wbar and addr==0:
                    # status
                    o.respout = 0x8000
                    o.state = RESP
                elif r_wbar and addr==1:
                    # config
                    o.respout = 0x0000
                    o.state = RESP
                elif r_wbar and addr==2:
                    # temperature
                    o.respout = 0x1234
                    o.state = RESP
                elif r_wbar and addr==3:
                    # id
                    o.respout = 0xc300
                    o.state = RESP
                else:
                    o.state = IDLE
            elif o.state==RESP:
                if ra.sclk.value.integer == 0:
                    ra.dout <= o.respout>>15 & 1
                    o.state = RESP1
                    o.count += 1
            elif o.state==RESP1:
                if ra.sclk.value.integer == 1:
                    o.respout = (o.respout << 1) & 0xffff
                    if o.count==24:
                        o.state = POSTRESP
                    else:
                        o.state = RESP
            elif o.state==POSTRESP:
                o.count += 1
                if o.count==100:
                    o.state = IDLE
                
    async def run_test1(self):
        """initial very simple test of read_adt7320 module"""
        dut = self.dut
        # From cocotb's perspective, our 'tb' verilog module is the 'dut',
        # even though from our perspective the actual D.U.T. is the
        # 'read_adt7320' module instantiated therein.
        ra = dut.ra

        # Wait a while, then reset, then wait a while
        await self.wclk(20)
        dut.reset <= 1
        await self.wclk()
        dut.reset <= 0
        await self.wclk(10)

        # Instantiate emulated ADT7320 chip
        self.adt7320 = cocotb.fork(self.adt7320_emulator())

        await self.wclk(10000)
        
        # Now kill off the coroutines we forked earlier
        self.adt7320.kill()
        await self.wclk(5)

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
