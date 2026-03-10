# Copyright 2022 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

# Author: Paul Scheffler <paulsc@iis.ee.ethz.ch>
# Author: Florian Zaruba <zarubaf@iis.ee.ethz.ch>

all:

# Generate peripheral RTL

BENDER ?= bender
PEAKRDL ?= uv run peakrdl
VSIM ?= vsim
VLIB ?= vlib
VMAP ?= vmap
OSEDA ?=
TB_TOP ?= clint_tb
TB_HDR ?= $(CLINTROOT)/test/clint_reg_defs.svh
VSIM_SCRIPT ?= scripts/compile.tcl
VSIM_WORKLIB ?= work-vsim
VSIM_VLOG_ARGS ?= -work $(VSIM_WORKLIB)
VLT ?= $(OSEDA) verilator
VLT_WORKDIR ?= work-vlt
VLT_BIN ?= $(VLT_WORKDIR)/Vclint_tb

CLINTROOT = .
CLINTCORES ?= 2
include clint.mk

$(TB_HDR): $(CLINTROOT)/rdl/clint.rdl $(CLINTROOT)/.generated
	$(PEAKRDL) raw-header $< -o $@ -P NumCores=$(CLINTCORES) --format svh
	@sed -i '1i// Copyright 2025 ETH Zurich and University of Bologna.\n// Licensed under the Apache License, Version 2.0, see LICENSE for details.\n// SPDX-License-Identifier: Apache-2.0\n' $@

all: clint $(TB_HDR)

$(VSIM_SCRIPT): Bender.lock Bender.yml
	mkdir -p scripts
	$(BENDER) script vsim -t test --vlog-args="$(VSIM_VLOG_ARGS)" > $@

build: $(TB_HDR) $(VSIM_SCRIPT)
	$(VLIB) $(VSIM_WORKLIB)
	$(VMAP) $(VSIM_WORKLIB) $(VSIM_WORKLIB)
	$(VSIM) -c -do "exit -code [source $(VSIM_SCRIPT)]"

run: build
	$(VSIM) -work $(VSIM_WORKLIB) -c -voptargs=+acc $(TB_TOP) -do "log -r /*; run -all" | tee vsim.log 2>&1
	@grep "Errors: 0," vsim.log >/dev/null || (echo "Simulation failed"; exit 1)

vlt-build: $(TB_HDR)
	$(VLT) $(shell $(BENDER) script verilator -t test -t simulation) \
	--timescale 1ns/1ps -Wno-fatal -Mdir $(VLT_WORKDIR) \
	--binary --top-module $(TB_TOP)

vlt-run: vlt-build
	$(OSEDA) ./$(VLT_BIN)

clean:
	rm -rf .bender
	rm -rf $(TB_HDR)
	rm -rf $(VSIM_WORKLIB)
	rm -rf $(VLT_WORKDIR)
	rm -f scripts/compile.tcl
	rm -f vsim.log
