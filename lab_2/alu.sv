// ============================================================
// alu.sv
// 32-bit Arithmetic Logic Unit (ALU) - RISC-V Processor
// University of Engineering and Technology, Lahore
// EE-475L - Experiment 2, Task 1: ALU Implementation
//
// Block Diagram Ports (Fig 1.1 / Fig 2.1):
//   Inputs:
//     operand1      [31:0]  -- 32-bit first source operand
//     operand2      [31:0]  -- 32-bit second source operand
//     alu_operation [3:0]   -- 4-bit operation select
//   Outputs:
//     result        [31:0]  -- 32-bit ALU output
//     zero                  -- 1 when result == 0
//
// Operation Encoding (student Table, Task 2):
//   4'b0000 = AND
//   4'b0001 = OR
//   4'b0010 = ADD
//   4'b0011 = XOR
//   4'b0100 = SLL
//   4'b0101 = SRL
//   4'b0110 = SUB
//   4'b0111 = SLT
//   4'b1000 = SRA
//   4'b1001 = SLTU
// ============================================================

`include "opcode.vh"

module alu (
    // ---- Inputs ----
    input  logic [31:0] operand1,
    input  logic [31:0] operand2,
    input  logic [3:0]  alu_operation,

    // ---- Outputs ----
    output logic [31:0] result,
    output logic        zero
);

    // ----------------------------------------------------------
    // Shift amount is taken from the lower 5 bits of operand2.
    // RISC-V specification says shift amount is at most 31 bits,
    // so only bits [4:0] of operand2 are used as shift amount.
    // ----------------------------------------------------------
    logic [4:0] shamt;
    assign shamt = operand2[4:0];

    // ----------------------------------------------------------
    // Signed casts for SLT (signed comparison).
    // Without $signed, '<' would do unsigned comparison.
    // ----------------------------------------------------------
    logic signed [31:0] signed_op1;
    logic signed [31:0] signed_op2;
    assign signed_op1 = $signed(operand1);
    assign signed_op2 = $signed(operand2);

    // ----------------------------------------------------------
    // Combinational ALU - case on alu_operation
    // ----------------------------------------------------------
    always_comb begin

        // Default output to 0. This prevents inferred latches and
        // ensures the output is defined for any undefined alu_operation.
        result = 32'b0;

        case (alu_operation)

            // -----------------------------------------------
            // 4'b0000 : AND
            // Bitwise AND of operand1 and operand2.
            // RISC-V instructions that use this: and, andi
            // -----------------------------------------------
            4'b0000: begin
                result = operand1 & operand2;
            end

            // -----------------------------------------------
            // 4'b0001 : OR
            // Bitwise OR of operand1 and operand2.
            // RISC-V instructions that use this: or, ori
            // -----------------------------------------------
            4'b0001: begin
                result = operand1 | operand2;
            end

            // -----------------------------------------------
            // 4'b0010 : ADD
            // Arithmetic addition.
            // RISC-V instructions: add, addi, lw, sw, lb, sb,
            //                      lh, sh, lbu, lhu, jalr, auipc
            // -----------------------------------------------
            4'b0010: begin
                result = operand1 + operand2;
            end

            // -----------------------------------------------
            // 4'b0011 : XOR
            // Bitwise XOR of operand1 and operand2.
            // RISC-V instructions: xor, xori
            // -----------------------------------------------
            4'b0011: begin
                result = operand1 ^ operand2;
            end

            // -----------------------------------------------
            // 4'b0100 : SLL (Shift Left Logical)
            // Shift operand1 LEFT by shamt positions.
            // Vacated bits on the right are filled with 0.
            // RISC-V instructions: sll, slli
            // -----------------------------------------------
            4'b0100: begin
                result = operand1 << shamt;
            end

            // -----------------------------------------------
            // 4'b0101 : SRL (Shift Right Logical)
            // Shift operand1 RIGHT by shamt positions.
            // Vacated bits on the left are filled with 0.
            // RISC-V instructions: srl, srli
            // -----------------------------------------------
            4'b0101: begin
                result = operand1 >> shamt;
            end

            // -----------------------------------------------
            // 4'b0110 : SUB
            // Arithmetic subtraction: operand1 - operand2.
            // RISC-V instruction: sub
            // Also used for branch comparisons (BEQ, BNE etc.)
            // where zero flag is checked after subtraction.
            // -----------------------------------------------
            4'b0110: begin
                result = operand1 - operand2;
            end

            // -----------------------------------------------
            // 4'b0111 : SLT (Set Less Than - Signed)
            // If operand1 < operand2 (signed), result = 1, else 0.
            // Uses $signed casts to force signed comparison.
            // RISC-V instructions: slt, slti
            // -----------------------------------------------
            4'b0111: begin
                result = (signed_op1 < signed_op2) ? 32'd1 : 32'd0;
            end

            // -----------------------------------------------
            // 4'b1000 : SRA (Shift Right Arithmetic)
            // Shift operand1 RIGHT by shamt positions.
            // Vacated bits filled with the SIGN BIT (MSB).
            // >>> operator on $signed performs arithmetic shift.
            // RISC-V instructions: sra, srai
            // -----------------------------------------------
            4'b1000: begin
                result = $signed(operand1) >>> shamt;
            end

            // -----------------------------------------------
            // 4'b1001 : SLTU (Set Less Than Unsigned)
            // If operand1 < operand2 (unsigned), result = 1, else 0.
            // No $signed cast - operands treated as unsigned values.
            // RISC-V instructions: sltu, sltiu
            // -----------------------------------------------
            4'b1001: begin
                result = (operand1 < operand2) ? 32'd1 : 32'd0;
            end

            // -----------------------------------------------
            // Default: undefined operation code -> output 0
            // -----------------------------------------------
            default: begin
                result = 32'b0;
            end

        endcase
    end

    // ----------------------------------------------------------
    // Zero Flag
    // zero = 1 when the result of the ALU operation is zero.
    // This flag is primarily used by branch instructions:
    //   BEQ  : branch if (rs1 - rs2 == 0), i.e., zero = 1
    //   BNE  : branch if (rs1 - rs2 != 0), i.e., zero = 0
    // ----------------------------------------------------------
    assign zero = (result == 32'b0) ? 1'b1 : 1'b0;

endmodule
