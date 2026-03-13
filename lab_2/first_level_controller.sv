// ============================================================
// first_level_controller.sv
// Main Controller: Decodes opcode to generate ALUOp
// ============================================================

`timescale 1ns/1ps
`include "opcode.vh"

module first_level_controller (
    input  logic [6:0] opcode,
    output logic [1:0] ALUOp
);

    // Combinational logic to determine ALU operation type
    always_comb begin
        case (opcode)
            // Memory operations and PC-relative additions
            `OPC_LOAD, 
            `OPC_STORE, 
            `OPC_AUIPC, 
            `OPC_JALR:      ALUOp = 2'b00;

            // Branch operations
            `OPC_BRANCH:    ALUOp = 2'b01;

            // R-type arithmetic/logical operations
            `OPC_ARI_RTYPE: ALUOp = 2'b10;

            // I-type arithmetic/logical, LUI, and JAL
            `OPC_ARI_ITYPE, 
            `OPC_LUI, 
            `OPC_JAL:       ALUOp = 2'b11;

            // Default fallback
            default:        ALUOp = 2'b00;
        endcase
    end

endmodule