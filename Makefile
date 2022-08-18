# Copyright 2022 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

# Author: Paul Scheffler <paulsc@iis.ee.ethz.ch>
# Author: Florian Zaruba <zarubaf@iis.ee.ethz.ch>

all:

clean:
	rm -rf .bender
	rm -f Bender.lock

bender:
	curl --proto '=https' --tlsv1.2 -sSf https://pulp-platform.github.io/bender/init | bash -s -- 0.26.0
	touch bender

# Generate peripheral RTL

BENDER = ./bender
CLINTROOT = .
clint.mk: bender # Bender is needed by make fragment
include clint.mk

all: clint

# Checks

CHECK_CLEAN = git status && test -z "$$(git status --porcelain)"

check_generated:
	$(MAKE) -B clint
	$(CHECK_CLEAN)

check: check_generated
