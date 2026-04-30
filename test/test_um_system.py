import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, ClockCycles
import random, os

import ca_code_gen

ASSERT = True
if "NOASSERT" in os.environ:
    ASSERT = False

async def reset(dut):
    dut.rst_n.value = 0

    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1;

@cocotb.test()
async def test_um_system(dut):
    clock = Clock(dut.clk, 10, units="us")
    cocotb.start_soon(clock.start())
    dut.ena.value = 1

    # test a range of values

    await reset(dut)
    await RisingEdge(dut.clk)
        
    for test_count in range(1023*4):
        await RisingEdge(dut.clk)
        #if ASSERT:
        #    assert( dut.gold_code_out.value == prn_seq[chip_idx]) 
