// ============================================================
// imm_gen.sv
// Immediate Generator for RISC-V Processor
// University of Engineering and Technology, Lahore
// EE-475L - Experiment 3, Task 2: Implementation
//
// Block Diagram (Fig 3.1):
//   Input:  instruction [31:0]  -- full 32-bit RISC-V instruction
//   Output: immediate   [31:0]  -- sign-extended 32-bit immediate
//
// Description:
//   Extracts and sign-extends the immediate field from any of
//   the 5 RISC-V instruction formats. The opcode (bits [6:0])
//   is used to determine which format applies.
//
// Format Reference:
//
// I-type  [addi, lw, jalr, ...]:
//   imm[11:0]  = instr[31:20]
//   sign-extend bit 31 into bits [31:12]
//
// S-type  [sw, sb, sh]:
//   imm[11:5]  = instr[31:25]
//   imm[4:0]   = instr[11:7]
//   sign-extend bit 31 into bits [31:12]
//
// B-type  [beq, bne, blt, bge, bltu, bgeu]:
//   imm[12]    = instr[31]      <- sign bit
//   imm[11]    = instr[7]
//   imm[10:5]  = instr[30:25]
//   imm[4:1]   = instr[11:8]
//   imm[0]     = 1'b0           <- always 0 (2-byte aligned)
//   sign-extend bit 31 into bits [31:13]
//
// U-type  [lui, auipc]:
//   imm[31:12] = instr[31:12]   <- upper 20 bits
//   imm[11:0]  = 12'b0          <- lower 12 bits always 0
//   (no sign extension needed - already 32 bits)
//
// J-type  [jal]:
//   imm[20]    = instr[31]      <- sign bit
//   imm[19:12] = instr[19:12]
//   imm[11]    = instr[20]
//   imm[10:1]  = instr[30:21]
//   imm[0]     = 1'b0           <- always 0 (2-byte aligned)
//   sign-extend bit 31 into bits [31:21]
// ============================================================

