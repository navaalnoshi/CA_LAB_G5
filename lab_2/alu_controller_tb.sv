// ============================================================
// alu_controller_tb.sv
// Randomized Testbench for Main Controller + ALU Controller
// University of Engineering and Technology, Lahore
// EE-475L - Experiment 2, Task 3: Controller Testing
//
// Tests all instruction rows from student Task 3 table:
//   R-type (ALUOp=10), I-type (ALUOp=10), Load (ALUOp=00),
//   Store (ALUOp=00), Branch (ALUOp=01), LUI/JAL (ALUOp=11)
//
// Both controllers are chained:
//   opcode -> main_controller -> ALUOp
//   ALUOp + func3 + func7    -> alu_controller -> alu_operation
// ============================================================

`include "opcode.vh"
`timescale 1ns/1ps

module alu_controller_tb;

    // ----------------------------------------------------------
    // Signals for main_controller (first-level)
    // ----------------------------------------------------------
    logic [6:0] opcode;
    logic [1:0] ALUOp;

    // ----------------------------------------------------------
    // Signals for alu_controller (second-level)
    // ----------------------------------------------------------
    logic [2:0] func3;
    logic [6:0] func7;
    logic [3:0] alu_operation;

    // ----------------------------------------------------------
    // Instantiate main_controller
    // ----------------------------------------------------------
    main_controller mc_dut (
        .opcode (opcode),
        .ALUOp  (ALUOp)
    );

    // ----------------------------------------------------------
    // Instantiate alu_controller
    // ALUOp wire connects the two controllers directly,
    // simulating the real hardware datapath.
    // ----------------------------------------------------------
    alu_controller ac_dut (
        .ALUOp         (ALUOp),
        .func3         (func3),
        .func7         (func7),
        .alu_operation (alu_operation)
    );

    // ----------------------------------------------------------
    // Tracking
    // ----------------------------------------------------------
    integer pass_count;
    integer fail_count;
    integer test_num;

    // ----------------------------------------------------------
    // Task: check
    // Sets opcode, func3, func7, waits 10ns for combinational
    // logic, then checks ALUOp and alu_operation against expected.
    // ----------------------------------------------------------
    task check(
        input [6:0]   opc,
        input [2:0]   f3,
        input [6:0]   f7,
        input [1:0]   exp_aluop,
        input [3:0]   exp_ctrl,
        input [255:0] name
    );
        opcode = opc;
        func3  = f3;
        func7  = f7;
        #10;

        if (ALUOp === exp_aluop && alu_operation === exp_ctrl) begin
            $display("  [PASS] %-10s | ALUOp=%b alu_op=%b",
                     name, ALUOp, alu_operation);
            pass_count++;
        end else begin
            $display("  [FAIL] %-10s | opc=%b f3=%b f7=%b",
                     name, opc, f3, f7);
            $display("         Expected: ALUOp=%b alu_op=%b",
                     exp_aluop, exp_ctrl);
            $display("         Got:      ALUOp=%b alu_op=%b",
                     ALUOp, alu_operation);
            fail_count++;
        end
        test_num++;
    endtask

    // ----------------------------------------------------------
    // Main stimulus
    // ----------------------------------------------------------
    initial begin
        pass_count = 0;
        fail_count = 0;
        test_num   = 1;

        $display("======================================================");
        $display("  ALU Controller Testbench  |  EE-475L  |  UET Lahore");
        $display("======================================================");

        // ======================================================
        // R-TYPE INSTRUCTIONS (OPC_ARI_RTYPE = 7'b0110011)
        // Student table: all R-type -> ALUOp = 10
        // ======================================================
        $display("\n--- R-Type Instructions (ALUOp = 2'b10) ---");
        //        opcode            f3            f7            exp_aluop  exp_ctrl   name
        check(`OPC_ARI_RTYPE, `FNC_ADD_SUB, `FNC7_0,     2'b10, 4'b0010, "add");
        check(`OPC_ARI_RTYPE, `FNC_ADD_SUB, `FNC7_1,     2'b10, 4'b0110, "sub");
        check(`OPC_ARI_RTYPE, `FNC_XOR,     `FNC7_0,     2'b10, 4'b0011, "xor");
        check(`OPC_ARI_RTYPE, `FNC_OR,      `FNC7_0,     2'b10, 4'b0001, "or");
        check(`OPC_ARI_RTYPE, `FNC_AND,     `FNC7_0,     2'b10, 4'b0000, "and");
        check(`OPC_ARI_RTYPE, `FNC_SLT,     `FNC7_0,     2'b10, 4'b0111, "slt");
        check(`OPC_ARI_RTYPE, `FNC_SLL,     `FNC7_0,     2'b10, 4'b0100, "sll");
        check(`OPC_ARI_RTYPE, `FNC_SLTU,    `FNC7_0,     2'b10, 4'b1001, "sltu");
        check(`OPC_ARI_RTYPE, `FNC_SRL_SRA, `FNC7_0,     2'b10, 4'b0101, "srl");
        check(`OPC_ARI_RTYPE, `FNC_SRL_SRA, `FNC7_1,     2'b10, 4'b1000, "sra");

        // ======================================================
        // I-TYPE ALU INSTRUCTIONS (OPC_ARI_ITYPE = 7'b0010011)
        // Student table: all I-type -> ALUOp = 10 (same as R-type)
        // ======================================================
        $display("\n--- I-Type ALU Instructions (ALUOp = 2'b10) ---");
        check(`OPC_ARI_ITYPE, `FNC_ADD_SUB, `FNC7_0,     2'b10, 4'b0010, "addi");
        check(`OPC_ARI_ITYPE, `FNC_XOR,     `FNC7_0,     2'b10, 4'b0011, "xori");
        check(`OPC_ARI_ITYPE, `FNC_OR,      `FNC7_0,     2'b10, 4'b0001, "ori");
        check(`OPC_ARI_ITYPE, `FNC_AND,     `FNC7_0,     2'b10, 4'b0000, "andi");
        check(`OPC_ARI_ITYPE, `FNC_SLT,     `FNC7_0,     2'b10, 4'b0111, "slti");
        check(`OPC_ARI_ITYPE, `FNC_SLL,     `FNC7_0,     2'b10, 4'b0100, "slli");
        check(`OPC_ARI_ITYPE, `FNC_SLTU,    `FNC7_0,     2'b10, 4'b1001, "sltiu");
        check(`OPC_ARI_ITYPE, `FNC_SRL_SRA, `FNC7_0,     2'b10, 4'b0101, "srli");
        check(`OPC_ARI_ITYPE, `FNC_SRL_SRA, `FNC7_1,     2'b10, 4'b1000, "srai");

        // ======================================================
        // LOAD INSTRUCTIONS (OPC_LOAD = 7'b0000011)
        // Student table: all load rows -> ALUOp = 00 -> ADD
        // ======================================================
        $display("\n--- Load Instructions (ALUOp = 2'b00, ADD) ---");
        check(`OPC_LOAD, `FNC_LB,  `FNC7_0, 2'b00, 4'b0010, "lb");
        check(`OPC_LOAD, `FNC_LH,  `FNC7_0, 2'b00, 4'b0010, "lh");
        check(`OPC_LOAD, `FNC_LW,  `FNC7_0, 2'b00, 4'b0010, "lw");
        check(`OPC_LOAD, `FNC_LBU, `FNC7_0, 2'b00, 4'b0010, "lbu");
        check(`OPC_LOAD, `FNC_LHU, `FNC7_0, 2'b00, 4'b0010, "lhu");

        // ======================================================
        // STORE INSTRUCTIONS (OPC_STORE = 7'b0100011)
        // Student table: all store rows -> ALUOp = 00 -> ADD
        // ======================================================
        $display("\n--- Store Instructions (ALUOp = 2'b00, ADD) ---");
        check(`OPC_STORE, `FNC_SB, `FNC7_0, 2'b00, 4'b0010, "sb");
        check(`OPC_STORE, `FNC_SH, `FNC7_0, 2'b00, 4'b0010, "sh");
        check(`OPC_STORE, `FNC_SW, `FNC7_0, 2'b00, 4'b0010, "sw");

        // ======================================================
        // BRANCH INSTRUCTIONS (OPC_BRANCH = 7'b1100011)
        // Student table: all branch rows -> ALUOp = 01 -> SUB
        // ======================================================
        $display("\n--- Branch Instructions (ALUOp = 2'b01, SUB) ---");
        check(`OPC_BRANCH, `FNC_BEQ,  `FNC7_0, 2'b01, 4'b0110, "beq");
        check(`OPC_BRANCH, `FNC_BNE,  `FNC7_0, 2'b01, 4'b0110, "bne");
        check(`OPC_BRANCH, `FNC_BLT,  `FNC7_0, 2'b01, 4'b0110, "blt");
        check(`OPC_BRANCH, `FNC_BGE,  `FNC7_0, 2'b01, 4'b0110, "bge");
        check(`OPC_BRANCH, `FNC_BLTU, `FNC7_0, 2'b01, 4'b0110, "bltu");
        check(`OPC_BRANCH, `FNC_BGEU, `FNC7_0, 2'b01, 4'b0110, "bgeu");

        // ======================================================
        // JALR (OPC_JALR = 7'b1100111)
        // Student table: jalr -> ALUOp = 00 -> ADD
        // ======================================================
        $display("\n--- JALR (ALUOp = 2'b00, ADD) ---");
        check(`OPC_JALR, `FNC_ADD_SUB, `FNC7_0, 2'b00, 4'b0010, "jalr");

        // ======================================================
        // JAL (OPC_JAL = 7'b1101111)
        // Student table: jal -> ALUOp = 11 -> ADD
        // ======================================================
        $display("\n--- JAL (ALUOp = 2'b11, ADD) ---");
        check(`OPC_JAL, 3'bxxx, 7'bxxxxxxx, 2'b11, 4'b0010, "jal");

        // ======================================================
        // LUI (OPC_LUI = 7'b0110111)
        // Student table: lui -> ALUOp = 11 -> ADD
        // ======================================================
        $display("\n--- LUI (ALUOp = 2'b11, ADD) ---");
        check(`OPC_LUI, 3'bxxx, 7'bxxxxxxx, 2'b11, 4'b0010, "lui");

        // ======================================================
        // AUIPC (OPC_AUIPC = 7'b0010111)
        // Student table: auipc -> ALUOp = 00 -> ADD
        // ======================================================
        $display("\n--- AUIPC (ALUOp = 2'b00, ADD) ---");
        check(`OPC_AUIPC, 3'bxxx, 7'bxxxxxxx, 2'b00, 4'b0010, "auipc");

        // ======================================================
        // SUMMARY
        // ======================================================
        $display("\n======================================================");
        $display("  SIMULATION COMPLETE");
        $display("  Total : %0d  |  Passed : %0d  |  Failed : %0d",
                 pass_count + fail_count, pass_count, fail_count);
        if (fail_count == 0)
            $display("  STATUS : ALL TESTS PASSED ✓");
        else
            $display("  STATUS : %0d TEST(S) FAILED ✗", fail_count);
        $display("======================================================");
        $finish;
    end

endmodule
