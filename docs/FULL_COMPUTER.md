# Full Computer / MS-DOS Scaling — DE1-SoC

Target: Scale the 80186 system so it can run **MS-DOS** and display output on an **external monitor** via VGA. This document describes the **memory map**, **I/O**, **VGA**, **keyboard**, and **BIOS** layout needed to reach a full PC-compatible-style computer on the DE1-SoC.

Reference: PC/AT memory map, IBM VGA, MS-DOS requirements. Board: Terasic DE1-SoC (Cyclone V, VGA connector, PS/2, SDRAM/SRAM).

---

## 1. Goal

- **80186 CPU** (already planned) with full instruction set and bus.
- **Memory map** compatible with PC-style layout: conventional RAM, video RAM (VRAM), option ROM, BIOS ROM, reset vector at FFFF0h.
- **VGA** output to drive an external monitor (80×25 text mode for MS-DOS; optionally 640×480 graphics).
- **Keyboard** input (PS/2 on DE1-SoC) for MS-DOS.
- **BIOS ROM** area (e.g. F0000h–FFFFFh) loadable with a minimal BIOS that boots MS-DOS (or a stub that jumps to DOS).
- **Storage** (optional later): SD card or similar for disk image (FAT12/FAT16) to load MS-DOS.

---

## 2. PC-Style Memory Map (1 MB)

| Address range (hex) | Size | Region | Purpose |
|---------------------|------|--------|---------|
| 00000 – 9FFFF | 640 KB | **Conventional RAM** | MS-DOS programs, DOS kernel, TSRs. |
| A0000 – BFFFF | 128 KB | **Video RAM (VRAM)** | VGA framebuffer. Text mode 3: B8000–B8FFF (4 KB typical). Graphics: A0000+ (EGA/VGA). |
| C0000 – EFFFF | 192 KB | **Option ROM / Extended BIOS** | Video BIOS, network ROMs; can be RAM or ROM. |
| F0000 – FFFFF | 64 KB | **BIOS ROM** | System BIOS. **Reset vector: FFFF0h** (jump to POST/boot). |

**Reset:** 80186 starts at CS:IP = FFFF:0000 → physical **FFFF0h**. BIOS at FFFF0h must contain a jump to the POST/boot routine.

**Scaling from Phase 1:** Start with a small RAM (e.g. 64 KB at 00000), no VRAM/ROM; then add VRAM at B8000 for text mode; then add ROM at F0000–FFFFF with a minimal BIOS; then expand conventional RAM toward 640 KB and add SDRAM if needed.

---

## 3. VGA (External Monitor)

- **DE1-SoC:** VGA connector (check board manual for pin names: typically VGA_R[9:0], VGA_G[9:0], VGA_B[9:0], VGA_HS, VGA_VS, VGA_BLANK_N, VGA_SYNC_N, VGA_CLK).
- **Text mode (mode 3):** 80×25, 16 colors. Character buffer at **0xB8000** (segment 0xB800). Each character: 2 bytes (ASCII + attribute). 80×25×2 = 4000 bytes. VGA controller reads this region and generates HSYNC, VSYNC, and pixel stream; font ROM or hardcoded font for glyphs.
- **Resolution:** 640×480 @ 60 Hz (or 720×400 for text) per VGA standard. Pixel clock ~25.175 MHz (or 28.322 MHz for 720×400); derive from PLL.
- **Modules:** `vga_controller` (timing + pixel output) and dual-port **VRAM** (CPU writes at 0xB8000, VGA reads for display). Memory controller or separate **video** subsystem decodes 0xA0000–0xBFFFF and routes CPU writes to VRAM; VGA reads VRAM on the other port.

---

## 4. Keyboard (PS/2)

- **DE1-SoC:** PS/2 connector (PS2_CLK, PS2_DAT). Use for keyboard only (mouse optional later).
- **PC compatibility:** Keyboard controller at I/O **0x60** (data), **0x64** (status/command). BIOS and MS-DOS read scan codes from 0x60. Implement a simple **PS/2 receiver** that stores the last scan code in a register; CPU reads it via I/O 0x60. Optionally: 8259-compatible interrupt (IRQ1) when key pressed.
- **Module:** `ps2_keyboard` or `keyboard_controller` — PS2_CLK/PS2_DAT in, I/O port 0x60/0x64 or memory-mapped register for CPU.

