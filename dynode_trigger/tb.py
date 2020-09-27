
import cocotb
import inspect
import os
import numpy
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

    async def wr(self, addr, data, check=None, verbose=None):
        """write 'addr' := 'data' on register-file bus"""
        dut = self.dut
        if verbose is None: verbose = self.verbose
        await self.wclk()
        dut.baddr <= addr
        dut.bwrdata <= data
        dut.bwr <= 1
        dut.bstrobe <= 1
        await self.wclk()
        dut.baddr <= 0
        dut.bwrdata <= 0
        dut.bwr <= 0
        dut.bstrobe <= 0
        await self.wclk()
        if verbose:
            print("wr {:04x} := {:04x}".format(addr, data))
        if check is not None:
            self.check(check.value.integer == data)

    async def rd(self, addr, check=None, verbose=None):
        """read from register-file bus at address 'addr'"""
        dut = self.dut
        if verbose is None: verbose = self.verbose
        await self.wclk()
        dut.baddr <= addr
        dut.bwr <= 0
        dut.bstrobe <= 0
        await self.wclk()
        dut.bstrobe <= 1
        await self.wclk()
        data = dut.brddata.value.integer
        dut.bstrobe <= 0
        dut.baddr <= 0
        await self.wclk()
        if verbose:
            print("rd {:04x} -> {:04x}".format(addr, data))
        if check is not None:
            self.check(data == check)
        return data

    async def send_pulse(self, data):
        """put list of samples in data[] onto 'adcdat'"""
        assert type(data)==list
        dut = self.dut
        for d in data:
            await self.wclk()
            d += self.adcdat_quiescent
            if d < 0: d = 0
            if d > 255: d = 255
            dut.adcdat <= d
        await self.wclk()
        dut.adcdat <= self.adcdat_quiescent
    
    async def run_test1(self):
        """initial very simple test of dynode_trigger module"""
        dut = self.dut
        # From cocotb's perspective, our 'tb' verilog module is the 'dut',
        # even though from our perspective the actual D.U.T. is the
        # 'read_adt7320' module instantiated therein.
        dt = dut.dt
        self.adcdat_quiescent = 32  # what is this in real life?

        dut.selecttime <= 0
        dut.smoothpmt <= 3

        # Wait a while, then reset, then wait a while
        dut.adcdat <= 0
        dut.adcdat <= self.adcdat_quiescent
        await self.wclk(20)
        dut.reset <= 1
        await self.wclk(5)
        dut.reset <= 0
        await self.wclk()
        await self.wr(0x0e00, 64, check=dt.energy_thresh_low, verbose=True)
        await self.wr(0x0e01, 192, check=dt.energy_thresh_high, verbose=True)
        dut.adcdat <= self.adcdat_quiescent
        # speed up settling time for baseline average
        dut.dtr.dynbl.currentvalue <= 0x100 * self.adcdat_quiescent
        await self.wclk(500)
        await self.send_pulse([45, 140, 200, 210, 160, 90, 20])
        await self.wclk(200)
        await self.send_pulse([35, 45, 35])
        await self.wclk(200)
        await self.send_pulse([45, 140, 200, 210, 160, 90, 20])
        await self.wclk(200)
        await self.send_pulse([45, 140, 200, 210, 160, 90, 20])
        await self.wclk(500)


        print("checks: {} ok, {} failed".format(
            self.nchecks_ok, self.nchecks_failed))
        if self.nchecks_failed:
            raise cocotb.result.TestFailure(
                "failed {} checks".format(self.nchecks_failed))

    async def run_test2(self):
        dut = self.dut
        # From cocotb's perspective, our 'tb' verilog module is the 'dut',
        # even though from our perspective the actual D.U.T. is the
        # 'read_adt7320' module instantiated therein.
        dt = dut.dt
        self.adcdat_quiescent = 32  # what is this in real life?

        # Sample pulses from real breast scanner PET detector
        pulse1 = [1.10969387755102, 31.1466836734694, 122.091836734694, 206.825255102041,
                      228.071428571429, 187.141581632653, 107.823979591837, 31.4553571428571]
        pulse2 = [1.46811224489796, 30.8405612244898, 119.411989795918, 201.660714285714,
                      222.081632653061, 180.992346938776, 103.591836734694, 29.6441326530612]
        pulse3 = [1.14158163265306, 26.7321428571429, 108.859693877551, 188.739795918367,
                      211.290816326531, 173.734693877551, 100.732142857143, 30.0420918367347]

        # Interpolate data from pulses
        x = numpy.linspace(0, 7, 40)
        xp = numpy.linspace(0, 8)

        interpolatedPulse1 = numpy.interp(x, xp, pulse1)
        interpolatedPulse2 = numpy.interp(x, xp, pulse2)
        interpolatedPulse3 = numpy.interp(x, xp, pulse3)

        # Average out interpolated pulses
        avgPulse = list(40)
        for i in range(40):
            pulseSampleSum = interpolatedPulse1[i] + interpolatedPulse2[i] + interpolatedPulse3[i]
            avgPulse[i] = pulseSampleSum / 3


        dut.selecttime <= 0
        dut.smoothpmt <= 3

        # Wait a while, then reset, then wait a while
        dut.adcdat <= 0
        dut.adcdat <= self.adcdat_quiescent
        await self.wclk(20)
        dut.reset <= 1
        await self.wclk(5)
        dut.reset <= 0
        await self.wclk()
        await self.wr(0x0e00, 64, check=dt.energy_thresh_low, verbose=True)
        await self.wr(0x0e01, 192, check=dt.energy_thresh_high, verbose=True)
        dut.adcdat <= self.adcdat_quiescent
        # speed up settling time for baseline average
        dut.dtr.dynbl.currentvalue <= 0x100 * self.adcdat_quiescent

        await self.wclk(500)
        rms = 0.1 * numpy.sqrt(numpy.mean(avgPulse ** 2))
        maxOfAvgPulse = max(avgPulse)
        for i in range(4):
            offset = numpy.random.randint(-2, 2)
            gaussFactor = numpy.random.normal(0, rms, 1) * numpy.random.randint(-1, 2)
            sentPulse = list(8)
            for j in range(2, 40, 5):
                sentPulse.append(avgPulse[j - offset] * (1 + (gaussFactor / maxOfAvgPulse)))

            await self.send_pulse(sentPulse)
            await self.wclk(numpy.random.randint(50, 750))



        print("checks: {} ok, {} failed".format(
            self.nchecks_ok, self.nchecks_failed))
        if self.nchecks_failed:
            raise cocotb.result.TestFailure(
                "failed {} checks".format(self.nchecks_failed))


@cocotb.test()
async def tests(dut):
    """instantiate Tester class then run its test(s)"""
    tester = Tester(dut)
    await tester.run_test1()
    await tester.run_test2()
