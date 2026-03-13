// ============================================================
// imm_gen.sv
// ============================================================

`include "opcode.vh"

module imm_gen (
    input  logic [31:0] instruction,
    output logic [31:0] immediate
);


    logic [6:0] opcode;
    assign opcode = instruction[6:0];

    always_comb begin
        // Default to 0 to avoid creating latches
        immediate = 32'b0;

        case (opcode)

            `OPC_ARI_ITYPE,
            `OPC_LOAD,
            `OPC_JALR: begin
                immediate = { {20{instruction[31]}}, instruction[31:20] };   
            end

           
            `OPC_STORE: begin
                immediate = { {20{instruction[31]}}, instruction[31:25], instruction[11:7] };
            end

          
            `OPC_BRANCH: begin
                immediate = { {19{instruction[31]}}, instruction[31], instruction[7], instruction[30:25], instruction[11:8], 1'b0 };
            end

           
            `OPC_LUI,
            `OPC_AUIPC: begin
                immediate = { instruction[31:12], 12'b0 };
            end

           
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
