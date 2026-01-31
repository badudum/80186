// ---------------------------------------------------------------------------
// VGA controller for full computer (Phase 4). Drive external monitor via DE1-SoC VGA connector.
//   - VGA timing: 640×480 @ 60 Hz or 720×400 (text). Pixel clock ~25.175 MHz (640×480) or 28.322 MHz (720×400).
//   - Text mode (80×25): read character buffer from VRAM at 0xB8000 (segment B800). Each cell: 2 bytes (ASCII + attribute).
//   - Font: 8×16 or 9×16 glyphs; store in ROM or hardcoded. Generate pixel stream from (row, col) and VRAM + font.
//   - Inputs: clk_vga (pixel clock from PLL), rst_n, VRAM read data/address (from memory_controller or dual-port VRAM).
//   - Outputs: VGA_R, VGA_G, VGA_B (8-bit each or 10-bit per DE1-SoC), VGA_HS, VGA_VS, VGA_CLK, VGA_BLANK_N, VGA_SYNC_N.
//   - See docs/FULL_COMPUTER.md and DE1-SoC user manual for pin names.
// ---------------------------------------------------------------------------

module vga_controller (
    input  logic        clk_vga,
    input  logic        rst_n,
    // VRAM read (text buffer at B8000). memory_controller or dual-port RAM provides data.
    input  logic [15:0] vram_data,
    output logic [15:0] vram_addr,
    // VGA outputs
    output logic [7:0]  vga_r,
    output logic [7:0]  vga_g,
    output logic [7:0]  vga_b,
    output logic        vga_hs,
    output logic        vga_vs,
    output logic        vga_blank_n,
    output logic        vga_sync_n
);

    // Stub: no timing or pixel generation yet. Tie outputs to avoid floating.
    assign vram_addr   = 16'h0000;
    assign vga_r       = 8'h00;
    assign vga_g       = 8'h00;
    assign vga_b       = 8'h00;
    assign vga_hs      = 1'b0;
    assign vga_vs      = 1'b0;
    assign vga_blank_n = 1'b0;
    assign vga_sync_n  = 1'b0;

endmodule
