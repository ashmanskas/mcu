
import cocotb
import random

from collections import deque


class Tester:

    def __init__(self, dut):
        self.dut = dut
        self.verbose = False

    async def wclk(self, nclk=1, rising=True):
        """shortcut for await ClockCycles(self.dut.clk, ...)"""
        await cocotb.triggers.ClockCycles(self.dut.clk, nclk, rising=rising)

    async def wr(self, addr, data, verbose=None):
        """write 'addr' := 'data' on register-file bus"""
        dut = self.dut
        if verbose is None: verbose = self.verbose
        await self.wclk(rising=False)
        dut.baddr <= addr
        dut.bwrdata <= data
        dut.bwr <= 1
        dut.bstrobe <= 1
        await self.wclk(rising=False)
        dut.baddr <= 0
        dut.bwrdata <= 0
        dut.bwr <= 0
        dut.bstrobe <= 0
        await self.wclk(rising=False)
        if verbose:
            print("wr {:04x} := {:04x}".format(addr, data))

    async def rd(self, addr, verbose=None):
        """read from regsiter-file bus at address 'addr'"""
        dut = self.dut
        if verbose is None: verbose = self.verbose
        await self.wclk(rising=False)
        dut.baddr <= addr
        dut.bwr <= 0
        dut.bstrobe <= 0
        await self.wclk(rising=False)
        dut.bstrobe <= 1
        await self.wclk(rising=False)
        data = dut.brddata.value.integer
        dut.bstrobe <= 0
        dut.baddr <= 0
        await self.wclk(rising=False)
        if verbose:
            print("rd {:04x} -> {:04x}".format(addr, data))
        return data

    async def throw_coincidences(self, coinc_probability=0.02):
        """randomly generate coincidences (observed by fake_rocstar)"""
        self.do_coinc_now = False
        while True:
            await self.wclk()
            if random.random() < coinc_probability:
                self.do_coinc_now = True
            else:
                self.do_coinc_now = False
                
    async def fake_rocstar(self, whoami, mcu_in, mcu_out,
                           single_probability=0.03):
        """emulate cable I/O of one rocstar board"""
        clk_counter = 0
        idle_counter = 0
        nclk_since_trigger = 0
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
        word_history = deque(iterable=NKEEP*[0], maxlen=NKEEP)
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
        MCU_LATENCY = 6
        # Begin main event loop
        while True:
            word = 0x00
            await self.wclk(rising=False)
            # Monitor MCU output
            mout = mcu_out.value.integer
            if mout==MCU_NCOIN:
                print("rs{} @ {} : NCOIN {} whist={}".
                      format(whoami, clk_counter,
                             word_history[-MCU_LATENCY], word_history))
                # We should have issued a single trigger LATENCY ago
                assert (word_history[-MCU_LATENCY] & 0x80) != 0
            elif mout==MCU_PCOIN:
                print("rs{} @ {} : PCOIN {} whist={}".
                      format(whoami, clk_counter,
                             word_history[-MCU_LATENCY], word_history))
                # We should have issued a single trigger LATENCY ago
                assert (word_history[-MCU_LATENCY] & 0x80) != 0
            else:
                # We should NOT have issued a single trigger LATENCY ago
                if (word_history[-MCU_LATENCY] & 0x80) != 0:
                    print("rs{} @ {} : uhoh {} whist={}".
                          format(whoami, clk_counter,
                                 word_history[-MCU_LATENCY], word_history))
                assert (word_history[-MCU_LATENCY] & 0x80) == 0
            # Next 3 lines are to make the if statement more readable
            do_single = random.random() < single_probability
            min_idle_ok = nclk_since_trigger > MIN_IDLE_BETWEEN_TRIG
            if do_coinc_next_clk:
                # We have a pending delayed coincidence from previous clk
                do_coinc = True
                do_coinc_next_clk = False
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
            if (min_idle_ok and (do_single or do_coinc)):
                # Issue a single-photon trigger
                time_offset = random.randint(0,127)
                time_offset = 0  # easier to debug!
                time_offset &= 0x7f  # this should do nothing
                word = TRIG | time_offset
                nclk_since_trigger = 0
            else:
                # Issue an IDLE word
                word = idle[idle_counter]
                clk_bits = clk_counter >> (4*idle_counter) & 0xf
                clk_hibits = (clk_bits >> 2) & 3
                clk_lobits = clk_bits & 3
                word |= clk_lobits
                word |= clk_hibits << 4
                idle_counter = (idle_counter + 1) % NIDLE
                nclk_since_trigger += 1
            mcu_in <= word
            word_history.append(word)
            clk_counter += 1
                
    async def run_test1(self):
        """initial very simple test of mcu_logic module"""
        dut = self.dut
        # From cocotb's perspective, our 'tb' verilog module is the 'dut',
        # even though from our perspective the actual D.U.T. is the
        # 'mcu_logic' module instantiated therein.
        ml = dut.ml

        # Wait a while, then reset, then wait a while
        await self.wclk(20, rising=False)
        dut.ml.rst <= 1
        await self.wclk(rising=False)
        dut.ml.rst <= 0
        await self.wclk(10, rising=False)

        # Instantiate emulated rocstar boards
        self.throw_coinc = cocotb.fork(self.throw_coincidences())
        self.frA1 = cocotb.fork(
            self.fake_rocstar("A1", mcu_in=dut.A1in, mcu_out=dut.A1out))
        self.frB1 = cocotb.fork(
            self.fake_rocstar("B1", mcu_in=dut.B1in, mcu_out=dut.B1out))

        # Let everything run for a while
        await self.wclk(300)

        # Try some register-file "bus" I/O
        self.verbose = True
        await self.wr(0x0001, 0x0000)
        d = await self.rd(0x0000); assert d==0x1234
        d = await self.rd(0x0001); assert d==0x0000
        d = await self.rd(0x0000); assert d==0x1234
        await self.wr(0x0001, 0x4321)
        d = await self.rd(0x0000); assert d==0x1234
        d = await self.rd(0x0001); assert d==0x4321

        await self.wclk(10)
        self.throw_coinc.kill()
        self.frA1.kill()
        self.frB1.kill()
        await self.wclk(5)


@cocotb.test()
async def test1(dut):
    """instantiate Tester class then run its test(s)"""
    tester = Tester(dut)
    await tester.run_test1()
