// ============================================================
// alu_controller.sv
// ALU Controller (Second-Level Controller)
// ============================================================

`include "opcode.vh"

module alu_controller (
    input  logic [1:0] ALUOp,
    input  logic [2:0] func3,
    input  logic [6:0] func7,
    output logic [3:0] alu_operation
);

    // Combinational logic for ALU operation selection
    always_comb begin
        case (ALUOp)
            // Load/Store, AUIPC
            2'b00: alu_operation = 4'b0010; // ADD 

            // Branch Instructions
            2'b01: alu_operation = 4'b0110; // SUB 

            // R-type (ALUOp=10) and I-type Arithmetic (ALUOp=11)
            2'b10, 2'b11: begin
                case (func3)
                    `FNC_ADD_SUB: begin
                        // Distinguish SUB from ADD for R-type instructions
                        if (ALUOp == 2'b10 && func7 == `FNC7_1)
                            alu_operation = 4'b0110; // SUB
                        else
                            alu_operation = 4'b0010; // ADD (R-type ADD or I-type ADDI)
                    end

                    `FNC_SLL:     alu_operation = 4'b0100; // SLL / SLLI
                    `FNC_SLT:     alu_operation = 4'b0111; // SLT / SLTI
                    `FNC_SLTU:    alu_operation = 4'b1001; // SLTU / SLTIU
                    `FNC_XOR:     alu_operation = 4'b0011; // XOR / XORI

                    `FNC_SRL_SRA: begin
                        // Distinguish SRL (logical) from SRA (arithmetic) shifts
                        if (func7 == `FNC7_1)
                            alu_operation = 4'b1000; // SRA / SRAI
                        else
                            alu_operation = 4'b0101; // SRL / SRLI
                    end

                    `FNC_OR:      alu_operation = 4'b0001; // OR / ORI
                    `FNC_AND:     alu_operation = 4'b0000; // AND / ANDI

                    default:      alu_operation = 4'b0000; // Default fallback
                endcase
            end

            default: alu_operation = 4'b0000; // Default ALUOp fallback
        endcase
    end

endmodule