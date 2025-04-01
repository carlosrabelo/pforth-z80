# pForth

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Interactive FIG-FORTH compiler and interpreter written in Z80 assembly. Runs on the z88dk-ticks simulator.

## Highlights

- Interactive pFORTH command-line compiler and interpreter
- Indirect-threaded inner interpreter (NEXT, DOCOL, EXIT) with TOS cached in DE
- Core dictionary: stack, memory, math, compiler, and control-flow primitives
- I/O via Z80 ports (`IN A,(1)` / `OUT (1),A`) with `z88dk-ticks -iochar=1`
- Assembly test harness executed on z88dk-ticks
- Highly modular dictionary and easily extensible primitive set

## Prerequisites

- **sjasmplus** — Z80 assembler (preferred); Debian `z80asm` is an accepted fallback
- **z88dk-ticks** — Z80 command-line simulator (`z88dk-ticks -iochar=1`)
- **Python 3.10+** — required for the assembly test runner

## Installation

### Build from Source

```bash
git clone https://github.com/carlosrabelo/pforth.git
cd pforth
make build
```

## Usage

### Build and run

```bash
make run
```

### Build only

```bash
make build
```

This assembles the Z80 modules into a binary:

```bash
# Run Z80 binary on z88dk-ticks
z88dk-ticks -iochar=1 -l 0 -pc 0 bin/pforth.bin
```

## Project Layout

```
src/                # Z80 assembly sources
tests/              # Assembly test suites and Python test runner
demos/              # Forth demonstration programs
bin/                # Assembled binary output (git-ignored)
Makefile            # Build orchestrator
.make/              # Build helper scripts
```

## Development

```bash
make help              # Show available targets
make build             # Assemble Z80 sources
make test              # Build, check sources and labels; run assembly tests if z88dk-ticks is installed
make run               # Build and run on z88dk-ticks
make clean             # Remove build artifacts
```

## License

This project is licensed under the MIT License — see [LICENSE](LICENSE) for details.
