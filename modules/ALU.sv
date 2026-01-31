// ---------------------------------------------------------------------------
// TODO: Implement 80186 ALU (arithmetic and logic).
//   - 16-bit and 8-bit operations: ADD, SUB, ADC, SBB, AND, OR, XOR, NOT, NEG;
//     shifts/rotates (SHL, SHR, SAR, ROL, ROR, RCL, RCR); INC, DEC; CMP.
//   - Output flags: CF, ZF, SF, OF, PF, AF per 8086/80186 semantics.
//   - Optional: MUL, IMUL, DIV, IDIV (can be multicycle in execUnit).
// ---------------------------------------------------------------------------

`timescale 1ns/1ns
module ALU (
    input  logic clk,
    input  logic rst_n,
    input  logic [5:0] alu_op,
    input  logic word,
    input  logic [15:0] a,
    input  logic [15:0] b,
    input  logic cf_in,
    input  logic [4:0] shift_cnt,
    output logic [15:0] result,
    output logic [1:0] result_hi,
    output logic div_zero,
    output logic byte_ok,
    output logic cf,
    output logic pf,
    output logic af,
    output logic zf,
    output logic sf,
    output logic of,
    output logic busy
);


    logic [15:0] a_in, b_in;


    parameter ADD = 6'b000000;
    parameter SUB = 6'b000001;
    parameter CMP = 6'b000010;
    parameter INC = 6'b000011;
    parameter DEC = 6'b000100;
    parameter NEG = 6'b000101;
    parameter AND = 6'b000110;
    parameter OR = 6'b000111;
    parameter XOR = 6'b001000;
    parameter NOT = 6'b001001;
    parameter TEST = 6'b001010;
    parameter SHL = 6'b001011;
    parameter SHR = 6'b001100;
    parameter SAR = 6'b001101;
    parameter ROL = 6'b001110;
    parameter ROR = 6'b001111;
    parameter RCL = 6'b010000;
    parameter RCR = 6'b010001;
    parameter MUL = 6'b010010;
    parameter IMUL = 6'b010011;
    parameter DIV = 6'b010100;
    parameter IDIV = 6'b010101;

    // Stub: no ports or logic yet
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_in <= 0;
            b_in <= 0;
        end else begin
            case(alu_op)
                ADD: begin
                    result <= a + b;
                end
                SUB: begin
                    result <= a - b;
                end
                CMP: begin
                    result <= a - b;
                end
                INC: begin
                    result <= a + 1;
                end
                DEC: begin
                    result <= a - 1;
                end
                NEG: begin
                    result <= 0 - a;
                end
                AND: begin
                    result <= a & b;
                end
                OR: begin
                    result <= a | b;
                end
                XOR: begin
                    result <= a ^ b;
                end
                NOT: begin
                    result <= ~a;
                end
                TEST: begin
                    result <= a & b;
                end
                SHL: begin
                    result <= a << shift_cnt;
                end
                SHR: begin
                    result <= a >> shift_cnt;
                end
                SAR: begin
                    result <= a >>> shift_cnt;
                end
                ROL: begin
                    result <= {a[15:0], a[15:0]};
                end
                ROR: begin
                    result <= {a[0], a[15:1]};
                end
                RCL: begin
                    result <= {a[15:0], cf_in};
                end
                RCR: begin
                    result <= {cf_in, a[15:0]};
                end
                // MUL/IMUL: 80186 takes 26–37 cycles; this does 1 cycle. See docs/ALU_FLAWS.md.
                // Word MUL/IMUL: product is 32-bit (DX:AX); result_hi must hold high 16 bits.
                // IMUL must use signed multiply ($signed), not unsigned a*b.
                MUL: begin
                    result <= a * b;   // FIX: set result_hi = product[31:16] for word; byte uses only result
                end
                IMUL: begin
                    result <= a * b;   // FIX: use signed multiply; set result_hi for word
                end
                DIV: begin
                    result <= a / b;
                end
                IDIV: begin
                    result <= a / b;
                end
            endcase
        end
    end


endmodule
