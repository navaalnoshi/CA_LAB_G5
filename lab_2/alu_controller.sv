// ============================================================
// alu_controller.sv
// Second-Level ALU Controller for RISC-V Processor
// University of Engineering and Technology, Lahore
// EE-475L - Experiment 2, Task 1: ALU Controller Implementation
//
// Block Diagram (student Fig 1.2 / Fig 2.2):
//   Inputs:
//     ALUOp [1:0]  -- from first-level controller
//     func3 [2:0]  -- instruction bits [14:12]
//     func7 [6:0]  -- instruction bits [31:25]
//   Output:
//     alu_operation [3:0] -- goes directly to ALU
//
// Decoding Logic Summary (student Task 3 table):
//
//   ALUOp=00 -> always ADD  (load/store address)
//   ALUOp=01 -> always SUB  (branch comparison)
//   ALUOp=10 -> R-type and I-type:
//     func3=111            -> AND  (4'b0000)
//     func3=110            -> OR   (4'b0001)
//     func3=000, func7=000 -> ADD  (4'b0010) [R-type add or I-type addi]
//     func3=100            -> XOR  (4'b0011)
//     func3=001            -> SLL  (4'b0100)
//     func3=101, func7=000 -> SRL  (4'b0101)
//     func3=000, func7=100 -> SUB  (4'b0110) [R-type sub]
//     func3=010            -> SLT  (4'b0111)
//     func3=101, func7=100 -> SRA  (4'b1000)
//     func3=011            -> SLTU (4'b1001)
//   ALUOp=11 -> ADD (lui, jal)
//
// Note: func7 bit used is bit [5] (instruction bit [30]):
//   FNC2_ADD = 1'b0, FNC2_SUB = 1'b1
//   FNC2_SRL = 1'b0, FNC2_SRA = 1'b1
// ============================================================

`include "opcode.vh"

module alu_controller (
    // ---- Inputs ----
    input  logic [1:0] ALUOp,
    input  logic [2:0] func3,
    input  logic [6:0] func7,

    // ---- Output ----
    output logic [3:0] alu_operation
);

    // ----------------------------------------------------------
    // Combinational decoding
    // ----------------------------------------------------------
    always_comb begin
        // Default: ADD. Prevents unintended latches.
        alu_operation = 4'b0010; // ADD

        case (ALUOp)

            // --------------------------------------------------
            // ALUOp = 00: Load / Store
            // Always output ADD (4'b0010).
            // Covers: lw, sw, lb, sb, lh, sh, lbu, lhu, jalr, auipc
            // --------------------------------------------------
            2'b00: begin
                alu_operation = 4'b0010; // ADD
            end

            // --------------------------------------------------
            // ALUOp = 01: Branch instructions
            // Always output SUB (4'b0110).
            // Covers: beq, bne, blt, bge, bltu, bgeu
            // The ALU subtracts rs1 - rs2 and the zero/negative
            // flags are used to decide if the branch is taken.
            // --------------------------------------------------
            2'b01: begin
                alu_operation = 4'b0110; // SUB
            end

            // --------------------------------------------------
            // ALUOp = 10: R-type AND I-type ALU instructions
            // Decode using func3 and func7 (bit [5] = instruction[30])
            // --------------------------------------------------
            2'b10: begin
                case (func3)

                    // func3 = 000 : ADD or SUB (R-type) / ADDI (I-type)
                    // Differentiated by func7[5] (instruction bit 30):
                    //   FNC2_SUB (1'b1) -> SUB (R-type only)
                    //   FNC2_ADD (1'b0) -> ADD (add / addi)
                    `FNC_ADD_SUB: begin
                        if (func7[5] == `FNC2_SUB)
                            alu_operation = 4'b0110; // SUB
                        else
                            alu_operation = 4'b0010; // ADD
                    end

                    // func3 = 001 : SLL / SLLI
                    `FNC_SLL: begin
                        alu_operation = 4'b0100; // SLL
                    end

                    // func3 = 010 : SLT / SLTI (signed comparison)
                    `FNC_SLT: begin
                        alu_operation = 4'b0111; // SLT
                    end

                    // func3 = 011 : SLTU / SLTIU (unsigned comparison)
                    `FNC_SLTU: begin
                        alu_operation = 4'b1001; // SLTU
                    end

                    // func3 = 100 : XOR / XORI
                    `FNC_XOR: begin
                        alu_operation = 4'b0011; // XOR
                    end

                    // func3 = 101 : SRL / SRLI  OR  SRA / SRAI
                    // Differentiated by func7[5] (instruction bit 30):
                    //   FNC2_SRA (1'b1) -> SRA (arithmetic, fills sign bit)
                    //   FNC2_SRL (1'b0) -> SRL (logical, fills 0)
                    `FNC_SRL_SRA: begin
                        if (func7[5] == `FNC2_SRA)
                            alu_operation = 4'b1000; // SRA
                        else
                            alu_operation = 4'b0101; // SRL
                    end

                    // func3 = 110 : OR / ORI
                    `FNC_OR: begin
                        alu_operation = 4'b0001; // OR
                    end

                    // func3 = 111 : AND / ANDI
                    `FNC_AND: begin
                        alu_operation = 4'b0000; // AND
                    end

                    // Undefined func3 -> default ADD
                    default: begin
                        alu_operation = 4'b0010; // ADD
                    end

                endcase
            end

            // --------------------------------------------------
            // ALUOp = 11: LUI / JAL
            // Student table: lui=11 (ADD to x0), jal=11 (ADD)
            // Always output ADD.
            // --------------------------------------------------
            2'b11: begin
                alu_operation = 4'b0010; // ADD
            end

            // --------------------------------------------------
            // Default
            // --------------------------------------------------
            default: begin
                alu_operation = 4'b0010; // ADD
            end

        endcase
    end

endmodule
