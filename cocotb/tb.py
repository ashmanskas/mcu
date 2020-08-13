
import cocotb
import inspect
import os
import random

from collections import deque
from types import SimpleNamespace


class Tester:

    # values for special words sent from MCU to rocstar boards
    SPWORD_SYNCH = 0x1111  # synchronize clock counters to 0
    SPWORD_START = 0x2222  # start data taking
    SPWORD_END   = 0x3333  # end data taking
    SPWORD_SVCLK = 0x4444  # save current clock counter to a register
        
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
        """read from regsiter-file bus at address 'addr'"""
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

    async def throw_coincidences(self, coinc_probability=0.02):
        """randomly generate coincidences (observed by fake_rocstar)"""
        self.do_coinc_now = False
        self.coinc_t_offset = 0
        while True:
            await self.wclk()
            if random.random() < coinc_probability:
                self.do_coinc_now = True
                # we may expand (-15,15) to a larger range later
                self.coinc_t_offset = random.randint(-15,15)
                # This is intended to represent the time when the real
                # coincident happened w.r.t. the time tickwhen this
                # method is invoked.  If a given rocstar board reports
                # the event one clock cycle later, that board's offset
                # will be different from this value.
            else:
                self.do_coinc_now = False
                self.coinc_t_offset = 0
            # Make 'coinc_t_offset' visible in the waveform viewer
            self.dut.coinc_t_offset <= self.coinc_t_offset
                
    async def fake_rocstar(self, whoami, mcu_in, mcu_out,
                           single_probability=0.03):
        """emulate cable I/O of one rocstar board"""
        # Create a place to store this coroutine's internal state, so
        # that it can be accessed from the enclosing 'Tester'
        # instance.  I'll give it the absurdly short name 'o' (short
        # for "object") to avoid clutter below.
        o = SimpleNamespace()
        self.fr[whoami] = o
        o.nclk_since_trigger = 0
        # Look up self.dut.clkcnt_A1 or similar
        tb_clkcnt = getattr(self.dut, "clkcnt_"+whoami)
        tb_clkcnt <= random.randint(0,65535)
        tb_clksav = getattr(self.dut, "clksav_"+whoami)
        single_net = getattr(self.dut, "single_"+whoami)
        offset_net = getattr(self.dut, "offset_"+whoami)
        runmode_net = getattr(self.dut, "runmode_"+whoami)
        # I spread the clk_counter bits out like this because mcu_in bits
        # 7:4 are on one wire and bits 3:0 are on another wire.  I want to
        # use the idle patterns to check the signal integrity of both wires.
        IDLE0 = 0b01000000  # bits 5,4,1,0 -> clk_counter bits 3:0
        IDLE1 = 0b01000100  # bits 5,4,1,0 -> clk_counter bits 7:4
        IDLE2 = 0b01001000  # bits 5,4,1,0 -> clk_counter bits 11:8
        IDLE3 = 0b01001100  # bits 5,4,1,0 -> clk_counter bits 15:12
        TRIG  = 0b10000000  # bits 6:0 -> time offset wrt rising clk edge
        idle = [IDLE0, IDLE1, IDLE2, IDLE3]
        NIDLE = len(idle)
        # Symbol values output by MCU: these belong somewhere else
        MCU_IDLE0 = 0b0111 ; MCU_IDLE1 = 0b1011
        MCU_IDLE2 = 0b1101 ; MCU_IDLE3 = 0b1110
        MCU_PCOIN = 0b0011 ; MCU_DCOIN = 0b0110
        MCU_NCOIN = 0b1001 ; MCU_SPECL = 0b1100
        MCU_TEST0 = 0b0000 ; MCU_TEST1 = 0b0001
        MCU_TEST2 = 0b0010 ; MCU_TEST4 = 0b0100
        MCU_TEST5 = 0b0101 ; MCU_TEST8 = 0b1000
        MCU_TESTA = 0b1010 ; MCU_TESTF = 0b1111
        # Keep track of most recent N transmitted words
        NKEEP = 20
        o.trig_history = deque(iterable=NKEEP*[0], maxlen=NKEEP)
        # Enforce minimum delay between triggers from a given rocstar.
        # Do we do this in real life?!
        MIN_IDLE_BETWEEN_TRIG = 1
        # Some fraction of the time, insert a one-clock delay before noticing
        # the coincidence, so that we test the MCU's intended ability to find
        # coincidences that are shifted in time by one clock cycle.
        COINC_DELAY_FRACTION = 0.2
        do_coinc_next_clk = False
        # Latency (in clock cycles) of rocstar <-> MCU round trip;
        # this will be much longer in real life
        MCU_LATENCY = 9
        # Keep track of what state the event loop is in
        ticks_since_specl = 0
        # Begin main event loop
        prev_coinc_t_offset = 0
        while True:
            do_trigger_now = 0
            await self.wclk()  # This loop executes once per clk cycle
            # Monitor MCU output
            mout = mcu_out.value.integer
            if ticks_since_specl>0 and ticks_since_specl<5:
                ticks_since_specl += 1
            elif mout==MCU_SPECL:
                ticks_since_specl = 1
            elif mout==MCU_NCOIN:
                print("rs{}@{:.0f} : NCOIN {} whist={}".
                      format(whoami, self.ns(),
                             o.trig_history[-MCU_LATENCY], o.trig_history))
                # We should have issued a single trigger LATENCY ago
                self.check(o.trig_history[-MCU_LATENCY])
            elif mout==MCU_PCOIN:
                print("rs{}@{:.0f} : PCOIN {} whist={}".
                      format(whoami, self.ns(),
                             o.trig_history[-MCU_LATENCY], o.trig_history))
                # We should have issued a single trigger LATENCY ago
                self.check(o.trig_history[-MCU_LATENCY])
            else:
                # We should NOT have issued a single trigger LATENCY ago
                if o.trig_history[-MCU_LATENCY]:
                    print("rs{}@{:.0f} : uhoh {} whist={}".
                          format(whoami, self.ns(),
                                 o.trig_history[-MCU_LATENCY],
                                 o.trig_history))
                self.check(not o.trig_history[-MCU_LATENCY])
            time_offset = 0  # may be overridden below
            # Next 2 lines are to make the if statement more readable
            do_single = random.random() < single_probability
            min_idle_ok = o.nclk_since_trigger >= MIN_IDLE_BETWEEN_TRIG
            t_offset = self.coinc_t_offset  # local copy
            if do_coinc_next_clk:
                # We have a pending delayed coincidence from previous clk
                do_coinc = True
                do_coinc_next_clk = False
                t_offset = prev_coinc_t_offset - 32
            elif not self.do_coinc_now:
                # We do not have a new coincidence this clk
                do_coinc = False
                do_coinc_next_clk = False
            elif random.random() < COINC_DELAY_FRACTION:
                # We do have a new coinc this clk, but we choose to delay it
                do_coinc = False
                do_coinc_next_clk = True
            else:
                # We have a new coinc this clk and we'll do it now
                do_coinc = True
                do_coinc_next_clk = False
            if runmode_net.value.integer==0:
                # If we're not in data-taking mode, then we should not
                # report triggers to the mcu
                do_single = False
                do_coinc = False
                do_coinc_next_clk = False
            if (min_idle_ok and (do_single or do_coinc)):
                # Issue a single-photon trigger
                if False: time_offset = random.randint(0,63)
                if False: time_offset = 0  # easier to debug!
                time_offset = t_offset
                time_offset += random.randint(-3,+3)
                if time_offset < -32: time_offset = -32
                if time_offset > +31: time_offset = +31
                time_offset &= 0x3f
                do_trigger_now = 1
                o.nclk_since_trigger = 0
            else:
                # Issue an IDLE word
                o.nclk_since_trigger += 1
            o.trig_history.append(do_trigger_now)
            single_net <= do_trigger_now
            offset_net <= time_offset
            # save this value of coinc_t_offset for next time
            prev_coinc_t_offset = self.coinc_t_offset
                
    async def run_test1(self):
        """initial very simple test of mcu_logic module"""
        dut = self.dut
        # From cocotb's perspective, our 'tb' verilog module is the 'dut',
        # even though from our perspective the actual D.U.T. is the
        # 'mcu_logic' module instantiated therein.
        ml = dut.ml

        # Wait a while, then reset, then wait a while
        await self.wclk(20)
        dut.ml.rst <= 1
        await self.wclk()
        dut.ml.rst <= 0
        await self.wclk(10)

        # Instantiate emulated rocstar boards
        self.throw_coinc = cocotb.fork(self.throw_coincidences())
        self.fr = {}  # dict of info about fake_rocstar instances
        _ = cocotb.fork(
            self.fake_rocstar("A1", mcu_in=dut.A1in, mcu_out=dut.A1out))
        self.fr["A1"].forked_coroutine = _
        _ = cocotb.fork(
            self.fake_rocstar("B1", mcu_in=dut.B1in, mcu_out=dut.B1out))
        self.fr["B1"].forked_coroutine = _

        # Run for a while, then tell mcu to transmit special commands
        # to rocstar boards to save the current values of their clock
        # counters, then synchronize their clock counters and start
        # data collection.
        await self.wclk(20)
        await self.wr(0x0002, self.SPWORD_SVCLK, check=dut.ml.spword)
        await self.wclk(20)
        await self.wr(0x0002, self.SPWORD_SYNCH, check=dut.ml.spword)
        await self.wclk(10)
        await self.wr(0x0002, self.SPWORD_START, check=dut.ml.spword)
        await self.wclk(20)
        await self.wr(0x0002, self.SPWORD_SVCLK, check=dut.ml.spword)

        # Let everything run for a while, then tell mcu to transmit
        # the "stop data collection" special command to the rocstar
        # boards.
        await self.wclk(300)
        await self.wr(0x0002, self.SPWORD_END, check=dut.ml.spword)
        await self.wclk(10)

        # Try some register-file "bus" I/O
        self.verbose = True
        await self.wr(0x0001, 0x0000, check=dut.ml.q0001)
        d = await self.rd(0x0000, check=0x1234)
        d = await self.rd(0x0001, check=0x0000)
        d = await self.rd(0x0000, check=0x1234)
        await self.wr(0x0001, 0x4321, check=dut.ml.q0001)
        d = await self.rd(0x0000, check=0x1234)
        d = await self.rd(0x0001, check=0x4321)
        await self.wr(0x0001, 0x2341, check=dut.ml.q0001)
        d = await self.rd(0x0001, check=0x2341)
        d = await self.rd(0x0000, check=0x1234)
        d = await self.rd(0x0001, check=0x2341)
        await self.wclk(20)
        await self.wr(0x0002, self.SPWORD_SVCLK, check=dut.ml.spword)
        await self.wclk(20)

        # Now kill off the coroutines we forked earlier
        self.throw_coinc.kill()
        for fr_name in self.fr:
            fr = self.fr[fr_name]
            print("killing off fake_rocstar instance {} : {}".
                  format(fr_name, fr))
            fr.forked_coroutine.kill()
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
