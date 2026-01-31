# 80186 ALU Architecture Overview

Reference: **80186/80188 Instruction Set Summary** (80186_datasheet.pdf, p.27+). This document lists the **full set of features** the ALU must support, **clock-cycle context** (instruction timings; ALU may be combinational or 1-cycle for simple ops, multi-cycle for MUL/DIV), and **suggested input/output pins**. No implementation.

---

## 1. Operand Size

The 80186 uses **8-bit (byte)** and **16-bit (word)** operands. Many instructions have a **w** bit in the opcode (w=0 byte, w=1 word). The ALU must support both:

- **Byte:** Operands and result on low 8 bits; upper 8 bits ignored or zero/sign-extended as per instruction (e.g. CBW, CWD).
- **Word:** Full 16-bit operands and result.

So the ALU needs a **width control** (e.g. 8 or 16 bit) so that flags and result are computed for the active width.

---

## 2. Block Diagram

High-level structure of the 80186 ALU (single-cycle arithmetic/logic and one shift step; optional multi-cycle MUL/DIV). Data flows left to right; **op** selects which block drives the result and how flags are computed.

```
                    ┌─────────────────────────────────────────────────────────────────────────┐
                    │                           ALU (80186)                                   │
  ┌──────────────┐  │                                                                         │  ┌──────────────┐
  │ clk, rst_n   │──┼──► (optional: register result/flags for 1-cycle latency)                 │  │ result [15:0]│
  │ op [4:0]     │──┼───────────────────────────────────────────────────────────────────────► │  │ cf, pf, af   │
  │ w (word)     │  │     ┌─────────────┐                                                    │  │ zf, sf, of   │
  │ a [15:0]     │──┼────►│ Operand     │     ┌──────────────┐     ┌──────────────┐          │  │ (busy)       │
  │ b [15:0]     │──┼────►│ prep        │────►│ Arithmetic   │     │ Logic        │          │  └──────────────┘
  │ cf_in        │──┼────►│ (byte/word  │     │ ADD,ADC,SUB, │     │ AND,OR,XOR,   │          │
  │ shift_cnt[4:0]│─┼────►│  mask/ext)  │     │ SBB,CMP,INC, │     │ NOT,TEST      │          │
  └──────────────┘  │     └──────┬──────┘     │ DEC,NEG      │     └───────┬──────┘          │
                    │            │            └──────┬───────┘             │                 │
                    │            │                   │                     │                 │
                    │            │            ┌──────▼───────┐     ┌───────▼──────┐          │
                    │            └───────────►│ Shift/Rotate │     │ Result mux   │◄──────────┼── op selects
                    │                         │ SHL,SHR,SAR  │     │ (select arith,│          │   which result
                    │                         │ ROL,ROR,     │     │  logic, shift │          │   and flags
                    │                         │ RCL,RCR      │     └───────┬───────┘          │
                    │                         │ (1 step/clk)  │             │                 │
                    │                         └──────┬───────┘             │                 │
                    │                                │                     ▼                 │
                    │                         ┌──────▼──────────────────────▼──────┐          │
                    │                         │ Flag logic                         │          │
                    │                         │ CF, PF, AF, ZF, SF, OF from result │          │
                    │                         │ (and cf_in for ADC,SBB,RCL,RCR)    │          │
                    │                         └───────────────────────────────────┘          │
                    │                                                                         │
                    │  (Optional)  ┌──────────────┐                                           │
                    │              │ MUL/DIV      │──► busy, result_hi, (div_zero)            │
                    │  a,b,op ────►│ multi-cycle  │                                           │
                    │              └──────────────┘                                           │
                    └─────────────────────────────────────────────────────────────────────────┘
```

### Block roles

