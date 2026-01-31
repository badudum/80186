# 80186 Execution Model — Per 80186 Datasheet

This document describes how the **80186** CPU executes instructions and interfaces to the bus **as specified in the Intel 80186/80188 High-Integration 16-Bit Microprocessors datasheet** (Order Number 272430-002, November 1994). It is written for implementing the 80186 on FPGA; the 8086 is cited only where the 80186 datasheet references it (e.g. “Enhanced 8086-2 CPU”, ALE timing comparison).

**Primary reference:** `80186_datasheet.pdf` — Functional Description (p.9–12), Pin Descriptions Table 1 (p.4–8), A.C. Characteristics and Waveforms (p.16–24), Execution Timings (p.25–26), Instruction Set Summary (p.27+).

---

## 1. 80186 Base Architecture (Datasheet p.9)

From the **Functional Description — Introduction**:

> "The following Functional Description describes the **base architecture of the 80186**. The 80186 is a very high integration 16-bit microprocessor. It combines 15–20 of the most common microprocessor system components onto one chip while providing **twice the performance** of the standard 8086. The 80186 is **object code compatible** with the 8086/8088 microprocessors and **adds 10 new instruction types** to the 8086/8088 instruction set.  
> For more detailed information on the architecture, please refer to the **80C186XL/80C188XL User's Manual**. The 80186 and the 80186XL devices are **functionally and register compatible**."

So for implementation: **80186 = enhanced 8086-2 CPU** plus integrated peripherals (clock, DMA, interrupt controller, timers, chip-select/ready, local bus controller). The **CPU core** follows the same two-unit (BIU + EU) and prefetch-queue model as the 8086; the 80186 datasheet specifies **bus timing**, **READY** (SRDY/ARDY), **queue**, **RESET**, and **instruction timings** for the 80186.

---

## 2. Execution Timings and Queue (80186 Datasheet p.25–26)

From **EXECUTION TIMINGS**:

- Program execution timing depends on **bus cycles for prefetching instructions** and **execution unit cycles** for executing instructions.
- The instruction timings in the datasheet are **minimum execution time in clock cycles** and assume:
  - The **opcode**, and any **data or displacement** required, **has been prefetched and resides in the queue** when needed.
  - **No wait states** or bus **HOLD**s.
  - **Word data on even-address boundaries** (odd-aligned word adds 4 clocks per memory transfer per footnote).
- **Memory instructions:** "All instructions which involve memory accesses can also require **one or two additional clocks** above the minimum timings shown due to the **asynchronous handshake between the bus interface unit (BIU) and execution unit**."
- **Jumps and calls:** Include the time to fetch the opcode of the **next instruction at the destination address**.
- **80186:** "The 80186 has sufficient bus performance to ensure that an adequate number of prefetched bytes will reside in the queue **(6 bytes)** most of the time. Therefore, actual program execution time will not be substantially greater than that derived from adding the instruction timings shown."
- **80188:** 4-byte queue; execution time may be substantially greater.

So for the 80186: **6-byte prefetch queue**; BIU keeps it filled; EU consumes; **memory ops add 1–2 clocks** for BIU–EU handshake; instruction timings in the **Instruction Set Summary** (80186 column) apply when the instruction is already in the queue.

---

## 3. Clock and RESET (80186 Datasheet p.9, Table 1)

- **Clock:** On-chip clock generator; oscillator (X1/X2) or external clock on X1; **divide-by-two** → **CLKOUT** (50% duty cycle). **All device pin timings are specified relative to CLKOUT.**
- **RES (input):** Active RES terminates present activity and clears internal logic. **For proper initialization**, VCC must be in spec and the **clock must be stable for more than 4 clocks with RES held LOW**. RES is internally synchronized; **Schmitt-trigger** input for power-on RES (e.g. RC).
- **RESET (output):** Active HIGH; synchronized to processor clock. **Guaranteed to remain active for at least five clocks** given a RES input of at least six clocks.
- **First fetch:** "The processor begins fetching instructions **approximately 6½ clock cycles** after RES is returned HIGH."

