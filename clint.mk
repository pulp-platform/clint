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

_clint: $(CLINTROOT)/rdl/clint.rdl
	$(PEAKRDL) regblock $< -o $(CLINTROOT)/src --cpuif apb4-flat --default-reset arst_n --module-name clint_reg_top --package-name clint_reg_pkg -P NumCores=$(CLINTCORES)
		@sed -i '1i// Copyright 2025 ETH Zurich and University of Bologna.\n// Licensed under the Apache License, Version 2.0, see LICENSE for details.\n// SPDX-License-Identifier: Apache-2.0\n' src/clint_reg*.sv


clint:
	@echo "[PULP] Generate CLINT (CLINTCORES=$(CLINTCORES))"
	@$(MAKE) -B _clint
