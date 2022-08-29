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
REGTOOL    ?= $(shell $(BENDER) path register_interface)/vendor/lowrisc_opentitan/util/regtool.py
CLINTCORES ?= 2
CLINTROOT  ?= $(shell $(BENDER) path clint)
CLINTTOOL  ?= $(CLINTROOT)/util/gen_clint.py

$(CLINTROOT)/src/clint.hjson: $(CLINTROOT)/data/clint.hjson.tpl
	$(CLINTTOOL) $< -c $(CLINTCORES) > $@

$(CLINTROOT)/src/clint.sv: $(CLINTROOT)/data/clint.sv.tpl
	$(CLINTTOOL) $< -c $(CLINTCORES) > $@

_clint: $(CLINTROOT)/src/clint.hjson $(CLINTROOT)/src/clint.sv $(REGTOOL)
	$(REGTOOL) $< -r --outdir $(CLINTROOT)/src/

clint:
	@echo "[PULP] Generate CLINT (CLINTCORES=$(CLINTCORES))"
	@$(MAKE) -B _clint
