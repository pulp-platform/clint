# CLINT (Core-local Interrupt Controller)

This repository contains a RISC-V privilege spec 1.11 (WIP) compatible CLINT.

The CLINT uses an **AMBA APB** interface for register access.

|      Address      | Description |                      Note                      |
|-------------------|-------------|------------------------------------------------|
| `BASE` + `0x0000` | msip        | Machine mode software interrupt (IPI)          |
| `BASE` + `0x4000` | mtimecmp    | Machine mode timer compare register for Hart 0 |
| `BASE` + `0xBFF8` | mtime       | Timer register                                 |

## Requirements

The register interface is generated from a SystemRDL description, but the generated RTL is checked in. Nothing is required to simply *use* the CLINT — [PeakRDL](https://github.com/SystemRDL/PeakRDL) is only needed to regenerate it, for example with a different number of cores. The testbench additionally requires the `peakrdl-rawheader` plugin for its register header.

To work on this repository, we recommend [uv](https://docs.astral.sh/uv/): it provides the versions pinned in `uv.lock`, so `make` works out of the box. Alternatively, install the tools yourself and build with `make PEAKRDL=peakrdl`:

```bash
pip install peakrdl peakrdl-rawheader
```


## Reconfiguring CLINT

To simplify CLINT reconfiguration in your project, you can include the GNU Make fragment `clint.mk` in your makefile, for example:

```make
CLINT_ROOT ?= $(shell bender path clint)

# Alternative number of cores
CLINT_CORES = 4

include $(CLINT_ROOT)/clint.mk

# Rebuild CLINT RTL
all: $(CLINT_RTL)
```

This expects `peakrdl` on your `PATH`
