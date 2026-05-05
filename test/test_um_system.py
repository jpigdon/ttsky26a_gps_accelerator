import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, ClockCycles, Timer, Edge
import random, os


import numpy as np

import gen_synthetic_data
import ca_code_gen

SPI_PERIOD_NS = 1000

ASSERT = True
if "NOASSERT" in os.environ:
    ASSERT = False

async def reset(dut):
    dut.rst_n.value = 0

    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1;


async def spi_operation(dut, num_transactions=1,delay_ns=2000, word_to_send=0x81A50F00, num_read_ops=4, read_op_delays=[5000,5000,5000,5000], read_op_words=[0x05000000, 0x06000000, 0x07000000, 0x08000000] ):
    uin_val = 0x03
    dut.uio_in.value = uin_val

    for j in range(num_transactions):
        await Timer(delay_ns[j], units='ns')
        uin_val = 0x02

        #print("Sending: "+ str(hex(word_to_send[j])))

        if(((word_to_send[j] >> 31) & 1) == 1):
            uin_val = uin_val | (1 << 1)
        else:
            uin_val = uin_val & 0xFD

        dut.uio_in.value = uin_val

        await Timer(1.5*SPI_PERIOD_NS, units='ns')
        for i in range(31):
        #     #set the bit
            await Timer(SPI_PERIOD_NS/2, units='ns')
            uin_val = uin_val | (1 << 3)
            dut.uio_in.value = uin_val

            await Timer(SPI_PERIOD_NS/2, units='ns')
            uin_val = uin_val & 0xF7

            if(((word_to_send[j] >> 31-i-1) & 1) == 1):
                uin_val = uin_val | (1 << 1)
            else:
                uin_val = uin_val & 0xFD

            dut.uio_in.value = uin_val

        await Timer(1.5*SPI_PERIOD_NS, units='ns')
        uin_val = uin_val | 0x01
        dut.uio_in.value = uin_val
    
    while True:
        await Edge(dut.uo_out)
        for j in range(num_read_ops):
            await Timer(read_op_delays[j], units='ns')
            uin_val = 0x02

            if(((read_op_words[j] >> 31) & 1) == 1):
                uin_val = uin_val | (1 << 1)
            else:
                uin_val = uin_val & 0xFD

            dut.uio_in.value = uin_val

            await Timer(1.5*SPI_PERIOD_NS, units='ns')
            for i in range(31):
            #     #set the bit
                await Timer(SPI_PERIOD_NS/2, units='ns')
                uin_val = uin_val | (1 << 3)
                dut.uio_in.value = uin_val

                await Timer(SPI_PERIOD_NS/2, units='ns')
                uin_val = uin_val & 0xF7

                if(((read_op_words[j] >> 31-i-1) & 1) == 1):
                    uin_val = uin_val | (1 << 1)
                else:
                    uin_val = uin_val & 0xFD

                dut.uio_in.value = uin_val

            await Timer(1.5*SPI_PERIOD_NS, units='ns')
            uin_val = uin_val | 0x01
            dut.uio_in.value = uin_val
        
        await Timer(read_op_delays[0], units='ns')
        uin_val = 0x02

        if(((0x80000100 >> 31) & 1) == 1):
            uin_val = uin_val | (1 << 1)
        else:
            uin_val = uin_val & 0xFD

        dut.uio_in.value = uin_val

        await Timer(1.5*SPI_PERIOD_NS, units='ns')
        for i in range(31):
        #     #set the bit
            await Timer(SPI_PERIOD_NS/2, units='ns')
            uin_val = uin_val | (1 << 3)
            dut.uio_in.value = uin_val

            await Timer(SPI_PERIOD_NS/2, units='ns')
            uin_val = uin_val & 0xF7

            if(((0x80000100 >> 31-i-1) & 1) == 1):
                uin_val = uin_val | (1 << 1)
            else:
                uin_val = uin_val & 0xFD

            dut.uio_in.value = uin_val

        await Timer(1.5*SPI_PERIOD_NS, units='ns')
        uin_val = uin_val | 0x01
        dut.uio_in.value = uin_val




@cocotb.test()
async def test_um_system(dut):
    

    # test a range of values

    test_data_unquantised = gen_synthetic_data.generate_synthetic_data()
    i_chan_quantised = np.array(np.where(np.real(test_data_unquantised) >= 0.0, 1,-1),dtype="int8")
    q_chan_quantised = np.array(np.where(np.imag(test_data_unquantised) >= 0.0, 1,-1),dtype="int8")

    taps = ca_code_gen.taps_from_sv(1)
    #print(hex(taps))

    delays = [5000, 5000, 5000, 5000, 5000]
    transactions = [ 0x81000000 | (taps << 8), 0x82FFFE00, 0x83000100, 0x84000300, 0x80000200]

    clock = Clock(dut.clk, int((1/4.092)*1000000), units="ps")
    cocotb.start_soon(clock.start())
    spi_task = cocotb.start_soon(spi_operation(dut, num_transactions=5, delay_ns=delays, word_to_send=transactions))


    dut.ena.value = 1
    dut.ui_in.value = 0
    # test a range of values



    # test a range of values

    await reset(dut)
    await RisingEdge(dut.clk)
        
    for test_count in range(1023*4*32):

        await RisingEdge(dut.clk)
        uin_val = 0x00
        if(i_chan_quantised[test_count] == 1):
            uin_val = 1
      
        if(q_chan_quantised[test_count] == 1):
            uin_val = uin_val | (1 << 2)

        dut.ui_in.value = uin_val
        
        #if ASSERT:
        #    assert( dut.gold_code_out.value == prn_seq[chip_idx]) 
