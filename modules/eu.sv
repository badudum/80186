// ---------------------------------------------------------------------------
// TODO: Implement 80186 Execution Unit (EU) top-level.
//   - Instantiate decode, reg, ALU, execUnit, microcode.
//   - Provide interface to BIU: request instruction bytes; send address/data for
//     memory ops; receive read data; drive write data.
//   - Coordinate: decode produces control; microcode sequences steps; execUnit
//     performs ALU/reg operations; reg holds 80186 register set and flags.
//   - Support 80186/8086 addressing modes and operand sizes (8/16 bit).
// ---------------------------------------------------------------------------

module eu (
    input  logic clk,
    input  logic rst_n
);

    // Stub: no submodules yet

endmodule
