// ---------------------------------------------------------------------------
// Memory controller for 80186 bus on DE1-SoC. Scales to full computer (MS-DOS, VGA).
//   - Accept 80186-style bus from BIU: address (20-bit), data, RD, WR, BHE, A0, etc.
//   - Memory map (see docs/FULL_COMPUTER.md):
//       • 0x00000 – 0x9FFFF: Conventional RAM (640 KB). Phase 1: subset in M10K/BRAM; scale to SDRAM.
//       • 0xA0000 – 0xBFFFF: Video RAM (VRAM). Text mode: B8000–B8FFF (4 KB). Dual-port: CPU write, VGA read.
//       • 0xC0000 – 0xEFFFF: Option ROM / extended BIOS (optional; can be RAM or ROM).
//       • 0xF0000 – 0xFFFFF: BIOS ROM (64 KB). Reset vector at FFFF0. Load minimal BIOS for MS-DOS boot.
//   - Drive READY (SRDY/ARDY) to BIU when transfer completes.
//   - Phase 1: Single region (e.g. 0x00000–0x0FFFF) in on-chip M10K; no VRAM/ROM yet.
// ---------------------------------------------------------------------------

module memory_controller (
    input  logic        clk,
    input  logic        rst_n,
    // CPU bus interface (from BIU / system bus)
    input  logic [19:0] addr,
    inout  wire  [15:0] data,
    input  logic        rd,
    input  logic        wr,
    input  logic        bhe,
    input  logic        a0,
    output logic        ready,
    // Phase 4: VGA read port for VRAM (0xB8000 text buffer). Connect to vga_controller.
    output logic [15:0] vram_read_data,
    input  logic [15:0] vram_read_addr
);

    // Stub: always ready; no actual memory yet. vram_read_data unused until VRAM and vga_controller exist.
    assign ready = 1'b1;
    assign vram_read_data = 16'h0000;

endmodule
