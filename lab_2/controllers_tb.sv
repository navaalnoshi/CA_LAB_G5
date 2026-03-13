// ============================================================
// Randomized Testbench for First-Level and ALU Controllers
// ============================================================

`timescale 1ns/1ps
`include "opcode.vh"

module controllers_tb;

    logic [6:0] opcode;
    logic [2:0] func3;
    logic [6:0] func7;
    logic [1:0] ALUOp_wire; 
    
    // Final output
    logic [3:0] alu_operation;



    first_level_controller ctrl1 (
        .opcode (opcode),
        .ALUOp  (ALUOp_wire)
    );

    alu_controller ctrl2 (
        .ALUOp         (ALUOp_wire),
        .func3         (func3),
        .func7         (func7),
        .alu_operation (alu_operation)
    );


    integer pass_count = 0;
    integer fail_count = 0;
    integer test_num   = 1;


    logic [6:0] valid_opcodes [0:8] = '{
        `OPC_LOAD, `OPC_STORE, `OPC_AUIPC, `OPC_JALR, 
        `OPC_BRANCH, `OPC_ARI_RTYPE, `OPC_ARI_ITYPE, `OPC_LUI, `OPC_JAL
    };


    function logic [1:0] get_expected_aluop(input logic [6:0] opc);
        case (opc)
            `OPC_LOAD, `OPC_STORE, `OPC_AUIPC, `OPC_JALR: get_expected_aluop = 2'b00;
            `OPC_BRANCH:                                  get_expected_aluop = 2'b01;
            `OPC_ARI_RTYPE:                               get_expected_aluop = 2'b10;
            `OPC_ARI_ITYPE, `OPC_LUI, `OPC_JAL:           get_expected_aluop = 2'b11;
            default:                                      get_expected_aluop = 2'b00;
        endcase
    endfunction

    function logic [3:0] get_expected_alu_op(
        input logic [1:0] alu_op_code, 
        input logic [2:0] f3, 
        input logic [6:0] f7
    );
        case (alu_op_code)
            2'b00: get_expected_alu_op = 4'b0010; // ADD
            2'b01: get_expected_alu_op = 4'b0110; // SUB
            2'b10, 2'b11: begin
                case (f3)
                    `FNC_ADD_SUB: get_expected_alu_op = (alu_op_code == 2'b10 && f7 == `FNC7_1) ? 4'b0110 : 4'b0010;
                    `FNC_SLL:     get_expected_alu_op = 4'b0100;
                    `FNC_SLT:     get_expected_alu_op = 4'b0111;
                    `FNC_SLTU:    get_expected_alu_op = 4'b1001;
                    `FNC_XOR:     get_expected_alu_op = 4'b0011;
                    `FNC_SRL_SRA: get_expected_alu_op = (f7 == `FNC7_1) ? 4'b1000 : 4'b0101;
                    `FNC_OR:      get_expected_alu_op = 4'b0001;
                    `FNC_AND:     get_expected_alu_op = 4'b0000;
                    default:      get_expected_alu_op = 4'b0000;
                endcase
            end
            default: get_expected_alu_op = 4'b0000;
        endcase
    endfunction


    task apply_test(
        input logic [6:0] t_opcode,
        input logic [2:0] t_func3,
        input logic [6:0] t_func7
    );
        logic [1:0] exp_aluop;
        logic [3:0] exp_alu_operation;

        opcode = t_opcode;
        func3  = t_func3;
        func7  = t_func7;
        
        #10; 
        
        exp_aluop = get_expected_aluop(t_opcode);
        exp_alu_operation = get_expected_alu_op(exp_aluop, t_func3, t_func7);

        if (ALUOp_wire === exp_aluop && alu_operation === exp_alu_operation) begin
            $display("  [PASS] Test#%03d | opc=%b f3=%b f7=%b | ALUOp=%b alu_out=%b", 
                     test_num, t_opcode, t_func3, t_func7, ALUOp_wire, alu_operation);
            pass_count++;
        end else begin
            $display("  [FAIL] Test#%03d | opc=%b f3=%b f7=%b", test_num, t_opcode, t_func3, t_func7);
            $display("         Expected -> ALUOp=%b alu_out=%b", exp_aluop, exp_alu_operation);
            $display("         Got      -> ALUOp=%b alu_out=%b", ALUOp_wire, alu_operation);
            fail_count++;
        end
        test_num++;
    endtask


    initial begin
        $display("======================================================");
        $display("  Combined Controllers Randomized Testbench");
        $display("======================================================");

        // --- DIRECTED TESTS ---
        $display("\n[Directed Tests]");
        apply_test(`OPC_LOAD,      3'b010,       7'b0000000); // lw -> ADD
        apply_test(`OPC_BRANCH,    `FNC_BEQ,     7'b0000000); // beq -> SUB
        apply_test(`OPC_ARI_RTYPE, `FNC_ADD_SUB, `FNC7_0);    // add -> ADD
        apply_test(`OPC_ARI_RTYPE, `FNC_ADD_SUB, `FNC7_1);    // sub -> SUB
        apply_test(`OPC_ARI_ITYPE, `FNC_ADD_SUB, `FNC7_0);    // addi -> ADD
        apply_test(`OPC_ARI_RTYPE, `FNC_SRL_SRA, `FNC7_1);    // sra -> SRA
        apply_test(`OPC_LUI,       3'b000,       7'b0000000); // lui -> ADD

        // --- RANDOMIZED TESTS ---
        $display("\n[Randomized Tests (100 Iterations)]");
        begin
            integer i;
            logic [6:0] r_opcode;
            logic [2:0] r_func3;
            logic [6:0] r_func7;
            integer rand_idx;

            for (i = 0; i < 100; i++) begin
                // Pick a random valid opcode
                rand_idx = $urandom_range(0, 8);
                r_opcode = valid_opcodes[rand_idx];
                
                // Random func3 (0-7)
                r_func3 = $urandom_range(0, 7);
                
                // Random func7 (either all 0s or bit 5 set)
                r_func7 = ($urandom_range(0, 1)) ? `FNC7_1 : `FNC7_0; 
                
                apply_test(r_opcode, r_func3, r_func7);
            end
        end

        // --- SUMMARY ---
        $display("\n======================================================");
        $display("  SIMULATION COMPLETE");
        $display("  Total : %0d  |  Passed : %0d  |  Failed : %0d", 
                 pass_count + fail_count, pass_count, fail_count);
        if (fail_count == 0)
            $display("  STATUS : ALL TESTS PASSED");
        else
            $display("  STATUS : %0d TEST(S) FAILED", fail_count);
        $display("======================================================");
        
        $finish;
    end

endmodule