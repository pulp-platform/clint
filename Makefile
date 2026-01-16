# Copyright 2022 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

# Author: Paul Scheffler <paulsc@iis.ee.ethz.ch>
# Author: Florian Zaruba <zarubaf@iis.ee.ethz.ch>

all:

clean:
	rm -rf .bender
	rm -f Bender.lock

# Generate peripheral RTL

BENDER ?= bender
PEAKRDL ?= uv run peakrdl
CLINTROOT = .
CLINTCORES ?= 2
include clint.mk

$(CLINTROOT)/test/clint_reg_defs.svh: $(CLINTROOT)/rdl/clint.rdl $(CLINTROOT)/.generated
	$(PEAKRDL) raw-header $< -o $@ -P NumCores=$(CLINTCORES) --format svh

all: clint $(CLINTROOT)/test/clint_reg_defs.svh
build:
	./util/compile.sh

run:
	./util/run_vsim.sh
