import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, ClockCycles
import random, os

import ca_code_gen

ASSERT = True
if "NOASSERT" in os.environ:
    ASSERT = False

async def reset(dut):
    dut.reset.value = 1

    await ClockCycles(dut.clk, 5)
    dut.reset.value = 0;

@cocotb.test()
async def test_acq_and_track_subsystem(dut):
    clock = Clock(dut.clk, int((1/4.092)*1000000), units="ps")
    cocotb.start_soon(clock.start())

    # test a range of values

    await reset(dut)
    await RisingEdge(dut.clk)
        
    for test_count in range(1023*8):
        await RisingEdge(dut.clk)
        #if ASSERT:
        #    assert( dut.gold_code_out.value == prn_seq[chip_idx]) 
