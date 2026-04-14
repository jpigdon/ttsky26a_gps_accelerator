# Makefile
# See https://docs.cocotb.org/en/stable/quickstart.html for more info

# defaults
SIM ?= nvc
SIM_ARGS += --wave=nvcsim.fst
TOPLEVEL_LANG ?= vhdl
SRC_DIR = $(PWD)/../src


ifneq ($(GATES),yes)

# RTL simulation:
SIM_BUILD				= sim_build/rtl
VHDL_SOURCES = $(SRC_DIR)/gold_code_gen.vhdl

else

# Gate level simulation:
SIM_BUILD				= sim_build/gl
COMPILE_ARGS    += -DGL_TEST
COMPILE_ARGS    += -DFUNCTIONAL
COMPILE_ARGS    += -DUSE_POWER_PINS
COMPILE_ARGS    += -DSIM
COMPILE_ARGS    += -DUNIT_DELAY=\#1
VERILOG_SOURCES += $(PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd/verilog/primitives.v
VERILOG_SOURCES += $(PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd/verilog/sky130_fd_sc_hd.v

# this gets copied in by the GDS action workflow
VERILOG_SOURCES += $(PWD)/gate_level_netlist.v

COMPILE_ARGS 		+= -I$(SRC_DIR)
endif

# Allow sharing configuration between design and testbench via `include`:

# Include the testbench sources:
TOPLEVEL = gold_code_gen
MODULE = test_gold_code
# List test modules to run, separated by commas and without the .py suffix:
#COCOTB_TEST_MODULES = test

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim
