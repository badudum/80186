// ---------------------------------------------------------------------------
// TODO: Implement 80186 Bus Interface Unit (BIU).
//   - Generate bus cycles per 80186: T1 (address + ALE), T2–T4 (data), TW if READY
//     not asserted; drive ALE, RD, WR per datasheet timing (ALE 1/2 clk earlier
//     than 8086).
//   - Multiplexed address/data: output address in T1; latch externally or provide
//     latched address; bidirectional data in T2–T4. BHE and A0 for byte/word.
//   - Accept SRDY and/or ARDY from memory_controller; insert wait states until
//     READY; optionally programmable wait states per 80186 chip-select logic.
//   - Prefetch queue (optional Phase 1): buffer fetched instruction bytes for EU.
//   - Later: HOLD/HLDA; float address/data and control when HLDA asserted.
// ---------------------------------------------------------------------------

module biu (
    input  logic clk,
    input  logic rst_n
);

    // Stub: no ports or logic yet

endmodule