| Block | Role |
|-------|------|
| **Operand prep** | Use **w** to select 8-bit (low byte of A, B) or 16-bit operands; zero/sign-extend or mask for byte ops. Feed prepared A, B (and **cf_in** where needed) to arithmetic, logic, and shift/rotate. |
| **Arithmetic** | ADD, ADC, SUB, SBB, CMP, INC, DEC, NEG. Uses **cf_in** for ADC/SBB. Outputs result (discarded for CMP) and raw carry/overflow for flag logic. |
| **Logic** | AND, OR, XOR, NOT, TEST. Outputs result (discarded for TEST) and zero/sign/parity for flag logic (CF=0, AF=0, OF=0 for logic ops). |
| **Shift/Rotate** | SHL, SHR, SAR, ROL, ROR, RCL, RCR. One shift/rotate step per cycle; **shift_cnt** = 1 for “by 1” or execUnit loops for “by CL”. Uses **cf_in** for RCL/RCR. Outputs result and CF (and ZF, SF, PF, OF for last step of multi-step shifts). |
| **Result mux** | **op** selects arithmetic result, logic result, or shift/rotate result as **result**. For CMP/TEST, result is discarded externally; flags still valid. |
| **Flag logic** | From selected result (and **cf_in** for ADC, SBB, RCL, RCR): compute CF, PF (even parity low 8 bits), AF (bit 4 carry), ZF, SF (MSB), OF (signed overflow). NOT does not change flags. |
| **MUL/DIV** (optional) | Multi-cycle block; **busy** high until done; **result** and **result_hi** (and **div_zero** for DIV) when complete. Omit if execUnit does MUL/DIV with repeated ADD/SUB/SHL. |

---

## 3. Full Set of Operations (From 80186 Instruction Set)

### 3.1 Arithmetic (Binary)

| Operation | Description | Instruction cycles (80186) | ALU use |
|-----------|-------------|----------------------------|---------|
| **ADD**   | A + B       | 3 (reg-reg) / 10 (mem)     | One ALU cycle (combinational or 1 cycle). |
| **ADC**   | A + B + CF  | 3/10                        | One ALU cycle; **needs CF in**. |
| **SUB**   | A − B       | 3/10                        | One ALU cycle. |
| **SBB**   | A − B − CF  | 3/10                        | One ALU cycle; **needs CF in**. |
| **CMP**   | A − B, flags only, no result | 3/10              | Same as SUB; result discarded; **flags only**. |

### 2.2 Arithmetic (Unary)

| Operation | Description | Instruction cycles | ALU use |
|-----------|-------------|--------------------|---------|
| **INC**   | A + 1       | 3 (reg) / 3–15 (mem) | One ALU cycle (add 1). |
| **DEC**   | A − 1       | 3 (reg) / 3–15 (mem) | One ALU cycle (subtract 1). |
| **NEG**   | 0 − A (two’s complement) | 3/10 | One ALU cycle (subtract from 0 or equivalent). |

### 3.3 Logic

| Operation | Description | Instruction cycles | ALU use |
|-----------|-------------|--------------------|---------|
| **AND**   | A ∧ B       | 3/10                | One ALU cycle. |
| **OR**    | A ∨ B       | 3/10                | One ALU cycle. |
| **XOR**   | A ⊕ B       | 3/10                | One ALU cycle. |
| **NOT**   | ¬A (one’s complement) | 3/10           | One ALU cycle; no flags (80186: NOT does not change flags). |
| **TEST**  | A ∧ B, flags only, no result | 3/10        | Same as AND; result discarded; **flags only**. |

### 3.4 Shifts and Rotates

Mod bits **TTT** in instruction encoding (80186 Instruction Set Summary):

| TTT | Instruction | Description | Instruction cycles | ALU use |
|-----|-------------|-------------|--------------------|---------|
| 100 | **SHL / SAL** | Logical/arithmetic left (same); CF = MSB out | 2/15 (by 1), 5+4n / 17+4n (by CL) | 1 cycle per shift step; **count** 1–31 (or 1 only for “by 1”). |
| 101 | **SHR**      | Logical right; CF = LSB out | Same | 1 cycle per shift step. |
| 111 | **SAR**      | Arithmetic right (sign extend); CF = LSB out | Same | 1 cycle per shift step. |
| 000 | **ROL**      | Rotate left; CF = MSB out | Same | 1 cycle per step; **CF in/out**. |
| 001 | **ROR**      | Rotate right; CF = LSB out | Same | 1 cycle per step. |
| 010 | **RCL**      | Rotate left through CF | Same | 1 cycle per step; **CF in and out**. |
| 011 | **RCR**      | Rotate right through CF | Same | 1 cycle per step; **CF in and out**. |

