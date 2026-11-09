# This file is public domain, it can be freely copied without restrictions.
# SPDX-License-Identifier: CC0-1.0

# Makefile

# The simulator we want to run our tests with.
SIM = ghdl
ARCH = Rtl

# The top-level language of the design (verilog or vhdl).
TOPLEVEL_LANG = vhdl

# List of Verilog source files.
VHDL_SOURCES = $(PWD)/design/*.vhd

# The name of the toplevel module/entity in your design.
COCOTB_TOPLEVEL = envelope

# The Python modules which contain your testcases.
# The current directory is included in the Python path,
# so you can just specify the module name without the .py extension.
COCOTB_TEST_MODULES = run

# Enable waveform generation.
WAVES = 0

# Includes cocotb's Makefiles which define the build and simulation flows for each supported simulator.
# This must be included *after* all of the variables above are defined.
include $(shell cocotb-config --makefiles)/Makefile.sim
