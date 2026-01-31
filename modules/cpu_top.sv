// ---------------------------------------------------------------------------
// TODO: Implement 80186 CPU top (BIU + EU coordination).
//   - Instantiate biu and eu; connect address/data/control between them.
//   - Implement fetch–execute loop: BIU fetches bytes into prefetch queue (optional
//     for Phase 1); EU requests instruction bytes and executes; update IP on fetch.
//   - Handle reset: set IP/CS per 80186 reset vector (e.g. FFFF:0 → FFFF0); clear
//     or initialize other state as per datasheet.
//   - Drive READY (SRDY/ARDY) from external memory_controller into BIU.
//   - Later: HOLD/HLDA interface to BIU for bus arbitration.
// ---------------------------------------------------------------------------

module cpu_top (
    input  logic clk,
    input  logic rst_n
);

    // Stub: no submodules yet

endmodule
