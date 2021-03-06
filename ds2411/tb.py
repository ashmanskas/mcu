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

    async def send_one(self):
        await cocotb.triggers.Edge(self.dut.din)
        await cocotb.triggers.Edge(self.dut.din)

    async def send_zero(self):
        await cocotb.triggers.Edge(self.dut.din)
        await cocotb.triggers.Edge(self.dut.din)
        self.dut.din <= 0;
        await self.wclk(9000)
        self.dut.din <= 1;

    async def ROM_zeroes(self):
        for i in range (64):
            await self.send_zero()
            await self.wclk(10)

    async def ROM_zero_one_alternating(self):
        for i in range (32):
            await self.send_zero()
            await self.wclk(10)
            await self.send_one()
            await self.wclk(10)

    async def ROM_like_expected(self):
        ## This test is sent the wrong way round
        ## Sample CRC byte
        for i in range (4):
            await self.send_zero()
            await self.wclk(10)
            await self.send_one()
            await self.wclk(10)

        ## Sample serial code (6 bytes)
        for i in range(12):
            await self.send_zero()
            await self.wclk(10)
            await self.send_one()
            await self.wclk(10)
            await self.send_one()
            await self.wclk(10)
            await self.send_zero()
            await self.wclk(10)

        ## Sample family code byte
        for i in range(7):
            await self.send_zero()
            await self.wclk(10)
        await self.send_one()
        await self.wclk(10)

    async def run_test_sample_ROM(self):
        dut = self.dut
        dt = dut.rd2411

        await self.wclk(1000)

        ## Start the logic
        dut.go <= 1;

        ## Respond
        await self.wclk(80000)
        dut.din <= 0;
        dut.go <= 0;
        await self.wclk(1000)
        dut.din <= 1;

        ## Wait for the HOST to send ROM command and initiate writing sequence
        for i in range(26):
            await cocotb.triggers.Edge(dt.smtm)

        ## Write ROM string
        await self.ROM_like_expected()

        ## Reset the logic after a delay
        await cocotb.triggers.Edge(dt.done)
        await self.wclk(100000)
        dut.reset <= 1;
        await self.wclk(1500)
        dut.reset <= 0;

        print("checks: {} ok, {} failed".format(
            self.nchecks_ok, self.nchecks_failed))
        if self.nchecks_failed:
            raise cocotb.result.TestFailure(
                "failed {} checks".format(self.nchecks_failed))

    async def run_test_reset(self):
        dut = self.dut
        dt = dut.rd2411

        await self.wclk(1000)

        ## Start the logic
        dut.go <= 1;

        ## Respond
        await self.wclk(80000)
        dut.din <= 0;
        dut.go <= 0;
        await self.wclk(1000)
        dut.din <= 1;

        ## Wait for the HOST to send ROM command and initiate writing sequence
        await cocotb.triggers.Edge(dt.smtm)
        await cocotb.triggers.Edge(dt.smtm)

        ## Cut the logic off
        dut.reset <= 1;
        await self.wclk(30000)
        dut.reset <= 0;
        await self.wclk(1500)

        await self.wclk(50000)

        print("checks: {} ok, {} failed".format(
            self.nchecks_ok, self.nchecks_failed))
        if self.nchecks_failed:
            raise cocotb.result.TestFailure(
                "failed {} checks".format(self.nchecks_failed))

    async def run_test_no_response(self):
        dut = self.dut
        dt = dut.rd2411

        await self.wclk(1000)

        ## Start the logic
        dut.go <= 1;
        await self.wclk(10000)
        dut.go <= 0;

        ## Wait for error to be announced
        await cocotb.triggers.Edge(dt.error)

        ## Reset the logic after a delay
        await self.wclk(10000)
        dut.reset <= 1;
        await self.wclk(1500)
        dut.reset <= 0;

        await self.wclk(50000)

        print("checks: {} ok, {} failed".format(
            self.nchecks_ok, self.nchecks_failed))
        if self.nchecks_failed:
            raise cocotb.result.TestFailure(
                "failed {} checks".format(self.nchecks_failed))


@cocotb.test()
async def tests(dut):
    """instantiate Tester class then run its test(s)"""
    tester = Tester(dut)
    await tester.run_test_sample_ROM()
    await tester.wclk(100000)
    await tester.run_test_reset()
    await tester.wclk(100000)
    await tester.run_test_no_response()
