// ============================================================
// imm_gen_tb.sv
// Testbench for Immediate Generator Module
// University of Engineering and Technology, Lahore
// EE-475L - Experiment 3, Task 3: Testing
//
// Tests all 5 RISC-V instruction formats:
//   Section 1: I-type  (addi, lw, jalr)
//   Section 2: S-type  (sw, sb, sh)
//   Section 3: B-type  (beq, bne)
//   Section 4: U-type  (lui, auipc)
//   Section 5: J-type  (jal)
//   Section 6: Randomized sign-extension verification
//
// Each test manually encodes a real RISC-V instruction and checks
// that imm_gen produces the correct sign-extended 32-bit immediate.
// ============================================================

`include "opcode.vh"
`timescale 1ns/1ps

module imm_gen_tb;

    // ----------------------------------------------------------
    // DUT signals
    // ----------------------------------------------------------
    logic [31:0] instruction;
    logic [31:0] immediate;

    // ----------------------------------------------------------
    // Instantiate DUT
    // ----------------------------------------------------------
    imm_gen dut (
        .instruction (instruction),
        .immediate   (immediate)
    );

    // ----------------------------------------------------------
    // Test tracking
    // ----------------------------------------------------------
    integer pass_count;
    integer fail_count;
    integer test_num;

    // ----------------------------------------------------------
    // Task: check
    // Sets instruction input, waits for combinational settle,
    // compares with expected immediate value.
    // ----------------------------------------------------------
    task check(
        input [31:0]  instr,
        input [31:0]  expected,
        input [255:0] test_name
    );
        instruction = instr;
        #10; // wait for combinational logic to settle

        if (immediate === expected) begin
            $display("  [PASS] %-22s | instr=0x%08h => imm=0x%08h (%0d)",
                     test_name, instr, immediate, $signed(immediate));
            pass_count++;
        end else begin
            $display("  [FAIL] %-22s | instr=0x%08h",
                     test_name, instr);
            $display("         Expected: 0x%08h (%0d)",
                     expected, $signed(expected));
            $display("         Got:      0x%08h (%0d)",
                     immediate, $signed(immediate));
            fail_count++;
        end
        test_num++;
    endtask

    // ----------------------------------------------------------
    // Helper: build I-type instruction
    // Format: [imm[11:0] | rs1[4:0] | func3[2:0] | rd[4:0] | opcode[6:0]]
    // ----------------------------------------------------------
    function automatic [31:0] encode_itype(
        input [11:0] imm,
        input [4:0]  rs1,
        input [2:0]  f3,
        input [4:0]  rd,
        input [6:0]  opc
    );
        encode_itype = {imm, rs1, f3, rd, opc};
    endfunction

    // ----------------------------------------------------------
    // Helper: build S-type instruction
    // Format: [imm[11:5] | rs2 | rs1 | func3 | imm[4:0] | opcode]
    // ----------------------------------------------------------
    function automatic [31:0] encode_stype(
        input [11:0] imm,
        input [4:0]  rs2,
        input [4:0]  rs1,
        input [2:0]  f3,
        input [6:0]  opc
    );
        encode_stype = {imm[11:5], rs2, rs1, f3, imm[4:0], opc};
    endfunction

    // ----------------------------------------------------------
    // Helper: build B-type instruction
    // Format: [imm[12|10:5] | rs2 | rs1 | func3 | imm[4:1|11] | opcode]
    // ----------------------------------------------------------
    function automatic [31:0] encode_btype(
        input [12:0] imm, // bit 0 is always 0, provide imm[12:1] in [12:1]
        input [4:0]  rs2,
        input [4:0]  rs1,
        input [2:0]  f3,
        input [6:0]  opc
    );
        encode_btype = {imm[12], imm[10:5], rs2, rs1, f3, imm[4:1], imm[11], opc};
    endfunction

    // ----------------------------------------------------------
    // Helper: build U-type instruction
    // Format: [imm[31:12] | rd | opcode]
    // ----------------------------------------------------------
    function automatic [31:0] encode_utype(
        input [19:0] imm, // upper 20 bits
        input [4:0]  rd,
        input [6:0]  opc
    );
        encode_utype = {imm, rd, opc};
    endfunction

    // ----------------------------------------------------------
    // Helper: build J-type instruction
    // Format: [imm[20|10:1|11|19:12] | rd | opcode]
    // ----------------------------------------------------------
    function automatic [31:0] encode_jtype(
        input [20:0] imm, // bit 0 always 0
        input [4:0]  rd,
        input [6:0]  opc
    );
        encode_jtype = {imm[20], imm[10:1], imm[11], imm[19:12], rd, opc};
    endfunction

    // ----------------------------------------------------------
    // Main test body
    // ----------------------------------------------------------
    initial begin
        pass_count = 0;
        fail_count = 0;
        test_num   = 1;

        $display("======================================================");
        $display("  Immediate Generator Testbench  |  EE-475L  |  UET Lahore");
        $display("======================================================");

        // ======================================================
        // SECTION 1: I-TYPE FORMAT TESTS
        // Covers: addi, xori, ori, andi, slti, sltiu,
        //         slli, srli, srai (OPC_ARI_ITYPE)
        //         lw, lh, lb, lhu, lbu  (OPC_LOAD)
        //         jalr                  (OPC_JALR)
        //
        // Expected: {sign_ext[31:12], instr[31:20]}
        // ======================================================
        $display("\n--- I-Type Format ---");

        // addi x1, x0, 5   -> imm = +5 = 0x00000005
        check(encode_itype(12'd5,   5'd0, `FNC_ADD_SUB, 5'd1, `OPC_ARI_ITYPE),
              32'h00000005, "addi x1,x0,5");

        // addi x1, x0, -1  -> imm = -1 = 0xFFFFFFFF
        check(encode_itype(12'hFFF, 5'd0, `FNC_ADD_SUB, 5'd1, `OPC_ARI_ITYPE),
              32'hFFFFFFFF, "addi x1,x0,-1");

        // addi x1, x0, -2048 -> imm = -2048 = 0xFFFFF800 (most negative I-type imm)
        check(encode_itype(12'h800, 5'd0, `FNC_ADD_SUB, 5'd1, `OPC_ARI_ITYPE),
              32'hFFFFF800, "addi imm=-2048");

        // addi x1, x0, 2047 -> imm = 2047 = 0x000007FF (most positive I-type imm)
        check(encode_itype(12'h7FF, 5'd0, `FNC_ADD_SUB, 5'd1, `OPC_ARI_ITYPE),
              32'h000007FF, "addi imm=2047");

        // addi x1, x0, 0  -> imm = 0 = 0x00000000
        check(encode_itype(12'd0,   5'd0, `FNC_ADD_SUB, 5'd1, `OPC_ARI_ITYPE),
              32'h00000000, "addi imm=0");

        // lw x2, 8(x1)  -> imm = +8
        check(encode_itype(12'd8, 5'd1, `FNC_LW, 5'd2, `OPC_LOAD),
              32'h00000008, "lw x2,8(x1)");

        // lw x2, -4(x1) -> imm = -4 = 0xFFFFFFFC
        check(encode_itype(12'hFFC, 5'd1, `FNC_LW, 5'd2, `OPC_LOAD),
              32'hFFFFFFFC, "lw x2,-4(x1)");

        // lw x2, -2048(x1) -> imm = -2048 = 0xFFFFF800
        check(encode_itype(12'h800, 5'd1, `FNC_LW, 5'd2, `OPC_LOAD),
              32'hFFFFF800, "lw imm=-2048");

        // jalr x0, 0(x1) -> imm = 0
        check(encode_itype(12'd0, 5'd1, `FNC_ADD_SUB, 5'd0, `OPC_JALR),
              32'h00000000, "jalr offset=0");

        // jalr x0, -4(x1) -> imm = -4 = 0xFFFFFFFC
        check(encode_itype(12'hFFC, 5'd1, `FNC_ADD_SUB, 5'd0, `OPC_JALR),
              32'hFFFFFFFC, "jalr offset=-4");

        // ======================================================
        // SECTION 2: S-TYPE FORMAT TESTS
        // Covers: sw, sh, sb (OPC_STORE)
        //
        // Immediate is SPLIT: instr[31:25]=imm[11:5], instr[11:7]=imm[4:0]
        // Expected: {sign_ext[31:12], imm[11:5], imm[4:0]}
        // ======================================================
        $display("\n--- S-Type Format ---");

        // sw x2, 0(x1)  -> imm = 0
        check(encode_stype(12'd0, 5'd2, 5'd1, `FNC_SW, `OPC_STORE),
              32'h00000000, "sw x2,0(x1)");

        // sw x2, 4(x1)  -> imm = +4
        check(encode_stype(12'd4, 5'd2, 5'd1, `FNC_SW, `OPC_STORE),
              32'h00000004, "sw x2,4(x1)");

        // sw x2, -4(x1) -> imm = -4 = 0xFFFFFFFC
        check(encode_stype(12'hFFC, 5'd2, 5'd1, `FNC_SW, `OPC_STORE),
              32'hFFFFFFFC, "sw x2,-4(x1)");

        // sw x2, 2047(x1) -> imm = 2047 = 0x7FF
        check(encode_stype(12'h7FF, 5'd2, 5'd1, `FNC_SW, `OPC_STORE),
              32'h000007FF, "sw imm=2047");

        // sw x2, -2048(x1) -> imm = -2048 = 0xFFFFF800
        check(encode_stype(12'h800, 5'd2, 5'd1, `FNC_SW, `OPC_STORE),
              32'hFFFFF800, "sw imm=-2048");

        // sb x2, 1(x1) -> imm = +1
        check(encode_stype(12'd1, 5'd2, 5'd1, `FNC_SB, `OPC_STORE),
              32'h00000001, "sb x2,1(x1)");

        // ======================================================
        // SECTION 3: B-TYPE FORMAT TESTS
        // Covers: beq, bne, blt, bge, bltu, bgeu (OPC_BRANCH)
        //
        // Bit scrambling:
        //   instr[31]    = imm[12] (sign)
        //   instr[7]     = imm[11]
        //   instr[30:25] = imm[10:5]
        //   instr[11:8]  = imm[4:1]
        //   imm[0]       = always 0
        // ======================================================
        $display("\n--- B-Type Format ---");

        // beq x0, x0, +8  -> imm = +8 = 0x00000008
        check(encode_btype(13'd8, 5'd0, 5'd0, `FNC_BEQ, `OPC_BRANCH),
              32'h00000008, "beq offset=+8");

        // beq x0, x0, +4  -> imm = +4
        check(encode_btype(13'd4, 5'd0, 5'd0, `FNC_BEQ, `OPC_BRANCH),
              32'h00000004, "beq offset=+4");

        // beq x0, x0, -4  -> imm = -4 = 0xFFFFFFFC
        check(encode_btype(13'h1FFC, 5'd0, 5'd0, `FNC_BEQ, `OPC_BRANCH),
              32'hFFFFFFFC, "beq offset=-4");

        // bne x1, x2, +12 -> imm = +12
        check(encode_btype(13'd12, 5'd2, 5'd1, `FNC_BNE, `OPC_BRANCH),
              32'h0000000C, "bne offset=+12");

        // blt x1, x2, -8  -> imm = -8 = 0xFFFFFFF8
        check(encode_btype(13'h1FF8, 5'd2, 5'd1, `FNC_BLT, `OPC_BRANCH),
              32'hFFFFFFF8, "blt offset=-8");

        // bge offset = 0 -> imm = 0
        check(encode_btype(13'd0, 5'd1, 5'd2, `FNC_BGE, `OPC_BRANCH),
              32'h00000000, "bge offset=0");

        // ======================================================
        // SECTION 4: U-TYPE FORMAT TESTS
        // Covers: lui, auipc (OPC_LUI, OPC_AUIPC)
        //
        // Expected: {instr[31:12], 12'b0}
        // No sign extension needed - upper 20 bits become result[31:12]
        // ======================================================
        $display("\n--- U-Type Format ---");

        // lui x1, 1 -> imm = 0x00001000
        check(encode_utype(20'd1, 5'd1, `OPC_LUI),
              32'h00001000, "lui x1,1");

        // lui x1, 0xFFFFF -> imm = 0xFFFFF000
        check(encode_utype(20'hFFFFF, 5'd1, `OPC_LUI),
              32'hFFFFF000, "lui x1,0xFFFFF");

        // lui x1, 0x10000 -> imm = 0x10000000
        check(encode_utype(20'h10000, 5'd1, `OPC_LUI),
              32'h10000000, "lui x1,0x10000");

        // lui x1, 0 -> imm = 0
        check(encode_utype(20'd0, 5'd1, `OPC_LUI),
              32'h00000000, "lui x1,0");

        // auipc x1, 1 -> imm = 0x00001000
        check(encode_utype(20'd1, 5'd1, `OPC_AUIPC),
              32'h00001000, "auipc x1,1");

        // auipc x1, 0x80000 -> imm = 0x80000000 (negative when used as signed)
        check(encode_utype(20'h80000, 5'd1, `OPC_AUIPC),
              32'h80000000, "auipc x1,0x80000");

        // ======================================================
        // SECTION 5: J-TYPE FORMAT TESTS
        // Covers: jal (OPC_JAL)
        //
        // Bit scrambling (in instruction):
        //   instr[31]    = imm[20] (sign)
        //   instr[19:12] = imm[19:12]
        //   instr[20]    = imm[11]
        //   instr[30:21] = imm[10:1]
        //   imm[0]       = always 0
        // ======================================================
        $display("\n--- J-Type Format ---");

        // jal x1, +4  -> imm = +4 = 0x00000004
        check(encode_jtype(21'd4, 5'd1, `OPC_JAL),
              32'h00000004, "jal x1,+4");

        // jal x1, +8  -> imm = +8
        check(encode_jtype(21'd8, 5'd1, `OPC_JAL),
              32'h00000008, "jal x1,+8");

        // jal x0, -4  -> imm = -4 = 0xFFFFFFFC
        check(encode_jtype(21'h1FFFFC, 5'd0, `OPC_JAL),
              32'hFFFFFFFC, "jal x0,-4");

        // jal x0, -8  -> imm = -8 = 0xFFFFFFF8
        check(encode_jtype(21'h1FFFF8, 5'd0, `OPC_JAL),
              32'hFFFFFFF8, "jal x0,-8");

        // jal x1, 0   -> imm = 0 (infinite loop)
        check(encode_jtype(21'd0, 5'd1, `OPC_JAL),
              32'h00000000, "jal x1,0");

        // ======================================================
        // SECTION 6: SIGN EXTENSION VERIFICATION
        // Targeted tests to confirm sign bit propagates correctly
        // for both positive (imm[MSB]=0) and negative (imm[MSB]=1)
        // immediates across different formats.
        // ======================================================
        $display("\n--- Sign Extension Verification ---");

        // I-type: positive (bit 11 = 0) -> bits [31:12] must all be 0
        // addi x0, x0, 1 -> imm = 0x00000001  (all zeros above bit 11)
        check(encode_itype(12'h001, 5'd0, `FNC_ADD_SUB, 5'd0, `OPC_ARI_ITYPE),
              32'h00000001, "I: pos sign-ext");

        // I-type: negative (bit 11 = 1) -> bits [31:12] must all be 1
        // addi x0, x0, -2048 -> imm = 0xFFFFF800  (all ones above bit 11)
        check(encode_itype(12'h800, 5'd0, `FNC_ADD_SUB, 5'd0, `OPC_ARI_ITYPE),
              32'hFFFFF800, "I: neg sign-ext");

        // S-type: negative (bit 11 = 1) -> bits [31:12] all 1
        check(encode_stype(12'h800, 5'd0, 5'd0, `FNC_SW, `OPC_STORE),
              32'hFFFFF800, "S: neg sign-ext");

        // B-type: negative (bit 12 = 1) -> bits [31:13] all 1
        check(encode_btype(13'h1000, 5'd0, 5'd0, `FNC_BEQ, `OPC_BRANCH),
              32'hFFFFF000, "B: neg sign-ext");

        // J-type: negative (bit 20 = 1) -> bits [31:21] all 1
        check(encode_jtype(21'h100000, 5'd0, `OPC_JAL),
              32'hFFF00000, "J: neg sign-ext");

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