Shifts by **CL** or by **immediate count** take **5+4n** (reg) or **17+4n** (mem) cycles—the ALU typically does **one shift per clock**; the execution unit (execUnit) loops **n** times for count **n**. So the ALU needs a **shift/rotate count** input (e.g. 1 for “by 1”, or full 5-bit count); multi-step shifts are driven by execUnit over multiple cycles.

### 3.5 Multiply and Divide (Multi-Cycle)

| Operation | Description | Instruction cycles (80186) | ALU use |
|-----------|-------------|----------------------------|---------|
| **MUL**   | Unsigned: AX × r/m8 → AX (byte) or DX:AX × r/m16 → DX:AX (word) | 26–28 (byte), 35–37 (word) | **Multi-cycle** (e.g. shift-add); ALU used repeatedly or separate multiplier. |
| **IMUL**  | Signed multiply (same formats + immediate forms) | 25–28 (byte), 34–37 (word), 22–25/29–32 (immed) | Same as MUL; multi-cycle. |
| **DIV**    | Unsigned: AX ÷ r/m8 → AL, AH; or DX:AX ÷ r/m16 → AX, DX | 29 (byte), 38 (word) | **Multi-cycle** (e.g. repeated subtract/shift); ALU or separate divider. |
| **IDIV**   | Signed divide | 44–52 (byte), 53–61 (word) | Multi-cycle. |

So the ALU either: (a) exposes **MUL/DIV** as multi-cycle operations (with **busy** and multiple cycles), or (b) the execution unit implements MUL/DIV using repeated ADD/SUB/SHL (and the ALU only does single-cycle ops). Either way, the **ALU’s single-cycle interface** is enough for everything else; MUL/DIV are a design choice (dedicated multi-cycle block vs. sequencer using ADD/SUB/SHL).

### 2.6 BCD/ASCII Adjust (Use ALU + Flags)

| Instruction | Description | Instruction cycles | ALU use |
|-------------|-------------|--------------------|---------|
| **DAA**    | Decimal adjust after ADD | 4 | Uses ALU result + AF, CF; correction add. |
| **DAS**    | Decimal adjust after SUB | 4 | Uses result + AF, CF; correction. |
| **AAA**    | ASCII adjust after ADD | 8 | Uses AL, AF, CF; correction. |
| **AAS**    | ASCII adjust after SUB | 7 | Same idea. |
| **AAM**    | ASCII adjust after MUL | 19 | Division-like (divide by 10). |
| **AAD**    | ASCII adjust before DIV | 15 | Multiply-like (multiply by 10). |

These can be implemented in the execution unit using the ALU (add/sub and flags); the ALU itself only needs to support the underlying add/sub and flag outputs (AF, CF, etc.).

### 3.7 Sign/Zero Extend (Simple)

| Instruction | Description | Cycles | ALU use |
|-------------|-------------|--------|---------|
| **CBW** | Sign-extend AL → AX | 2 | Can be ALU “pass A, sign-extend” or simple wire. |
| **CWD** | Sign-extend AX → DX:AX | 4 | Same idea. |

Optional: one “sign-extend” or “zero-extend” mode, or handled in reg/execUnit.

---

## 4. Flags (80186/8086)

The ALU must **output** (and for some ops **input**) the following flags as per the 80186:

