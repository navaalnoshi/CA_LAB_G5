// ============================================================
// alu.sv
// ALU Module for EE-475L Lab 2
// Supports 10 operations: AND, OR, ADD, XOR, SLL, SRL, SUB, SLT, SRA, SLTU
// ============================================================

`timescale 1ns/1ps

module alu(
    input  logic [31:0] operand1,      // First operand
    input  logic [31:0] operand2,      // Second operand
    input  logic [3:0]  alu_operation, // Operation code
    output logic [31:0] result,        // ALU result
    output logic        zero           // Zero flag
);

    always_comb begin
        case (alu_operation)
            4'b0000: result = operand1 & operand2;                     // AND
            4'b0001: result = operand1 | operand2;                     // OR
            4'b0010: result = operand1 + operand2;                     // ADD
            4'b0011: result = operand1 ^ operand2;                     // XOR
            4'b0100: result = operand1 << operand2[4:0];               // SLL
            4'b0101: result = operand1 >> operand2[4:0];               // SRL (logical)
            4'b0110: result = operand1 - operand2;                     // SUB
            4'b0111: result = ($signed(operand1) < $signed(operand2)) ? 32'd1 : 32'd0; // SLT signed
            4'b1000: result = $signed(operand1) >>> operand2[4:0];     // SRA (arithmetic)
            4'b1001: result = (operand1 < operand2) ? 32'd1 : 32'd0;   // SLTU unsigned
            default: result = 32'd0;
        endcase

        // Set zero flag: 1 if result is zero, else 0
        zero = (result == 32'd0) ? 1'b1 : 1'b0;
    end

endmodule
