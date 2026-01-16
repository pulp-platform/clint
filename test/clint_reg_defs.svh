// Copyright 2025 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0



`ifndef CLINT_SVH
`define CLINT_SVH

`define CLINT_BASE_ADDR 64'h0
`define CLINT_SIZE 64'hC000


`define CLINT_MSIP_BASE_ADDR(msip_idx) (64'h0 + (msip_idx * 64'h4) )
`define CLINT_MSIP_NUM 64'h2

`define CLINT_MTIMECMP_BASE_ADDR(mtimecmp_idx) (64'h4000 + (mtimecmp_idx * 64'h8) )
`define CLINT_MTIMECMP_NUM 64'h2

`define CLINT_MTIME_BASE_ADDR 64'hBFF8



`endif /* CLINT_SVH */