| Flag | Name | Meaning (brief) | ALU role |
|------|------|------------------|----------|
| **CF** | Carry | Carry out (add/sub) or last bit out (shift/rotate) | **Output** for ADD, SUB, ADC, SBB, shifts, rotates; **input** for ADC, SBB, RCL, RCR. |
| **PF** | Parity | Even parity of low 8 bits of result | **Output** (ALU computes). |
| **AF** | Auxiliary carry | Carry between bits 3 and 4 (BCD) | **Output** for ADD, SUB, ADC, SBB, INC, DEC. |
| **ZF** | Zero | Result = 0 | **Output**. |
| **SF** | Sign | MSB of result | **Output**. |
| **OF** | Overflow | Signed overflow (two’s complement) | **Output** for ADD, SUB, ADC, SBB, INC, DEC, NEG, shifts. |

**TF, IF, DF** are not produced by the ALU (they are CPU control flags). So the ALU needs at least: **CF, PF, AF, ZF, SF, OF** as outputs, and **CF** as input for ADC, SBB, RCL, RCR.

---

## 5. ALU Flag Bits (Detailed)

The six flags the ALU outputs (CF, PF, AF, ZF, SF, OF) are defined as follows for the 80186/8086. **Which** flags are meaningful depends on the instruction (see §10); the ALU computes all six from the result (and **cf_in** where needed); the execution unit or microcode uses only the ones the instruction defines.

### CF — Carry Flag

- **Meaning:** For **add/subtract**: carry out of the **most significant bit** of the result (unsigned overflow). For **shifts/rotates**: the bit that was shifted or rotated **out** (e.g. MSB for SHL/ROL, LSB for SHR/ROR).
- **When set (1):** ADD/ADC produced a carry out of the MSB; SUB/SBB required a borrow into the MSB (i.e. unsigned result “wrapped”). For shifts: the last bit shifted out is 1.
- **When cleared (0):** No carry/borrow at MSB; or last bit shifted out is 0.
- **How ALU computes:** From the adder: carry out of the top bit (for add/sub). For shifts/rotates: the bit that exits the operand (MSB for left, LSB for right). For **RCL/RCR**, the new CF is the bit that moved into/out of the carry (CF is both input and output).
- **Used by:** ADD, ADC, SUB, SBB, CMP, INC, DEC, NEG; SHL, SHR, SAR, ROL, ROR, RCL, RCR; MUL (high part non-zero), IMUL (overflow). **Input** to ALU for ADC, SBB, RCL, RCR.

---

### PF — Parity Flag

- **Meaning:** **Even parity** of the **low 8 bits** of the result only (byte ops: that byte; word ops: low byte).
- **When set (1):** Number of 1s in the low 8 bits of the result is **even**.
- **When cleared (0):** Number of 1s in the low 8 bits is **odd**.
- **How ALU computes:** XOR tree (or count ones) over result[7:0]; PF = 1 if even number of 1s.
- **Used by:** ADD, ADC, SUB, SBB, CMP, INC, DEC, NEG; AND, OR, XOR, TEST; shifts (when flags are updated). NOT does not change flags. MUL/DIV: undefined for PF.

---

### AF — Auxiliary Carry Flag

- **Meaning:** Carry (or borrow) between **bit 3 and bit 4** of the 8- or 16-bit operation (BCD nibble boundary).
- **When set (1):** In add: carry from bit 3 to bit 4. In subtract: borrow from bit 4 into bit 3.
- **When cleared (0):** No carry/borrow across that boundary.
- **How ALU computes:** From the adder: carry out of bit 3 (for add) or borrow into bit 4 (for sub). Typically derived from the same adder used for the full result.
- **Used by:** ADD, ADC, SUB, SBB, CMP, INC, DEC, NEG. **Not** used by logic ops (AF=0 for AND, OR, XOR, TEST) or by shifts/rotates in the same way; DAA/DAS/AAA/AAS use AF for BCD adjust.

---

### ZF — Zero Flag

- **Meaning:** The **entire** result (8 or 16 bits, per **w**) is zero.
- **When set (1):** Result = 0.
- **When cleared (0):** Result ≠ 0.
- **How ALU computes:** NOR (or AND of bitwise NOT) over the active result bits (result[7:0] for byte, result[15:0] for word). ZF = 1 iff every bit is 0.
- **Used by:** All arithmetic, logic (except NOT), and shifts when flags are updated. Used for conditional jumps (JZ/JNZ, JE/JNE, etc.).

