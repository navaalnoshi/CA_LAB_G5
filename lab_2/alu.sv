// ============================================================
// alu.sv
// 32-bit Arithmetic Logic Unit (ALU)
// ============================================================

`include "opcode.vh"

module alu (
    input  logic [31:0] operand1,
    input  logic [31:0] operand2,
    input  logic [3:0]  alu_operation,

    output logic [31:0] result,
    output logic        zero
);

    // shift amount
    logic [4:0] shamt;
    assign shamt = operand2[4:0];

    // signed values for SLT
    logic signed [31:0] signed_op1;
    logic signed [31:0] signed_op2;
    assign signed_op1 = $signed(operand1);
    assign signed_op2 = $signed(operand2);

    always_comb begin
        result = 32'b0;

        case (alu_operation)

            4'b0000: result = operand1 & operand2;                 // AND
            4'b0001: result = operand1 | operand2;                 // OR
            4'b0010: result = operand1 + operand2;                 // ADD
            4'b0011: result = operand1 ^ operand2;                 // XOR
            4'b0100: result = operand1 << shamt;                   // SLL
            4'b0101: result = operand1 >> shamt;                   // SRL
            4'b0110: result = operand1 - operand2;                 // SUB
            4'b0111: result = (signed_op1 < signed_op2) ? 32'd1 : 32'd0; // SLT
            4'b1000: result = $signed(operand1) >>> shamt;         // SRA

            default: result = 32'b0;

        endcase
    end

    // Zero flag asserted only when SUB result is zero
    assign zero = (alu_operation == 4'b0110) && (result == 32'b0);

endmodule