---

## 5. I/O Map (PC-Style, Summary)

| I/O range (hex) | Purpose |
|-----------------|--------|
| 0x00 – 0x1F | DMA (80186 has internal DMA; external 8237 optional). |
| 0x20 – 0x21 | 8259 PIC (80186 has integrated interrupt controller; map if needed for PC compat). |
| 0x40 – 0x43 | 8253/8254 timer (system tick for MS-DOS; 80186 has internal timers — can emulate or use internal). |
| 0x60, 0x64 | Keyboard (data, status). |
| 0x3B0 – 0x3DF | VGA (CRTC, sequencer, etc.; optional for mode switches). |
| 0x3F8 – 0x3FF | COM1 (optional, for serial). |

For minimal MS-DOS: **keyboard (0x60/0x64)** and **timer tick** (internal 80186 timer or 8253 emulation) are the most important; VGA is memory-mapped at 0xB8000.

---

## 6. Block Diagram (Full Computer)

```
                    DE1-SoC FPGA
┌─────────────────────────────────────────────────────────────────┐
│  FPGA80186 (top.sv)                                              │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐  │
│  │ clk_rst     │  │ cpu_top     │  │ memory_controller        │  │
│  │ (PLL, RES)  │  │ (BIU + EU)  │  │ (decode → RAM/VRAM/ROM) │  │
│  └──────┬──────┘  └──────┬──────┘  └───────────┬─────────────┘  │
│         │                │                      │                 │
│         │                │    system bus        │                 │
│         │                │ (addr, data, RD, WR) │                 │
│         │                └─────────────────────┼─────────────────┤
│         │                                       │                 │
│         │                ┌──────────────────────┼─────────────────┤
│         │                │                      ▼                 │
│         │                │  ┌─────────────┐  ┌─────────────┐      │
│         │                │  │ RAM         │  │ VRAM        │      │
│         │                │  │ 0x00000–    │  │ 0xB8000     │      │
│         │                │  │ 0x9FFFF     │  │ (dual-port) │      │
│         │                │  └─────────────┘  └──────┬──────┘      │
│         │                │                          │             │
│         │                │  ┌─────────────┐         │             │
│         │                │  │ ROM/BIOS    │         │             │
│         │                │  │ F0000–FFFFF  │         │             │
│         │                │  └─────────────┘         │             │
│         │                │                          ▼             │
│         │                │                   ┌─────────────┐      │
│         │                │                   │ vga_controller     │
│         │                │                   │ (timing, font)     │
│         │                │                   └──────┬──────┘      │
│         │                │                          │             │
│         │                │  ┌─────────────┐         │             │
│         │                │  │ keyboard    │         │             │
│         │                │  │ (PS/2→0x60) │         │             │
│         │                │  └─────────────┘         │             │
│         └────────────────┴─────────────────────────┴─────────────┤
│                                                                   │
│  Pins: CLOCK_50, KEY, LED, VGA_*, PS2_*, (SRAM/SDRAM)             │
└───────────────────────────────────────────────────────────────────┘
```

---

## 7. Implementation Phases (Scaling)

| Phase | Scope | Memory | Video | I/O |
|-------|--------|--------|-------|-----|
| 1 (current) | Minimal CPU | Small RAM (e.g. 64 KB) | — | — |
| 2 | Bus + instructions | Expand RAM (e.g. 256 KB) | — | — |
| 3 | Full computer prep | Memory map: RAM + VRAM + ROM regions | VGA controller stub; VRAM at B8000 | — |
| 4 | MS-DOS capable | 640 KB conventional + ROM at F0000–FFFFF | 80×25 text mode; font | Keyboard (0x60/0x64); timer tick |
| 5 (optional) | Storage | — | — | SD card for disk image |

Use **docs/FULL_COMPUTER.md** and **PLANNING.md** Phase 4 when implementing the memory controller (decode to RAM/VRAM/ROM), VGA controller, and keyboard so the system can scale to a full computer and run MS-DOS on an external monitor.
