// ---------------------------------------------------------------------------
// TODO: Implement 80186 microcode or control FSM.
//   - Microcode ROM (or FSM): for each instruction, sequence of micro-ops
//     (fetch opcode, fetch ModR/M, compute EA, read operand, ALU op, write
//     result, update IP, etc.).
//   - Input: current instruction/decode state; output: next micro-op and
//     next-address (or state).
//   - Support 8086 instruction set sequencing; extend for 80186-specific
//     instructions (ENTER/LEAVE, PUSHA/POPA, etc.).
// ---------------------------------------------------------------------------

module microcode (
    input  logic clk,
    input  logic rst_n
);

    // Stub: no ports or logic yet

endmodule