`include "opcode.vh"

module imm_gen (
    // ---- Input ----
    input  logic [31:0] instruction,

    // ---- Output ----
    output logic [31:0] immediate
);

    // ----------------------------------------------------------
    // Extract opcode to identify instruction format
    // Opcode is always in the lowest 7 bits of the instruction.
    // ----------------------------------------------------------
    logic [6:0] opcode;
    assign opcode = instruction[6:0];

    // ----------------------------------------------------------
    // Combinational immediate generation
    // ----------------------------------------------------------
    always_comb begin
        // Default: 0 to prevent latches for undefined opcodes
        immediate = 32'b0;

        case (opcode)

            // --------------------------------------------------
            // I-TYPE FORMAT
            // Instructions: addi, slti, sltiu, xori, ori, andi,
            //               slli, srli, srai, lw, lh, lb, lhu,
            //               lbu, jalr
            //
            // Immediate field: instr[31:20]  (12 bits)
            // Sign extension:  replicate instr[31] into [31:12]
            //
            // Example - addi x1, x0, 5:
            //   instr[31:20] = 0000_0000_0101
            //   immediate    = 0x00000005
            //
            // Example - addi x1, x0, -1:
            //   instr[31:20] = 1111_1111_1111
            //   immediate    = 0xFFFFFFFF (-1)
            // --------------------------------------------------
            `OPC_ARI_ITYPE,
            `OPC_LOAD,
            `OPC_JALR: begin
                immediate = { {20{instruction[31]}},   // 20 copies of sign bit
                               instruction[31:20] };   // 12-bit immediate field
            end

            // --------------------------------------------------
            // S-TYPE FORMAT
            // Instructions: sw, sh, sb
            //
            // The immediate is SPLIT in the instruction encoding:
            //   Upper part: instr[31:25]  (7 bits) -> imm[11:5]
            //   Lower part: instr[11:7]   (5 bits) -> imm[4:0]
            // Sign extension: replicate instr[31] into [31:12]
            //
            // Example - sw x2, 4(x1):
            //   instr[31:25] = 0000000, instr[11:7] = 00100
            //   immediate    = 0x00000004
            //
            // Example - sw x2, -4(x1):
            //   instr[31:25] = 1111111, instr[11:7] = 11100
            //   immediate    = 0xFFFFFFFC (-4)
            // --------------------------------------------------
            `OPC_STORE: begin
                immediate = { {20{instruction[31]}},   // 20 copies of sign bit
                               instruction[31:25],     // imm[11:5]
                               instruction[11:7]  };   // imm[4:0]
            end

            // --------------------------------------------------
            // B-TYPE FORMAT
            // Instructions: beq, bne, blt, bge, bltu, bgeu
            //
            // Immediate encodes a SIGNED BYTE offset.
            // Bits are scrambled to simplify hardware decode:
            //   instr[31]    -> imm[12]   (sign bit)
            //   instr[7]     -> imm[11]
            //   instr[30:25] -> imm[10:5]
            //   instr[11:8]  -> imm[4:1]
            //   1'b0         -> imm[0]    (always 0, 2-byte aligned)
            // Sign extension: replicate instr[31] into [31:13]
            //
            // Example - beq x0, x0, +8:
            //   imm = 0x00000008  (offset = 8 bytes forward)
            //
            // Example - beq x0, x0, -4:
            //   imm = 0xFFFFFFFC  (offset = 4 bytes backward)
            // --------------------------------------------------
            `OPC_BRANCH: begin
                immediate = { {19{instruction[31]}},   // 19 copies of sign bit
                               instruction[31],        // imm[12]
                               instruction[7],         // imm[11]
                               instruction[30:25],     // imm[10:5]
                               instruction[11:8],      // imm[4:1]
                               1'b0 };                 // imm[0] always 0
            end

            // --------------------------------------------------
            // U-TYPE FORMAT
            // Instructions: lui, auipc
            //
            // Immediate occupies the UPPER 20 bits of the result.
            // The lower 12 bits are forced to 0.
            // No sign extension is needed - the 20-bit field
            // directly becomes bits [31:12] of the 32-bit result.
            //
            // Example - lui x1, 1:
            //   instr[31:12] = 00000000000000000001
            //   immediate    = 0x00001000
            //
            // Example - lui x1, 0xFFFFF:
            //   instr[31:12] = 11111111111111111111
            //   immediate    = 0xFFFFF000
            // --------------------------------------------------
            `OPC_LUI,
            `OPC_AUIPC: begin
                immediate = { instruction[31:12],  // imm[31:12] (upper 20 bits)
                              12'b0 };              // imm[11:0]  = 0
            end

            // --------------------------------------------------
            // J-TYPE FORMAT
            // Instructions: jal
            //
            // Immediate encodes a SIGNED BYTE offset for the jump.
            // Bits are heavily scrambled in the instruction:
            //   instr[31]    -> imm[20]   (sign bit)
            //   instr[19:12] -> imm[19:12]
            //   instr[20]    -> imm[11]
            //   instr[30:21] -> imm[10:1]
            //   1'b0         -> imm[0]    (always 0, 2-byte aligned)
            // Sign extension: replicate instr[31] into [31:21]
            //
            // Example - jal x1, +4:
            //   imm = 0x00000004
            //
            // Example - jal x0, -4:
            //   imm = 0xFFFFFFFC
            // --------------------------------------------------
            `OPC_JAL: begin
                immediate = { {11{instruction[31]}},   // 11 copies of sign bit
                               instruction[31],        // imm[20]
                               instruction[19:12],     // imm[19:12]
                               instruction[20],        // imm[11]
                               instruction[30:21],     // imm[10:1]
                               1'b0 };                 // imm[0] always 0
            end

            // --------------------------------------------------
            // R-TYPE and everything else:
            // R-type instructions have no immediate field.
            // Output 0 for safety.
            // --------------------------------------------------
            default: begin
                immediate = 32'b0;
            end

        endcase
    end

endmodule
