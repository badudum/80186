# Current ALU Implementation — Flaws and Fixes

This document lists the main flaws in the current `modules/ALU.sv` implementation relative to the 80186 datasheet and `docs/ALU_ARCHITECTURE.md`, and how to fix them.

---

## 1. MUL / IMUL — Using `a * b` in One Cycle

### Flaw: Cycle count does not match 80186

The **80186 Instruction Set Summary** specifies:

- **MUL (unsigned):** 26–28 cycles (byte), **35–37 cycles (word)**.
- **IMUL (signed):** 25–28 (byte), **34–37 (word)**.

The original 80186 used a **multi-cycle** multiplier (e.g. shift-add over many clocks). The current ALU does:

```systemverilog
MUL:  result <= a * b;
IMUL: result <= a * b;
```

So the **product is computed in a single clock**. That gives:

- **Correct result** (if you fix operand size and signedness — see below).
- **Wrong timing**: the execution unit would need to **insert 25–36 idle cycles** after starting MUL/IMUL to match 80186 behavior. If the execUnit doesn’t do that, software that relies on 80186 cycle counts (or timing-sensitive code) will behave differently.

**Options:**

1. **Multi-cycle ALU multiplier:** Implement a shift-add (or similar) multiplier inside the ALU; assert **busy** for 26–37 cycles; execUnit waits until **busy** is low. Result and **result_hi** valid when **busy** goes low.
2. **Keep single-cycle multiply, fix timing in execUnit:** Keep `a * b` in one cycle; in execUnit (or microcode), **stall for 26–37 cycles** after issuing MUL/IMUL so that the **instruction** timing matches the 80186. The ALU is still “too fast,” but the **instruction** cycle count is correct.
3. **Ignore cycle count:** If you don’t care about 80186-accurate timing, a single-cycle multiply is fine for correctness only.

---

### Flaw: Result width for MUL/IMUL word

- **MUL word:** AX × r/m16 → **DX:AX** (32-bit product). Low 16 bits in AX, high 16 in DX.
- **MUL byte:** AL × r/m8 → **AX** (16-bit product).

The ALU has **result** (16 bits) and **result_hi** (currently **2 bits** in the header comment; in the code it’s declared `output logic [1:0] result_hi`). So:

- **result_hi** should be **16 bits** for the high word of a 32-bit product (MUL/IMUL word).
- For **word** MUL/IMUL you must compute the full 32-bit product and assign:
  - `result`  = product[15:0];
  - `result_hi` = product[31:16];
- For **byte** MUL/IMUL the product is 16 bits; only **result** is used; **result_hi** should be zero or undefined.

Currently **result_hi** is never set in the MUL/IMUL cases, so the high word of the product is lost.

---

### Flaw: IMUL is signed; `a * b` is unsigned in Verilog

In Verilog/SystemVerilog, `a * b` is **unsigned** multiplication. **IMUL** is **signed** (two’s complement). So:

- For **IMUL**, operands and result must be interpreted as signed. You need e.g. **signed** operands and a signed product:
  - `$signed(a) * $signed(b)` (with a 32-bit signed result for word), or
  - Sign-extend byte operands to 16 bits, then signed multiply, then take low 16 (byte) or full 32 (word).

Otherwise IMUL gives wrong results for negative operands (e.g. (−1)×(−1) should be +1).

---

## 2. DIV / IDIV — Single-Cycle `a / b`

- **80186:** DIV 29–38 cycles, IDIV 44–67 cycles (multi-cycle divider).
- Current code: `result <= a / b` in **one cycle**.

Same idea as MUL: **result can be correct**, but **cycle count** is wrong unless the execUnit stalls for the documented number of cycles. Also:

- **DIV/IDIV word:** Dividend is **DX:AX** (32 bits), divisor 16 bits → quotient **AX**, remainder **DX**. So the ALU needs **two outputs** (quotient and remainder); currently only **result** is set. **result_hi** could be used for remainder.
- **Division by zero:** If `b == 0`, 80186 raises an exception; the ALU should set **div_zero** and not deliver a bogus result. Current code doesn’t check `b == 0`.

---

## 3. Shifts — Variable `shift_cnt` in One Cycle

Current code:

```systemverilog
SHL: result <= a << shift_cnt;
SHR: result <= a >> shift_cnt;
SAR: result <= a >>> shift_cnt;
```