---

### SF — Sign Flag

- **Meaning:** **Copy of the most significant bit** of the result (interpreted as sign in two’s complement).
- **When set (1):** Result MSB = 1 (negative when interpreted as signed).
- **When cleared (0):** Result MSB = 0 (positive or zero when interpreted as signed).
- **How ALU computes:** SF = result[15] for word, result[7] for byte (the MSB of the active result).
- **Used by:** Arithmetic, logic (except NOT), shifts. Used for signed comparisons and branches (JS/JNS, JL/JGE, etc.).

---

### OF — Overflow Flag

- **Meaning:** **Signed (two’s complement) overflow**: the result cannot be represented in the same signed width as the operands.
- **When set (1):** For add: two operands with the same sign produced a result with the opposite sign. For sub: sign of result disagrees with expected sign of (A − B). For NEG: operand was −2^(width−1) (e.g. −128 for byte). For shifts: sign of result changed (e.g. SHL of positive number produced “negative” result).
- **When cleared (0):** No signed overflow.
- **How ALU computes:** For add/sub: OF = (carry into MSB) XOR (carry out of MSB). Equivalently: both operands same sign and result has opposite sign (add), or operands opposite sign and result sign equals B’s sign (sub). For NEG: OF = 1 only if operand is the minimum signed value. For SHL: OF = 1 if the **two** MSBs differ after the shift (sign changed). For SAR: OF = 0 (sign preserved). For SHR, ROL, ROR, RCL, RCR: OF is sometimes undefined or defined only on the last step; 80186 defines it for the last shift/rotate step.
- **Used by:** ADD, ADC, SUB, SBB, CMP, INC, DEC, NEG; shifts (as per 80186). Logic ops clear OF (OF=0). Used for signed branches (JO/JNO, JG/JLE, etc.).

---

### Summary: which operations affect which flags

| Flag | Arithmetic (add/sub/inc/dec/neg/cmp) | Logic (and/or/xor/test) | NOT | Shifts/Rotates |
|------|-------------------------------------|-------------------------|-----|----------------|
| CF   | Yes (carry/borrow; shift bit out)   | Cleared (0)             | —   | Yes (bit out; RCL/RCR use cf_in) |
| PF   | Yes (even parity low 8 bits)       | Yes                     | —   | Yes (when flags updated) |
| AF   | Yes (nibble carry/borrow)           | Cleared (0)             | —   | —              |
| ZF   | Yes                                 | Yes                     | —   | Yes            |
| SF   | Yes (MSB of result)                 | Yes                     | —   | Yes            |
| OF   | Yes (signed overflow)               | Cleared (0)             | —   | Yes (SHL/SAR etc. as per 80186) |

**NOT** does not modify any flags. **MUL/IMUL** define only CF and OF (others undefined); **DIV/IDIV** leave all flags undefined.

---

## 6. Clock-Cycle Summary

- **Single-cycle (combinational or 1-cycle latency):** ADD, ADC, SUB, SBB, CMP, INC, DEC, NEG, AND, OR, XOR, NOT, TEST, and **one step** of shift/rotate (by 1 or one step of many). The **instruction** takes 3+ cycles (fetch, decode, execute, etc.); the **ALU** can complete in one clock for these.
- **Multi-step (execUnit loops):** Shifts/rotates by **CL** or by immediate count: **n** cycles for count **n** (one shift per cycle).
- **Multi-cycle (many clocks):** MUL, IMUL, DIV, IDIV (26–67 cycles depending on op and size). Implement either inside the ALU (with **busy** and multiple cycles) or in the execution unit using single-cycle ALU ops.

So the ALU interface should allow: (1) **single-cycle** result and flags for arithmetic/logic and one shift step, and (2) either **multi-cycle** MUL/DIV with a **busy** output, or no MUL/DIV in the ALU (handled by execUnit).

---

## 7. Suggested Input Pins