---

## 4. Local Bus Controller and Bus Cycles (80186 Datasheet p.9–10, Table 1)

From **LOCAL BUS CONTROLLER** and **Memory/Peripheral Control**:

- The 80186 provides a **local bus controller** that generates **ALE**, **RD**, and **WR**.
- **No M/IO pin:** "The local bus controller does not provide a memory/I/O signal. If this is required, use the **S2** signal (which will require external latching), make the memory and I/O spaces nonoverlapping, or use only the integrated chip-select circuitry."
- **HOLD/HLDA:** Bus arbitration; processor issues **HLDA** at the end of **T4 or Ti**; simultaneously floats the local bus and control lines. When HOLD goes LOW, HLDA is lowered; when the processor needs another bus cycle, it drives the bus again.

**Bus cycle (from 80186 pin descriptions and waveforms):**

- **T1:** Address (and BHE, A0) on AD bus; **ALE** active. **ALE rising edge** is generated **one-half clock cycle earlier than in the 8086** (off the CLKOUT rising edge immediately preceding T1). Trailing edge of ALE: address valid for latching (as in 8086). **ALE is never floated.**
- **T2, T3, TW, T4:** Address removed; RD or WR active (T2–T3–TW); data transfer; **READY** (SRDY or ARDY) sampled for wait states (TW); T4 completes the cycle.
- **Ti:** Idle cycles between bus cycles.

**What floats during HOLD or RESET:** DEN, RD, WR, S0–S2, LOCK, AD0–AD15, A16–A19, BHE, DT/R. **ALE is driven LOW during RESET** and is never floated.

**S2, S1, S0 (80186 Table 1):**

| S2 | S1 | S0 | Bus cycle |
|----|----|----|-----------|
| 0 | 0 | 0 | Interrupt Acknowledge |
| 0 | 0 | 1 | Read I/O |
| 0 | 1 | 0 | Write I/O |
| 0 | 1 | 1 | Halt |
| 1 | 0 | 0 | Instruction Fetch |
| 1 | 0 | 1 | Read Data from Memory |
| 1 | 1 | 0 | Write Data to Memory |
| 1 | 1 | 1 | Passive (no bus cycle) |

S2 can be used as M/IO with external latching.

**BHE and A0 encodings (80186 only, Table 1):**

| BHE | A0 | Function |
|-----|----|----------|
| 0 | 0 | Word transfer |
| 0 | 1 | Byte on upper half (D15–D8) |
| 1 | 0 | Byte on lower half (D7–D0) |
| 1 | 1 | Reserved |

---

## 5. READY: SRDY and ARDY (80186 Datasheet Table 1, p.10)

The 80186 has **two** ready inputs:

- **ARDY (Asynchronous Ready):** Active HIGH. Rising edge can be asynchronous to CLKOUT; **falling edge must be synchronized** to the processor clock. Tying ARDY HIGH always asserts ready. If unused, tie LOW so **SRDY** controls ready.
- **SRDY (Synchronous Ready):** Active HIGH; **synchronized to CLKOUT**. Use of SRDY allows **relaxed system timing** over ARDY by eliminating the half-clock needed to synchronize ARDY internally. If unused, tie LOW so ARDY controls ready.

In addition, the **chip-select/ready logic** (see below) can **program WAIT states** (0–3) per memory/peripheral block and can factor in or ignore external READY per range.

---

## 6. Chip-Select and Programmable Wait States (80186 Datasheet p.10)

The 80186 integrates **programmable chip-select and READY generation**:

