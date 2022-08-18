# CLINT (Core-local Interrupt Controller)

This repository contains a RISC-V privilege spec 1.11 (WIP) compatible CLINT .

The CLINT plugs into a [generic register interface](https://github.com/pulp-platform/register_interface), which may be adapted to various protocols including AMBA APB and AXI 4/Lite (see repository for adapter IPs).

|      Address      | Description |                      Note                      |
|-------------------|-------------|------------------------------------------------|
| `BASE` + `0x0`    | msip        | Machine mode software interrupt (IPI)          |
| `BASE` + `0x4000` | mtimecmp    | Machine mode timer compare register for Hart 0 |
| `BASE` + `0xBFF8` | mtime       | Timer register                                 |


## Reconfiguring CLINT

To simplify CLINT reconfiguration in your project, you can include the GNU Make fragment `clint.mk` in your makefile, for example:

```make
include $(bender path clint)/clint.mk

# Alternative number of cores
CLINTCORES = 4

# Alternative register config template
$(CLINTROOT)/data/clint.hjson.tpl: config/clint.hjson.tpl
    cp $< $@

# Rebuild CLINT RTL
all: clint
```
