// ============================================================
// main_controller.sv
// First-Level Controller for RISC-V Processor
// University of Engineering and Technology, Lahore
// EE-475L - Experiment 2, Task (First Level Controller)
//
// Block Diagram (student Task 4 / Fig 1.2 block):
//   Input:  opcode  [6:0]   -- bits [6:0] of the instruction
//   Output: ALUOp   [1:0]   -- 2-bit code to second-level controller
//
// ALUOp Encoding (from student Task 3 table):
//   2'b00 -> Load / Store  (lw, sw, lb, sb, lh, sh, lbu, lhu, jalr, auipc)
//             -> ALU always does ADD for address calculation
//   2'b01 -> Branch        (beq, bne, blt, bge, bltu, bgeu)
//             -> ALU always does SUB to compare operands
//   2'b10 -> R-type        (add, sub, and, or, xor, sll, srl, sra, slt, sltu)
//             -> ALU operation decided by func3 + func7 in second controller
//   2'b10 -> I-type ALU    (addi, andi, ori, xori, slli, srli, srai, slti, sltiu)
//             -> Note: student table uses 2'b10 for I-type too (same as R-type)
//             -> second controller uses func3 (and func7 for shift variants)
//   2'b11 -> LUI / JAL     (from student's table: lui=11, jal=11)
// ============================================================

`include "opcode.vh"

module main_controller (
    // ---- Input ----
    input  logic [6:0] opcode,

    // ---- Output ----
    output logic [1:0] ALUOp
);

    // ----------------------------------------------------------
    // Combinational decoding: opcode -> ALUOp
    // Uses the macro names from the provided opcode.vh file:
    //   `OPC_ARI_RTYPE  = 7'b0110011
    //   `OPC_ARI_ITYPE  = 7'b0010011
    //   `OPC_LOAD       = 7'b0000011
    //   `OPC_STORE      = 7'b0100011
    //   `OPC_BRANCH     = 7'b1100011
    //   `OPC_JAL        = 7'b1101111
    //   `OPC_JALR       = 7'b1100111
    //   `OPC_LUI        = 7'b0110111
    //   `OPC_AUIPC      = 7'b0010111
    // ----------------------------------------------------------
    always_comb begin
        // Default: ADD (safe fallback, same as load/store)
        ALUOp = 2'b00;

        case (opcode)

            // --------------------------------------------------
            // R-type: add, sub, and, or, xor, sll, srl, sra, slt, sltu
            // ALUOp = 10 (from student table, all R-type rows = 10)
            // Second controller uses func3 + func7 to pick operation.
            // --------------------------------------------------
            `OPC_ARI_RTYPE: begin
                ALUOp = 2'b10;
            end

            // --------------------------------------------------
            // I-type ALU: addi, andi, ori, xori, slli, srli, srai, slti, sltiu
            // ALUOp = 10 (student table: all I-type ALU rows = 10)
            // Second controller uses func3 to pick operation.
            // --------------------------------------------------
            `OPC_ARI_ITYPE: begin
                ALUOp = 2'b10;
            end

            // --------------------------------------------------
            // Load: lb, lh, lw, lbu, lhu
            // ALUOp = 00 (student table: all load rows = 00)
            // ALU computes: address = base_register + sign_ext_offset
            // --------------------------------------------------
            `OPC_LOAD: begin
                ALUOp = 2'b00;
            end

            // --------------------------------------------------
            // Store: sb, sh, sw
            // ALUOp = 00 (student table: all store rows = 00)
            // ALU computes: address = base_register + sign_ext_offset
            // --------------------------------------------------
            `OPC_STORE: begin
                ALUOp = 2'b00;
            end

            // --------------------------------------------------
            // Branch: beq, bne, blt, bge, bltu, bgeu
            // ALUOp = 01 (student table: all branch rows = 01)
            // ALU subtracts operands, zero flag used for branch decision.
            // --------------------------------------------------
            `OPC_BRANCH: begin
                ALUOp = 2'b01;
            end

            // --------------------------------------------------
            // JALR: jalr
            // ALUOp = 00 (student table: jalr = 00, ADD)
            // ALU computes jump target: rs1 + sign_ext_imm
            // --------------------------------------------------
            `OPC_JALR: begin
                ALUOp = 2'b00;
            end

            // --------------------------------------------------
            // JAL: jal
            // ALUOp = 11 (student table: jal = 11)
            // --------------------------------------------------
            `OPC_JAL: begin
                ALUOp = 2'b11;
            end

            // --------------------------------------------------
            // LUI: lui
            // ALUOp = 11 (student table: lui = 11, ADD to x0)
            // --------------------------------------------------
            `OPC_LUI: begin
                ALUOp = 2'b11;
            end

            // --------------------------------------------------
            // AUIPC: auipc
            // ALUOp = 00 (student table: auipc = 00, ADD)
            // ALU computes: PC + (imm << 12)
            // --------------------------------------------------
            `OPC_AUIPC: begin
                ALUOp = 2'b00;
            end

            // --------------------------------------------------
            // Default / unknown opcode
            // --------------------------------------------------
            default: begin
                ALUOp = 2'b00;
            end

        endcase
    end

endmodule