- **Memory chip selects:** **UCS** (upper memory), **LCS** (lower memory), **MCS0–MCS3** (mid-range). Address ranges and sizes are programmable (e.g. 1K–256K for UCS/LCS; 8K–512K for MCS).
- **Peripheral chip selects:** **PCS0–PCS6** (seven 128-byte blocks above a programmable base in memory or I/O). PCS5/PCS6 can be programmed as latched A1/A2 instead.
- **READY/WAIT:** For each chip-select range, the number of **WAIT states** (0–3) is **programmable**. External READY can be **ignored** or **factored** with the internal ready generator per range.
- **Reset:** On RESET, **UCS** is programmed to a **1K block** with READY control bits that **insert 3 wait states in conjunction with external READY** (UMCS resets to FFFBH). Other chip-select/READY registers have no predefined value until the CPU accesses their control registers.

So for a minimal 80186 implementation you can drive **SRDY** (or ARDY) from external memory; for full 80186 compatibility you can add the internal chip-select and programmable wait-state logic.

---

## 7. Instruction Prefetch Queue and Queue Status (80186 Datasheet Table 1)

- **Prefetch queue:** 6 bytes (80186); filled by BIU when there is room; EU consumes instruction bytes. (Same conceptual model as 8086; 80186 Execution Timings state “6 bytes” for 80186.)
- **ALE/QS0 and WR/QS1:** These pins normally carry **ALE** and **WR**. If **RD is tied to GND**, the processor is in **Queue Status Mode**: at reset the pin is sampled; if RD=GND, the processor outputs **queue status** on ALE/QS0 and WR/QS1 instead of ALE and WR:
  - **QS1, QS0:** 00 = No operation; 01 = First opcode byte fetched from queue; 11 = Subsequent byte from queue; 10 = Empty the queue.
- **LOCK (Table 1):** "**No instruction prefetching will occur while LOCK is asserted.**" When executing more than one LOCK instruction, there must be **6 bytes of code** between the end of the first LOCK instruction and the start of the second.

---

## 8. Instruction Set and Timings (80186 Datasheet p.27+)

The **Instruction Set Summary** gives **80186** and **80188** clock-cycle columns. Use the **80186** column. Assumptions (as in Execution Timings): prefetched, no wait states, word data even-aligned. For byte/word: footnote “*Clock cycles shown for byte transfers; for word operations, add 4 clock cycles for each memory transfer.”

**Examples from 80186 Instruction Set Summary:**

| Function | Example | 80186 (cycles) | Note |
|----------|---------|----------------|------|
| MOV immediate to register | MOV AX, 0x1234 (B8 34 12) | 3/4 | 8/16-bit |
| ADD reg/mem with register | ADD AX, BX (01 D8) | 3/10 | reg-reg 3; mem 10 |
| MOV accumulator to memory | MOV [addr], AX (A3 lo hi) | 9 | +1–2 handshake |
| JMP rel16 | E9 disp-lo disp-hi | (in table) | includes fetch at target |
| PUSHA | 60 (80186-only) | 36 | Push all GPRs |
| POPA | 61 (80186-only) | 51 | Pop all GPRs |

Shaded rows in the datasheet are **80186/80188-only** (e.g. PUSHA, POPA, ENTER, LEAVE, BOUND); implement these for full 80186 compatibility.

---

## 9. Detailed Example (80186-Focused)

**Program:**

| CS:IP   | Instruction        | Bytes (hex) | Description           |
|---------|--------------------|-------------|------------------------|
| 1000:0000 | MOV AX, 0x1234   | B8 34 12   | AX ← 0x1234           |
| 1000:0003 | ADD AX, BX       | 01 D8      | AX ← AX + BX           |
| 1000:0005 | MOV [0x0100], AX | A3 00 01   | Store AX at DS:0x0100  |
| 1000:0008 | JMP 0x0000      | E9 F5 FF   | IP ← 0x0000 (relative) |

**Assumptions:** CS=0x1000, DS=0x2000, BX=0x0002; **SRDY** (or ARDY) asserted in time (no wait states); physical code at 0x10000, DS:0x0100 → 0x20100.

