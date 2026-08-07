# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## 0.3.0 - 2026-08-07
### Changed
- Replace configuration registers with SystemRDL, generated with `peakrdl`
- Parametrize number of harts in SystemRDL file.
- Change to interface from `register_interface` to standard AMBA APB.
- Improve integration via `clint.mk` make fragment, which allows easier reconfiguration of number of harts with automatic regeneration of the configuration registers.

## 0.2.0 - 2023-08-03
### Changed
- Make pending bits standalone 32-bit registers to conform with ACLINT spec.
- Switch to Chipsalliance's Verible linting action.

## 0.1.0 - 2022-08-29
### Changed
- Update to IP variant from Snitch repository which uses register_interface.

### Added
- Add basic testbench.
- Add CI.
- Add make fragment for easy reconfiguration.
