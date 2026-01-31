// ---------------------------------------------------------------------------
// TODO: Implement 80186 register file.
//   - General: AX, BX, CX, DX (and AH, AL, BH, BL, CH, CL, DH, DL); SI, DI, BP, SP.
//   - IP (instruction pointer); FLAGS (CF, PF, AF, ZF, SF, TF, IF, DF, OF).
//   - Segment: CS, DS, SS, ES.
//   - Reset state per 80186: CS=FFFF, IP=0000 (or per datasheet); other regs
//     undefined or zero as chosen.
//   - Dual read / single write (or as needed for execUnit); segment override
//     handling can be in decode or here.
// ---------------------------------------------------------------------------

module reg (
    input  logic clk,
    input  logic rst_n
);

    // Stub: no ports or logic yet

endmodule