- **80186:** Shifts by **CL** or immediate count take **5+4n** (reg) or **17+4n** (mem) cycles — i.e. **one shift per clock**; the EU loops **n** times.
- Current implementation does **up to 31 shifts in one cycle**. So again: **result correct**, **cycle count wrong** unless execUnit runs **n** single-step shifts instead of one variable shift.

To match 80186 timing, the ALU should perform **one** shift per cycle (e.g. `result <= a << 1` for SHL by 1) and the execUnit should call the ALU **n** times for shift count **n**. Alternatively, keep variable shift but document that timing is not 80186-accurate.

---

## 4. ROL / ROR / RCL / RCR — Bugs

- **ROL:** `result <= {a[15:0], a[15:0]}` is **32 bits** (duplicate of a); it gets truncated to 16 bits and is not a rotate. **ROL by 1** should be: `result <= {a[14:0], a[15]}` (rotate left: MSB moves to LSB).
- **ROR:** `result <= {a[0], a[15:1]}` is correct for **ROR by 1**.
- **RCL:** `result <= {a[15:0], cf_in}` is **17 bits**; truncated to 16 bits loses the MSB. **RCL by 1** should be: shift left, LSB = cf_in, new CF = old MSB; so `result <= {a[14:0], cf_in}` and **cf** = a[15].
- **RCR:** Similarly, **RCR by 1**: shift right, MSB = cf_in, new CF = old LSB; so `result <= {cf_in, a[15:1]}` and **cf** = a[0].

All four currently ignore **shift_cnt**; 80186 rotates by 1 or by CL (one step per cycle). So either implement “by 1” only and let execUnit loop, or add multi-step rotate with correct CF handling.

---

## 5. Flags Not Implemented

The ALU declares **cf, pf, af, zf, sf, of** but the **always** block never assigns them. So all flag outputs are undriven (or default). Per `docs/ALU_ARCHITECTURE.md`, the ALU must compute these from the result (and **cf_in** for ADC, SBB, RCL, RCR). Until they are implemented, conditional jumps and instructions that depend on flags (e.g. ADC, SBB, DAA) will not work correctly.

---

## 6. Byte vs Word Not Implemented

The **word** input is not used. All operations act on full 16-bit **a** and **b**. For 80186, byte operations (e.g. ADD AL, BL, MUL byte) must use only the low 8 bits of operands and result; flags (e.g. PF) are defined on the low 8 bits of the result. So operand and result masking/extension based on **word** is missing.

---

## 7. ADC / SBB Not Implemented

The ALU opcode list has no **ADC** or **SBB**. Those need **cf_in** in the add/sub (e.g. result = a + b + cf_in for ADC). They must be added and **cf_in** used.

---

## Summary Table

| Item | Flaw | Fix (brief) |
|------|------|--------------|
| MUL/IMUL cycle count | Single-cycle vs 26–37 on 80186 | Multi-cycle ALU multiplier + **busy**, or execUnit stall for 26–37 cycles. |
| MUL/IMUL result width | result_hi not set; width 2 bits | result_hi[15:0]; set result = low 16, result_hi = high 16 for word MUL/IMUL. |
| IMUL signed | `a * b` unsigned in Verilog | Use signed multiply (e.g. $signed(a)*$signed(b)) and 32-bit product for word. |
| DIV/IDIV cycle count | Single-cycle vs 29–67 on 80186 | Multi-cycle divider + **busy**, or execUnit stall. |
| DIV/IDIV quotient/remainder | Only result; no remainder | result = quotient, result_hi = remainder; set **div_zero** when b==0. |
| Shifts | Variable shift in 1 cycle vs 1 step/cycle on 80186 | One shift per cycle and execUnit loop, or document timing mismatch. |
| ROL/ROR/RCL/RCR | ROL wrong; RCL/RCR truncation; no shift_cnt | Implement “by 1” with correct CF; use shift_cnt in execUnit loop. |
| Flags | Not computed | Implement cf, pf, af, zf, sf, of per ALU_ARCHITECTURE.md. |
| Byte/word | word unused | Mask/extend operands and result by **word**; PF on low 8 bits. |
| ADC/SBB | Missing | Add opcodes and use **cf_in** in add/sub. |

Adding a short comment in the ALU near the MUL/IMUL/DIV/IDIV cases that references this doc and the cycle-count/result-width/signed flaws.