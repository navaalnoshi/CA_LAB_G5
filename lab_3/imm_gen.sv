// ============================================================
// imm_gen.sv
// Pulls the immediate value out of an instruction and sign-extends it.
// ============================================================

`include "opcode.vh"

module imm_gen (
    input  logic [31:0] instruction,
    output logic [31:0] immediate
);

    // Grab the opcode from the bottom 7 bits to know the format
    logic [6:0] opcode;
    assign opcode = instruction[6:0];

    always_comb begin
        // Default to 0 to avoid creating latches
        immediate = 32'b0;

        case (opcode)

            // I-TYPE: The immediate is just the top 12 bits. Sign-extend it.
            `OPC_ARI_ITYPE,
            `OPC_LOAD,
            `OPC_JALR: begin
                immediate = { {20{instruction[31]}}, instruction[31:20] };   
            end

            // S-TYPE: Immediate is split into two pieces. Glue them and sign-extend.
            `OPC_STORE: begin
                immediate = { {20{instruction[31]}}, instruction[31:25], instruction[11:7] };
            end

            // B-TYPE: Branches. The bits are scrambled, and bit 0 is always 0.
            `OPC_BRANCH: begin
                immediate = { {19{instruction[31]}}, instruction[31], instruction[7], instruction[30:25], instruction[11:8], 1'b0 };
            end

            // U-TYPE: Upper immediate. Grab the top 20 bits, pad the bottom with zeros.
            `OPC_LUI,
            `OPC_AUIPC: begin
                immediate = { instruction[31:12], 12'b0 };
            end

            // J-TYPE: Jumps. Scrambled bits again, with bit 0 locked to 0.
            `OPC_JAL: begin
                immediate = { {11{instruction[31]}}, instruction[31], instruction[19:12], instruction[20], instruction[30:21], 1'b0 };
            end

            // Default for R-Type or unknowns
            default: begin
                immediate = 32'b0;
            end

        endcase
    end

endmodule
