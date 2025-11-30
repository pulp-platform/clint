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

BENDER = ./bender
CLINTROOT = .
CLINTCORES ?= 2
include clint.mk

all: clint
build:
	./util/compile.sh

run:
	./util/run_vsim.sh
