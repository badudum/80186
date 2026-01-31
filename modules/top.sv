// ---------------------------------------------------------------------------
// FPGA80186 — DE1-SoC top-level. Scales to full computer (MS-DOS, external monitor).
//   - Module name must be FPGA80186 (TOP_LEVEL_ENTITY in .qsf).
//   - Instantiate clk_rst (board clock + reset), cpu_top, memory_controller, vga_controller.
//   - Pins: CLOCK_50, KEY, LED; VGA (external monitor); PS/2 (keyboard); memory (SRAM/SDRAM) when used.
//   - Phase 1: CPU + memory_controller + LEDs. Phase 4: add VGA + PS/2 for full computer (see docs/FULL_COMPUTER.md).
// ---------------------------------------------------------------------------

module FPGA80186 (
    // Board clock and reset
    input  logic       CLOCK_50,
    input  logic [0:0]  KEY,
    output logic [7:0]  LED,
    // VGA — external monitor (Phase 4 full computer; assign pins per DE1-SoC user manual)
    output logic [7:0]  VGA_R,
    output logic [7:0]  VGA_G,
    output logic [7:0]  VGA_B,
    output logic        VGA_HS,
    output logic        VGA_VS,
    output logic        VGA_CLK,
    output logic        VGA_BLANK_N,
    output logic        VGA_SYNC_N,
    // PS/2 keyboard (Phase 4 full computer)
    input  logic        PS2_CLK,
    input  logic        PS2_DAT
);

    logic clk_cpu;
    logic rst_n;

    clk_rst u_clk_rst (
        .clk_board  ( CLOCK_50 ),
        .rst_btn_n  ( KEY[0]   ),
        .clk_cpu    ( clk_cpu  ),
        .rst_n      ( rst_n    )
    );

    // TODO: instantiate cpu_top and memory_controller; connect bus and ready.
    assign LED = 8'h00;

    // Phase 4 full computer: VGA and keyboard
    // TODO: instantiate vga_controller (VGA_CLK from PLL or CLOCK_50; VRAM from memory_controller);
    //       drive VGA_R, VGA_G, VGA_B, VGA_HS, VGA_VS, VGA_CLK, VGA_BLANK_N, VGA_SYNC_N.
    // TODO: instantiate keyboard_controller (PS2_CLK, PS2_DAT) and expose I/O 0x60/0x64 to CPU.
    assign VGA_R      = 8'h00;
    assign VGA_G      = 8'h00;
    assign VGA_B      = 8'h00;
    assign VGA_HS     = 1'b0;
    assign VGA_VS     = 1'b0;
    assign VGA_CLK    = 1'b0;
    assign VGA_BLANK_N = 1'b0;
    assign VGA_SYNC_N  = 1'b0;

endmodule
