# CLINT (Core-local Interrupt Controller)

This repository contains a RISC-V privilege spec 1.11 (WIP) compatible CLINT.

The CLINT uses an **AMBA APB** interface for register access.

|      Address      | Description |                      Note                      |
|-------------------|-------------|------------------------------------------------|
| `BASE` + `0x0000` | msip        | Machine mode software interrupt (IPI)          |
| `BASE` + `0x4000` | mtimecmp    | Machine mode timer compare register for Hart 0 |
| `BASE` + `0xBFF8` | mtime       | Timer register                                 |

## Requirements

The register interface is generated from a SystemRDL description. To (re-)generate the RTL, the following tool is required:
- [PeakRDL](https://github.com/SystemRDL/PeakRDL)

You can install it via pip:

```bash
pip install peakrdl
```

For development and running tests, we use [uv](https://docs.astral.sh/uv/) to manage Python dependencies, including the `peakrdl-rawheader` plugin used for testbench header generation.


## Reconfiguring CLINT

To simplify CLINT reconfiguration in your project, you can include the GNU Make fragment `clint.mk` in your makefile, for example:

```make
CLINTROOT ?= $(shell bender path clint)

# Alternative number of cores
CLINTCORES = 4

include $(CLINTROOT)/clint.mk

# Rebuild CLINT RTL
all: $(CLINTROOT)/src/clint_reg.sv
```
