# 80186 on DE1-SoC

Intel 80186 CPU implementation on Terasic DE1-SoC (Cyclone V). Target: scale to a **full computer** capable of running **MS-DOS** and displaying output on an **external monitor** via VGA.

## Goals

- **Phase 1:** Minimal 80186 CPU + memory + board bring-up (see [PLANNING.md](PLANNING.md)).
- **Phase 4 (full computer):** PC-style memory map (RAM, VRAM, BIOS ROM), VGA (80×25 text mode), PS/2 keyboard, so MS-DOS can boot and run on an external monitor. See [docs/FULL_COMPUTER.md](docs/FULL_COMPUTER.md).

## References

- `80186_datasheet.pdf` — 80186/80188 datasheet.
- `intel-8086_datasheet.pdf` — 8086 reference.
- [PLANNING.md](PLANNING.md) — Block order (top-down and bottom-up).
- [docs/FULL_COMPUTER.md](docs/FULL_COMPUTER.md) — Memory map, VGA, keyboard, MS-DOS scaling.
- [docs/PIPELINE_EXAMPLE.md](docs/PIPELINE_EXAMPLE.md) — 80186 execution model (BIU/EU, queue, bus cycles).
- [docs/ALU_ARCHITECTURE.md](docs/ALU_ARCHITECTURE.md) — ALU features and I/O pins.

## Board

Terasic DE1-SoC (Cyclone V 5CSEMA5F31C6). Top-level entity: **FPGA80186** (`modules/top.sv`). Pins: CLOCK_50, KEY, LED, VGA (R/G/B, HS, VS, CLK, BLANK_N, SYNC_N), PS/2 (CLK, DAT) for full-computer scaling.
