// ---------------------------------------------------------------------------
// TODO: Implement 80186/8086 instruction decode.
//   - Decode opcode (and ModR/M, SIB, displacement, immediate) into control
//     signals: ALU operation, operand size (8/16), addressing mode, register
//     selects, memory vs register, etc.
//   - Cover 8086 instruction set first; then 80186-specific (ENTER, LEAVE,
//     PUSHA, POPA, BOUND, etc.).
//   - Output: micro-op or control word for microcode/execUnit.
// ---------------------------------------------------------------------------

module decode (
    input  logic clk,
    input  logic rst_n
);

    // Stub: no ports or logic yet

endmodule
