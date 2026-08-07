# Copyright 2022 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

# Author: Paul Scheffler <paulsc@iis.ee.ethz.ch>
# Author: Florian Zaruba <zarubaf@iis.ee.ethz.ch>

# Import this GNU Make fragment in your project's makefile to regenerate and
# reconfigure these IPs. You can modify the original RTL, configuration, and
# templates from your project without entering this dependency repo by adding
# build targets for them. To build the IPs, `make clint`.

# You may need to adapt these environment variables to your configuration.
BENDER      ?= bender
CLINT_CORES ?= 2
CLINT_ROOT  ?= $(shell $(BENDER) path clint)
PEAKRDL     ?= peakrdl

# Track the currently generated configuration in the .generated file.
# On every invocation of make, compare the current configuration with the
# stored one and regenerate the files if they differ. This ensures that changes
# to CLINT_CORES are picked up automatically and RDL regeneration is triggered.
.PHONY: CLINT_FORCE
CLINT_FORCE:

$(CLINT_ROOT)/.generated: CLINT_FORCE
	@printf '%s\n' "$(CLINT_CORES)" | cmp -s - $@ || printf '%s\n' "$(CLINT_CORES)" > $@

CLINT_RTL = $(CLINT_ROOT)/src/clint_reg.sv $(CLINT_ROOT)/src/clint_reg_pkg.sv

$(CLINT_ROOT)/src/%_reg.sv $(CLINT_ROOT)/src/%_reg_pkg.sv: $(CLINT_ROOT)/rdl/%.rdl $(CLINT_ROOT)/.generated
	$(PEAKRDL) regblock $< -o $(CLINT_ROOT)/src --cpuif apb4-flat --default-reset arst_n --module-name $*_reg --package-name $*_reg_pkg -P NumCores=$(CLINT_CORES)
	@sed -i '1i// Copyright 2025 ETH Zurich and University of Bologna.\n// Licensed under the Apache License, Version 2.0, see LICENSE for details.\n// SPDX-License-Identifier: Apache-2.0\n' $(CLINT_ROOT)/src/$*_reg.sv $(CLINT_ROOT)/src/$*_reg_pkg.sv

.PHONY: clint
clint: $(CLINT_RTL)
	@echo "[PULP] CLINT sources up to date (CLINT_CORES=$(CLINT_CORES))"
