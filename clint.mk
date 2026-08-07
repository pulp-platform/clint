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
BENDER     ?= bender
CLINTCORES ?= 2
CLINTROOT  ?= $(shell $(BENDER) path clint)
PEAKRDL    ?= peakrdl

# Track the currently generated configuration in the .generated file.
# On every invocation of make, compare the current configuration with the
# stored one and regenerate the files if they differ. This ensures that changes
# to CLINTCORES are picked up automatically and RDL regeneration is triggered.
.PHONY: CLINT_FORCE
CLINT_FORCE:

$(CLINTROOT)/.generated: CLINT_FORCE
	@printf '%s\n' "$(CLINTCORES)" | cmp -s - $@ || printf '%s\n' "$(CLINTCORES)" > $@

CLINT_RTL = $(CLINTROOT)/src/clint_reg.sv $(CLINTROOT)/src/clint_reg_pkg.sv

$(CLINTROOT)/src/%_reg.sv $(CLINTROOT)/src/%_reg_pkg.sv: $(CLINTROOT)/rdl/%.rdl $(CLINTROOT)/.generated
	$(PEAKRDL) regblock $< -o $(CLINTROOT)/src --cpuif apb4-flat --default-reset arst_n --module-name $*_reg --package-name $*_reg_pkg -P NumCores=$(CLINTCORES)
	@sed -i '1i// Copyright 2025 ETH Zurich and University of Bologna.\n// Licensed under the Apache License, Version 2.0, see LICENSE for details.\n// SPDX-License-Identifier: Apache-2.0\n' $(CLINTROOT)/src/$*_reg.sv $(CLINTROOT)/src/$*_reg_pkg.sv

.PHONY: clint
clint: $(CLINT_RTL)
	@echo "[PULP] CLINT sources up to date (CLINTCORES=$(CLINTCORES))"
