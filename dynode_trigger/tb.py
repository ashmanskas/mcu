import cocotb
import inspect
import os
import numpy
import random
import matplotlib.pyplot

from collections import deque
from types import SimpleNamespace


class Tester:

    def __init__(self, dut):
        self.dut = dut
        self.verbose = False
        self.nchecks_ok = 0
        self.nchecks_failed = 0

    def parse_bin(s):
        return int(s[:], 2) / 2. ** (len(s))

    def strip0b(s):
        return s[2:]

    def twos_comp(s):
        s = s[2:]
        value = int(s,2) - (1 << len(s))
        return abs(value)

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
        assert type(data) == list
        dut = self.dut
        for d in data:
            await self.wclk()
            d += self.adcdat_quiescent
            if d < 0: d = 0
            if d > 255: d = 255
            dut.adcdat <= d
        await self.wclk()
        dut.adcdat <= self.adcdat_quiescent

    async def run_testSD(self):

        f = open("CrazyRMS.csv", "w")

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
        x = numpy.linspace(0, 7, 8000)
        xp = numpy.linspace(0, 7, 8)

        interpolatedPulse1 = numpy.interp(x, xp, pulse1)
        interpolatedPulse2 = numpy.interp(x, xp, pulse2)
        interpolatedPulse3 = numpy.interp(x, xp, pulse3)

        # Average out interpolated pulses
        avgPulse = list((interpolatedPulse1 + interpolatedPulse2 + interpolatedPulse3) / 3)


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

        # Number of samples to check
        num_of_samples = 1000

        # Instantiate arrays for plots
        actual_eventtime = list()
        calculated_eventtime = list()
        actual_v_calculated_eventtime_diff = list()
        actual_fraction = list()
        calculated_fraction = list()
        event_whole_num_list = list()
        event_frac_list = list()
        event_float_list = list()
        event_actual_float_list = list()
        event_time_difference_list = list()
        event_time = list()

        # Populate a list with N0 in order
        num_list = list()
        for i in range(0, num_of_samples):
            num_list.append(i)

        # Figure out the RMS and max of our data
        rms = 0.1 * numpy.sqrt(numpy.mean([value ** 2 for value in avgPulse]))
        maxOfAvgPulse = max(avgPulse)

        # Generate pulses from the interpolated data in the following way:
        # Figure out an offset that represents the fraction of the clock cycle at which the pulse actually starts
        #    (we will not necessarily sample the pulse right at the start every time)
        # Figure out a factor to scale the interpolation by (from a normal distribution)
        #
        # Append data relevant for plots to their respective lists
        await self.wclk(500)
        for i in range(num_of_samples):
            offset = numpy.random.randint(0, 1000)
            gaussFactor = numpy.random.normal(0, rms, 1) * numpy.random.randint(-1, 2)
            sentPulse = []
            for j in range(0, 8000, 1000):
                value = int(numpy.round(avgPulse[j + offset] * (1 + (gaussFactor / maxOfAvgPulse))))
                sentPulse.append(value)

            # Find the actual clock tick at which we notice the pulse
            current_actual_eventtime = int(str(dut.timcnt), 2)
            actual_eventtime.append(current_actual_eventtime)
            
            # Send the pulse
            await self.send_pulse(sentPulse)
            await self.wclk(3)
            #enesmo_d2 = int(str(dut.enesmo_d2), 2)
            #enesmo_d3 = int(str(dut.enesmo_d3), 2)
            await self.wclk(100)

            # Find out the clock tick the program says it noticed the pulse
            #current_calculated_eventtime = int(str(dut.evnt_timsd_temp), 2)

            # Interpreting event_time_out as it is meant to be read:
            # Take the 12 least significant bits which represent the fractional part
            #    and turn them into the corresponding int
            actual_fraction.append((offset) / 1000)
            sd_timfraco_str =  str(dut.sd_timfraco)
            sd_timAdjusted_int = Tester.parse_bin(sd_timfraco_str) 

            ## THIS IS IMPORTANT: PUT THIS IN VERILOG!!!!!!
            """if sd_timAdjusted_int <= 0.19:
                current_calculated_fraction = - sd_timAdjusted_int + 0.19
                calculated_fraction.append(current_calculated_fraction)
                if enesmo_d3 - enesmo_d2 >= 0:
                    current_calculated_eventtime = current_calculated_eventtime + 1
                    calculated_eventtime.append(current_calculated_eventtime)
                else:
                    current_calculated_eventtime = current_calculated_eventtime - 1
                    calculated_eventtime.append(current_calculated_eventtime)
            else:
                current_calculated_fraction = 1.19 - sd_timAdjusted_int
                calculated_fraction.append(current_calculated_fraction)
                calculated_eventtime.append(current_calculated_eventtime)"""


            # Take the 12 most significant bits which represent the whole number part
            #    and turn them into the corresponding int
            event_whole_thing = int(str(dut.event_whole_num), 2)
            event_whole_num_list.append(int(str(dut.event_whole_num), 2))
            
            event_frac_str = str(dut.event_frac)
            event_frac_int = Tester.parse_bin(event_frac_str)
            event_frac_list.append(event_frac_int)
            
            event_actual_float_list.append(current_actual_eventtime + ((offset) / 1000))

            # Append the current difference in the tick at which we noticed the pulse
            #    and the tick at which we sent the pulse
            # Accounts for overflow
            current_difference = abs(current_actual_eventtime - event_whole_thing)
            if current_difference > 100:
                actual_v_calculated_eventtime_diff.append(abs(current_difference - 256))
            else:
                actual_v_calculated_eventtime_diff.append(current_difference)

        # Populate a list with the true form of the actual event time        
        """for k in range(num_of_samples):
            event_time.append(calculated_eventtime[k] + calculated_fraction[k])"""
            
        # Populate a list with the true form of the calculated event time
        for k in range(num_of_samples):
            event_float_list.append(event_whole_num_list[k] + event_frac_list[k])
            
        # Populate a list with the time difference between the
        #    (true form) actual event time and calculated event time
        # Accounts for overflow
        for k in range(num_of_samples):
            time_difference = event_actual_float_list[k] - event_float_list[k]
            f.write(str(event_actual_float_list[k]) + "," + str(event_float_list[k]) + ",")
            if abs(time_difference) > 100:
                event_time_difference_list.append(time_difference - 256)
                f.write(str(time_difference - 256) + "\n")
            else:
                event_time_difference_list.append(time_difference)
                f.write(str(time_difference) + "\n")

        f.close()

        # Plot data
        if (len(actual_eventtime) == num_of_samples):

            matplotlib.pyplot.scatter(actual_fraction, event_frac_list, s=5)
            matplotlib.pyplot.xlabel("Actual Event Time Fraction")
            matplotlib.pyplot.ylabel("Calculated Event Time Fraction")
            matplotlib.pyplot.savefig("SD_ActualFractionvsCalculatedFraction(tickVtick).pdf")
            matplotlib.pyplot.clf()

            matplotlib.pyplot.scatter(actual_fraction, actual_v_calculated_eventtime_diff, s=4)
            matplotlib.pyplot.xlabel("Calculated Event Time Fraction")
            matplotlib.pyplot.ylabel("Whole Num Diff")
            matplotlib.pyplot.savefig("ActualFractionVsWholeNumDiff.pdf")
            matplotlib.pyplot.clf()

        # Calculate rms, shift histogram by mean of data, produce new histogram
        mean_time_difference = numpy.mean(event_time_difference_list)
        event_time_difference_mean = [(value - mean_time_difference) for value in event_time_difference_list]
        rms_time_difference = numpy.sqrt(numpy.mean([value ** 2 for value in event_time_difference_mean]))

        print(rms_time_difference)

        print("checks: {} ok, {} failed".format(
            self.nchecks_ok, self.nchecks_failed))
        if self.nchecks_failed:
            raise cocotb.result.TestFailure(
                "failed {} checks".format(self.nchecks_failed))


@cocotb.test()
async def tests(dut):
    """instantiate Tester class then run its test(s)"""
    tester = Tester(dut)
    await tester.run_testSD()
