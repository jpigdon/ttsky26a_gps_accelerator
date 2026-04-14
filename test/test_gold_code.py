import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, ClockCycles
import random, os

ASSERT = True
if "NOASSERT" in os.environ:
    ASSERT = False

async def reset(dut):
    dut.sync.value = 1

    await ClockCycles(dut.clk, 5)
    dut.sync.value = 0;

@cocotb.test()
async def test_gold_code(dut):
    clock = Clock(dut.clk, 10, units="us")
    cocotb.start_soon(clock.start())
    dut.ena.value = 1
    # test a range of values
    for i in range(10, 255, 20):
        # set pwm to this level
        dut.sv_taps.value = 0x022 #"0000100010"
        dut.sv_load.value = 1

        await reset(dut)
        dut.sv_load.value = 0

        # with registered outputs, need to wait one clock cycle
        await RisingEdge(dut.clk)

        # wait pwm level clock steps
        for on in range(1023):
            await RisingEdge(dut.clk)