| Pin(s) | Direction | Width | Description |
|--------|-----------|--------|-------------|
| **clk** | Input | 1 | Clock (for registered output or multi-cycle MUL/DIV if applicable). |
| **rst_n** | Input | 1 | Reset (active low); clear internal state if any (e.g. multi-cycle state). |
| **op** or **alu_op** | Input | 4–6 | Operation select: ADD, ADC, SUB, SBB, CMP, INC, DEC, NEG, AND, OR, XOR, NOT, TEST, ROL, ROR, RCL, RCR, SHL, SHR, SAR, (optional: MUL, DIV, sign_ext, etc.). Encoding is design-specific. |
| **w** or **word** | Input | 1 | Operand size: 0 = 8-bit, 1 = 16-bit. |
| **a** | Input | 16 | Operand A (full word; ALU uses low 8 or full 16 per **w**). |
| **b** | Input | 16 | Operand B (same as A). For INC/DEC/NEG/NOT, B can be ignored or driven 0/1. |
| **cf_in** | Input | 1 | Carry flag in (for ADC, SBB, RCL, RCR). |
| **shift_cnt** or **cnt** | Input | 5 | Shift/rotate count (1–31). Use 1 for “by 1”; for “by CL” execUnit supplies CL(4:0). If only “by 1” is supported in one cycle, this can be 1 bit (0=by 1, 1=multi-step) and execUnit sequences. |
| **start** or **valid** | Input | 1 | (Optional) Assert when inputs are valid; useful for registered output or multi-cycle ops. |

---

## 8. Suggested Output Pins

| Pin(s) | Direction | Width | Description |
|--------|-----------|--------|-------------|
| **result** or **y** | Output | 16 | Result (word); for byte ops only low 8 bits are meaningful; upper 8 can be zero- or sign-extended per instruction (handled in execUnit if needed). |
| **cf** | Output | 1 | Carry flag. |
| **pf** | Output | 1 | Parity flag (even parity of low 8 bits). |
| **af** | Output | 1 | Auxiliary carry. |
| **zf** | Output | 1 | Zero flag. |
| **sf** | Output | 1 | Sign flag. |
| **of** | Output | 1 | Overflow flag. |
| **busy** | Output | 1 | (Optional) Asserted during multi-cycle MUL/DIV; execUnit waits until busy deasserts. Omit if MUL/DIV are not in the ALU. |

---

## 9. Optional Pins (Design-Dependent)

- **result_hi** (16-bit): High word of 32-bit product (MUL/IMUL word) or remainder (DIV/IDIV); only if ALU does MUL/DIV internally.
- **div_zero** or **error**: For DIV/IDIV, indicate divide-by-zero or overflow; only if ALU does DIV/IDIV.
- **byte_ok**: For byte ops, indicate that upper 8 bits of **result** are zero- or sign-extended (or leave to execUnit).

---

## 10. Summary Table: Operations vs. Cycles and Flags

| Category | Operations | ALU cycles | CF in | Flags out |
|----------|------------|------------|-------|-----------|
| Add/Sub | ADD, SUB, CMP, INC, DEC, NEG | 1 | — | CF, PF, AF, ZF, SF, OF |
| With carry | ADC, SBB | 1 | Yes | CF, PF, AF, ZF, SF, OF |
| Logic | AND, OR, XOR, TEST | 1 | — | CF=0, PF, AF=0, ZF, SF, OF=0 |
| Logic | NOT | 1 | — | (unchanged) |
| Shift/Rotate | SHL, SHR, SAR, ROL, ROR | 1 per step | RCL/RCR only | CF, (PF, ZF, SF, OF for shifts) |
| Shift/Rotate | RCL, RCR | 1 per step | Yes | CF, (others for last step) |
| Multiply | MUL, IMUL | 26–37 (instr.) | — | CF, OF (others undefined) |
| Divide | DIV, IDIV | 29–67 (instr.) | — | Undefined |

Use this overview and the 80186 Instruction Set Summary to define the exact **op** encoding and pin widths for your ALU; no implementation is specified here.