1. **After RESET:** Fetch begins ~6½ clocks after RES goes HIGH. IP=0x0000; queue empty. BIU runs **word fetch** at 0x10000 (T1–T4 per 80186 timing). Two bytes (B8 34) enter queue. BIU continues prefetch when ≥2 bytes free (e.g. 12 01 at 0x10002). Queue: B8 34 12 01 …; IP advanced by BIU.

2. **MOV AX, 0x1234:** EU takes B8, 34, 12 from queue. Decodes MOV reg,imm (16-bit). Executes AX ← 0x1234. **3 cycles** (80186 table: Immediate to register, 16-bit). Next instruction at 01 D8 … in queue.

3. **ADD AX, BX:** EU takes 01 D8. Decodes ADD r/m16,r16 (AX,BX). Reads AX, BX; ALU; writes AX, flags. **3 cycles** (reg-reg). Queue has A3 00 01 … from prefetch.

4. **MOV [0x0100], AX:** EU takes A3 00 01. Decodes MOV moff16, AX. Computes address DS:0x0100 → 0x20100. Requests **write** bus cycle from BIU. BIU runs one cycle: T1 (address 0x20100, BHE/A0 for word), T2–T4, WR active; **SRDY** (or ARDY) in time. **9 cycles** minimum (Accumulator to memory) + up to 2 for BIU–EU handshake. EU completes; IP=0x0008.

5. **JMP 0x0000:** EU takes E9 F5 FF. Decodes JMP rel16. New IP = 0x0008 + 3 + (-11) = 0x0000. **Queue flushed.** BIU fetches from new CS:IP (0x10000). First word (B8 34) into queue; EU can start MOV AX,0x1234 again. JMP timing in the table includes fetch of the next opcode at the destination.

This follows the 80186 model: **BIU** (bus cycles T1–T4/TW/Ti, 6-byte queue, ALE one-half clock early), **EU** (execution unit cycles from Instruction Set Summary), **READY** via SRDY/ARDY (and optionally chip-select/ready), and **1–2 extra clocks** for memory instructions due to BIU–EU handshake.

---

## 10. Mapping to Implementation Modules

| 80186 datasheet item | Module(s) | Responsibility |
|----------------------|-----------|----------------|
| Clock, RESET         | clk_rst.sv | CLKOUT (50% duty); RES ≥4 clocks, RESET out ≥5; first fetch ~6½ clocks after RES HIGH. |
| Local bus controller | biu.sv     | ALE (rising edge ½ clk before T1), RD, WR; T1–T4, TW, Ti; S0–S2; BHE, A0; address/data multiplexing. |
| Prefetch queue       | biu.sv, cpu_top.sv | 6-byte FIFO; fill when ≥2 bytes free; no prefetch while LOCK; flush on branch. |
| SRDY, ARDY           | biu.sv, memory_controller.sv | Drive READY to BIU; SRDY or ARDY timing per Table 1; optional programmable wait (chip-select). |
| HOLD/HLDA            | biu.sv     | Assert HLDA at end of T4 or Ti; float bus and controls; deassert when HOLD LOW. |
| Chip-select/ready    | biu.sv or separate | UCS, LCS, MCS0–3, PCS0–6; 0–3 wait states per range; UCS reset default (1K, 3 wait with external READY). |
| EU, execution cycles | eu.sv, decode.sv, execUnit.sv, ALU.sv, reg.sv, microcode.sv | Decode, ALU, registers, flags; request operand bus cycle to BIU; 80186 instruction set including 10 new types. |
| BIU–EU handshake     | cpu_top.sv, biu.sv, eu.sv | EU requests bus cycle; BIU runs T1–T4; 1–2 extra clocks for memory ops. |

Use this document and **80186_datasheet.pdf** as the reference when implementing the 80186 CPU and bus interface on FPGA.
