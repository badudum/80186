// ---------------------------------------------------------------------------
// TODO: Implement 80186 execution sequencer (inside EU).
//   - Drive ALU and register file per microcode/decode; perform multicycle
//     operations (e.g. multiply, divide, string ops).
//   - Compute effective address when needed (segment + base + index + disp).
//   - Update flags (CF, ZF, SF, OF, PF, AF) from ALU and store in reg.
//   - Interface with BIU for memory read/write (address, data, byte/word).
// ---------------------------------------------------------------------------

module execUnit (
    input  logic clk,
    input  logic rst_n
);

    // Stub: no ports or logic yet

endmodule
