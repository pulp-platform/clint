# Copyright 2022 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

# Author: Paul Scheffler <paulsc@iis.ee.ethz.ch>
# Author: Florian Zaruba <zarubaf@iis.ee.ethz.ch>

all:

clean:
	rm -rf .bender
	rm -rf work

# Generate peripheral RTL

BENDER ?= bender
PEAKRDL ?= uv run peakrdl
VSIM ?= vsim

CLINTROOT = .
CLINTCORES ?= 2
include clint.mk

$(CLINTROOT)/test/clint_reg_defs.svh: $(CLINTROOT)/rdl/clint.rdl $(CLINTROOT)/.generated
	$(PEAKRDL) raw-header $< -o $@ -P NumCores=$(CLINTCORES) --format svh
	@sed -i '1i// Copyright 2025 ETH Zurich and University of Bologna.\n// Licensed under the Apache License, Version 2.0, see LICENSE for details.\n// SPDX-License-Identifier: Apache-2.0\n' $@

all: clint $(CLINTROOT)/test/clint_reg_defs.svh

scripts/compile.tcl: Bender.lock Bender.yml
	mkdir -p scripts
	$(BENDER) script vsim -t test > $@

build: scripts/compile.tcl
	$(VSIM) -c -do "exit -code [source $<]"

run:
	$(VSIM) -c -voptargs=+acc clint_tb -do "log -r /*; run -all" | tee vsim.log 2>&1
	@grep "Errors: 0," vsim.log >/dev/null || (echo "Simulation failed"; exit 1)
