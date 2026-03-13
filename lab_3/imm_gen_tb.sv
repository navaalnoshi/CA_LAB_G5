// ============================================================
// imm_gen_tb.sv
// ============================================================

`include "opcode.vh"
`timescale 1ns/1ps

module imm_gen_tb;

    logic [31:0] instruction;
    logic [31:0] immediate;

    imm_gen dut (
        .instruction (instruction),
        .immediate   (immediate)
    );

    integer pass_count;
    integer fail_count;


    task check(
        input [31:0]  instr,
        input [31:0]  expected,
        input string  test_name
    );
        instruction = instr;
        #10; 

        if (immediate === expected) begin
            $display("[PASS] %s", test_name);
            pass_count++;
        end else begin
            $display("[FAIL] %s | Expected: %0h, Got: %0h", test_name, expected, immediate);
            fail_count++;
        end
    endtask

    function automatic [31:0] encode_itype(input [11:0] imm, input [4:0] rs1, input [2:0] f3, input [4:0] rd, input [6:0] opc);
        encode_itype = {imm, rs1, f3, rd, opc};
    endfunction

    function automatic [31:0] encode_stype(input [11:0] imm, input [4:0] rs2, input [4:0] rs1, input [2:0] f3, input [6:0] opc);
        encode_stype = {imm[11:5], rs2, rs1, f3, imm[4:0], opc};
    endfunction

    function automatic [31:0] encode_btype(input [13:0] imm, input [4:0] rs2, input [4:0] rs1, input [2:0] f3, input [6:0] opc);
        encode_btype = {imm[12], imm[10:5], rs2, rs1, f3, imm[4:1], imm[11], opc};
    endfunction

    function automatic [31:0] encode_utype(input [19:0] imm, input [4:0] rd, input [6:0] opc);
        encode_utype = {imm, rd, opc};
    endfunction

    function automatic [31:0] encode_jtype(input [21:0] imm, input [4:0] rd, input [6:0] opc);
        encode_jtype = {imm[20], imm[10:1], imm[11], imm[19:12], rd, opc};
    endfunction

    initial begin
        pass_count = 0;
        fail_count = 0;

        $display("\n--- Starting Immediate Generator Tests ---");

        // I-TYPE 
        check(encode_itype(12'd5,   5'd0, `FNC_ADD_SUB, 5'd1, `OPC_ARI_ITYPE), 32'h00000005, "I-Type: addi 5");
        check(encode_itype(12'hFFF, 5'd0, `FNC_ADD_SUB, 5'd1, `OPC_ARI_ITYPE), 32'hFFFFFFFF, "I-Type: addi -1");
        
        // S-TYPE 
        check(encode_stype(12'd4, 5'd2, 5'd1, `FNC_SW, `OPC_STORE), 32'h00000004, "S-Type: sw 4");
        check(encode_stype(12'hFFC, 5'd2, 5'd1, `FNC_SW, `OPC_STORE), 32'hFFFFFFFC, "S-Type: sw -4");

        // B-TYPE 
        check(encode_btype(13'd8, 5'd0, 5'd0, `FNC_BEQ, `OPC_BRANCH), 32'h00000008, "B-Type: beq +8");
        check(encode_btype(13'h1FFC, 5'd0, 5'd0, `FNC_BEQ, `OPC_BRANCH), 32'hFFFFFFFC, "B-Type: beq -4");

        // U-TYPE 
        check(encode_utype(20'hFFFFF, 5'd1, `OPC_LUI), 32'hFFFFF000, "U-Type: lui edge case");

        // J-TYPE 
        check(encode_jtype(21'd4, 5'd1, `OPC_JAL), 32'h00000004, "J-Type: jal +4");
        check(encode_jtype(21'h1FFFFC, 5'd0, `OPC_JAL), 32'hFFFFFFFC, "J-Type: jal -4");

        $display("\n--- Results ---");
        $display("Passed: %0d | Failed: %0d", pass_count, fail_count);
        if (fail_count == 0) $display("All tests passed!");
        else $display("%0d test(s) failed.", fail_count);
        
        $finish;
    end

endmodule
