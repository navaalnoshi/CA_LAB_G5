// ============================================================
// alu_tb.sv
// Randomized Testbench for ALU Module
// University of Engineering and Technology, Lahore
// EE-475L - Experiment 2, Task 2: ALU Testing
//
// Tests all 10 ALU operations from the student's operation table:
//   - Section 1: Directed tests (known values, check exact result)
//   - Section 2: Randomized tests (100 random input combinations)
//   - Section 3: Zero flag specific tests
//   Each test prints PASS or FAIL with operand and result values.
// ============================================================

`include "opcode.vh"
`timescale 1ns/1ps

module alu_tb;

    // ----------------------------------------------------------
    // DUT port connections
    // ----------------------------------------------------------
    logic [31:0] operand1;
    logic [31:0] operand2;
    logic [3:0]  alu_operation;
    logic [31:0] result;
    logic        zero;

    // ----------------------------------------------------------
    // Instantiate the ALU (Device Under Test)
    // ----------------------------------------------------------
    alu dut (
        .operand1      (operand1),
        .operand2      (operand2),
        .alu_operation (alu_operation),
        .result        (result),
        .zero          (zero)
    );

    // ----------------------------------------------------------
    // Test tracking variables
    // ----------------------------------------------------------
    integer pass_count;
    integer fail_count;
    integer test_num;

    // ----------------------------------------------------------
    // Task: apply_test
    // Sets inputs, waits for combinational logic to settle (10ns),
    // compares output with expected, prints PASS or FAIL.
    // ----------------------------------------------------------
    task apply_test(
        input [31:0]  op1,          // operand1 value
        input [31:0]  op2,          // operand2 value
        input [3:0]   op,           // alu_operation code
        input [31:0]  expected_res, // expected result
        input         expected_zero // expected zero flag
    );
        operand1      = op1;
        operand2      = op2;
        alu_operation = op;
        #10; // wait for combinational logic to settle

        if (result === expected_res && zero === expected_zero) begin
            $display("  [PASS] Test#%03d | op=%b | op1=0x%08h op2=0x%08h | result=0x%08h zero=%b",
                     test_num, op, op1, op2, result, zero);
            pass_count++;
        end else begin
            $display("  [FAIL] Test#%03d | op=%b | op1=0x%08h op2=0x%08h",
                     test_num, op, op1, op2);
            $display("         Expected -> result=0x%08h  zero=%b", expected_res,  expected_zero);
            $display("         Got      -> result=0x%08h  zero=%b", result, zero);
            fail_count++;
        end
        test_num++;
    endtask

    // ----------------------------------------------------------
    // Main test body
    // ----------------------------------------------------------
    initial begin
        pass_count = 0;
        fail_count = 0;
        test_num   = 1;

        $display("======================================================");
        $display("  ALU Testbench  |  EE-475L  |  UET Lahore");
        $display("======================================================");

        // ======================================================
        // SECTION 1: DIRECTED TESTS FOR EACH OPERATION
        // Each block tests one alu_operation code with hand-known
        // values so we can verify correctness manually.
        // ======================================================

        // ------------------------------------------------------
        // AND  (alu_operation = 4'b0000)
        // ------------------------------------------------------
        $display("\n[AND - 4'b0000]");
        // 0xFF & 0x0F = 0x0F
        apply_test(32'hFFFFFFFF, 32'h0F0F0F0F, 4'b0000, 32'h0F0F0F0F, 1'b0);
        // 0xAAAA & 0x5555 = 0x0000  -> zero flag should be 1
        apply_test(32'hAAAAAAAA, 32'h55555555, 4'b0000, 32'h00000000, 1'b1);
        // Any value AND 0 = 0
        apply_test(32'hDEADBEEF, 32'h00000000, 4'b0000, 32'h00000000, 1'b1);
        // Any value AND all-ones = same value
        apply_test(32'h12345678, 32'hFFFFFFFF, 4'b0000, 32'h12345678, 1'b0);

        // ------------------------------------------------------
        // OR   (alu_operation = 4'b0001)
        // ------------------------------------------------------
        $display("\n[OR - 4'b0001]");
        // 0xAAAA | 0x5555 = 0xFFFF
        apply_test(32'hAAAAAAAA, 32'h55555555, 4'b0001, 32'hFFFFFFFF, 1'b0);
        // 0 | 0 = 0 -> zero flag = 1
        apply_test(32'h00000000, 32'h00000000, 4'b0001, 32'h00000000, 1'b1);
        // value | 0 = same value
        apply_test(32'h12345678, 32'h00000000, 4'b0001, 32'h12345678, 1'b0);
        // 0xF0 | 0x0F = 0xFF
        apply_test(32'hF0F0F0F0, 32'h0F0F0F0F, 4'b0001, 32'hFFFFFFFF, 1'b0);

        // ------------------------------------------------------
        // ADD  (alu_operation = 4'b0010)
        // ------------------------------------------------------
        $display("\n[ADD - 4'b0010]");
        // 1 + 1 = 2
        apply_test(32'h00000001, 32'h00000001, 4'b0010, 32'h00000002, 1'b0);
        // 0xFFFF + 1 = 0x00000000 (overflow wraps) -> zero flag = 1
        apply_test(32'hFFFFFFFF, 32'h00000001, 4'b0010, 32'h00000000, 1'b1);
        // 0 + 0 = 0 -> zero flag = 1
        apply_test(32'h00000000, 32'h00000000, 4'b0010, 32'h00000000, 1'b1);
        // Standard positive addition
        apply_test(32'h00001000, 32'h00002000, 4'b0010, 32'h00003000, 1'b0);
        // Add negative (signed): 5 + (-3) = 2
        apply_test(32'h00000005, 32'hFFFFFFFD, 4'b0010, 32'h00000002, 1'b0);

        // ------------------------------------------------------
        // XOR  (alu_operation = 4'b0011)
        // ------------------------------------------------------
        $display("\n[XOR - 4'b0011]");
        // Same value XOR itself = 0 -> zero flag = 1
        apply_test(32'hFFFFFFFF, 32'hFFFFFFFF, 4'b0011, 32'h00000000, 1'b1);
        // 0xAAAA ^ 0x5555 = 0xFFFF
        apply_test(32'hAAAAAAAA, 32'h55555555, 4'b0011, 32'hFFFFFFFF, 1'b0);
        // value ^ 0 = same value
        apply_test(32'h12345678, 32'h00000000, 4'b0011, 32'h12345678, 1'b0);

        // ------------------------------------------------------
        // SLL  (alu_operation = 4'b0100)
        // ------------------------------------------------------
        $display("\n[SLL - 4'b0100]");
        // 1 << 1 = 2
        apply_test(32'h00000001, 32'h00000001, 4'b0100, 32'h00000002, 1'b0);
        // 1 << 31 = 0x80000000 (MSB set)
        apply_test(32'h00000001, 32'h0000001F, 4'b0100, 32'h80000000, 1'b0);
        // shift by 0 = no change
        apply_test(32'h00000005, 32'h00000000, 4'b0100, 32'h00000005, 1'b0);
        // 0xFF << 4 = 0xFF0
        apply_test(32'h000000FF, 32'h00000004, 4'b0100, 32'h00000FF0, 1'b0);
        // Shift out all bits -> result = 0
        apply_test(32'h00000001, 32'h00000020, 4'b0100, 32'h00000000, 1'b1);

        // ------------------------------------------------------
        // SRL  (alu_operation = 4'b0101)
        // ------------------------------------------------------
        $display("\n[SRL - 4'b0101]");
        // 0x80000000 >> 1 = 0x40000000 (fills 0, NOT sign bit)
        apply_test(32'h80000000, 32'h00000001, 4'b0101, 32'h40000000, 1'b0);
        // 0xFFFFFFFF >> 4 = 0x0FFFFFFF
        apply_test(32'hFFFFFFFF, 32'h00000004, 4'b0101, 32'h0FFFFFFF, 1'b0);
        // 4 >> 1 = 2
        apply_test(32'h00000004, 32'h00000001, 4'b0101, 32'h00000002, 1'b0);
        // Shift out all bits -> result = 0
        apply_test(32'h00000001, 32'h00000020, 4'b0101, 32'h00000000, 1'b1);

        // ------------------------------------------------------
        // SUB  (alu_operation = 4'b0110)
        // ------------------------------------------------------
        $display("\n[SUB - 4'b0110]");
        // 5 - 3 = 2
        apply_test(32'h00000005, 32'h00000003, 4'b0110, 32'h00000002, 1'b0);
        // Equal values: 5 - 5 = 0 -> zero flag = 1 (BEQ would branch)
        apply_test(32'h00000005, 32'h00000005, 4'b0110, 32'h00000000, 1'b1);
        // 0 - 1 = 0xFFFFFFFF (underflow wraps in 2's complement)
        apply_test(32'h00000000, 32'h00000001, 4'b0110, 32'hFFFFFFFF, 1'b0);
        // Same large value -> zero
        apply_test(32'hDEADBEEF, 32'hDEADBEEF, 4'b0110, 32'h00000000, 1'b1);

        // ------------------------------------------------------
        // SLT  (alu_operation = 4'b0111) - SIGNED
        // ------------------------------------------------------
        $display("\n[SLT - 4'b0111  (Signed)]");
        // 1 < 2 (signed) -> result = 1
        apply_test(32'h00000001, 32'h00000002, 4'b0111, 32'h00000001, 1'b0);
        // 2 < 1 (signed) -> result = 0
        apply_test(32'h00000002, 32'h00000001, 4'b0111, 32'h00000000, 1'b1);
        // -1 < 1 (signed) -> result = 1  (0xFFFFFFFF is -1 in signed)
        apply_test(32'hFFFFFFFF, 32'h00000001, 4'b0111, 32'h00000001, 1'b0);
        // 1 < -1 (signed) -> result = 0
        apply_test(32'h00000001, 32'hFFFFFFFF, 4'b0111, 32'h00000000, 1'b1);
        // Equal -> result = 0
        apply_test(32'h00000007, 32'h00000007, 4'b0111, 32'h00000000, 1'b1);

        // ------------------------------------------------------
        // SRA  (alu_operation = 4'b1000) - ARITHMETIC
        // ------------------------------------------------------
        $display("\n[SRA - 4'b1000  (Arithmetic)]");
        // 0x80000000 >> 1 arithmetically = 0xC0000000 (fills sign bit = 1)
        apply_test(32'h80000000, 32'h00000001, 4'b1000, 32'hC0000000, 1'b0);
        // Positive value SRA fills 0 just like SRL
        apply_test(32'h7FFFFFFF, 32'h00000001, 4'b1000, 32'h3FFFFFFF, 1'b0);
        // -1 (0xFFFFFFFF) shifted right by any amount = -1 (always 1s)
        apply_test(32'hFFFFFFFF, 32'h00000004, 4'b1000, 32'hFFFFFFFF, 1'b0);
        // 0x80000000 >> 31 = 0xFFFFFFFF
        apply_test(32'h80000000, 32'h0000001F, 4'b1000, 32'hFFFFFFFF, 1'b0);

        // ------------------------------------------------------
        // SLTU (alu_operation = 4'b1001) - UNSIGNED
        // ------------------------------------------------------
        $display("\n[SLTU - 4'b1001  (Unsigned)]");
        // 1 < 2 (unsigned) -> result = 1
        apply_test(32'h00000001, 32'h00000002, 4'b1001, 32'h00000001, 1'b0);
        // 2 < 1 (unsigned) -> result = 0
        apply_test(32'h00000002, 32'h00000001, 4'b1001, 32'h00000000, 1'b1);
        // 0xFFFFFFFF is a very large unsigned number, not less than 1
        apply_test(32'hFFFFFFFF, 32'h00000001, 4'b1001, 32'h00000000, 1'b1);
        // 1 < 0xFFFFFFFF unsigned -> result = 1
        apply_test(32'h00000001, 32'hFFFFFFFF, 4'b1001, 32'h00000001, 1'b0);

        // ======================================================
        // SECTION 2: RANDOMIZED TESTS (100 iterations)
        // Generates random operands and a random valid operation
        // code (0-9). A software reference model computes the
        // expected result which is compared against the DUT.
        // ======================================================
        $display("\n[Randomized Tests - 100 iterations]");
        begin
            integer       i;
            logic [31:0]  r_op1, r_op2;
            logic [3:0]   r_aluop;
            logic [31:0]  expected;
            logic         exp_zero;

            for (i = 0; i < 100; i++) begin
                r_op1   = $random;
                r_op2   = $random;
                r_aluop = $urandom_range(0, 9); // only codes 0..9 are valid

                // Software reference model
                case (r_aluop)
                    4'b0000: expected = r_op1 & r_op2;
                    4'b0001: expected = r_op1 | r_op2;
                    4'b0010: expected = r_op1 + r_op2;
                    4'b0011: expected = r_op1 ^ r_op2;
                    4'b0100: expected = r_op1 << r_op2[4:0];
                    4'b0101: expected = r_op1 >> r_op2[4:0];
                    4'b0110: expected = r_op1 - r_op2;
                    4'b0111: expected = ($signed(r_op1) < $signed(r_op2)) ? 32'd1 : 32'd0;
                    4'b1000: expected = $signed(r_op1) >>> r_op2[4:0];
                    4'b1001: expected = (r_op1 < r_op2) ? 32'd1 : 32'd0;
                    default: expected = 32'd0;
                endcase
                exp_zero = (expected == 32'b0);

                apply_test(r_op1, r_op2, r_aluop, expected, exp_zero);
            end
        end

        // ======================================================
        // SECTION 3: ZERO FLAG FOCUSED TESTS
        // Make sure the zero flag is correct in edge cases.
        // ======================================================
        $display("\n[Zero Flag Edge Cases]");
        // ADD 0 + 0 = 0 -> zero must be 1
        apply_test(32'h00000000, 32'h00000000, 4'b0010, 32'h00000000, 1'b1);
        // SUB equal values -> zero must be 1
        apply_test(32'hCAFEBABE, 32'hCAFEBABE, 4'b0110, 32'h00000000, 1'b1);
        // XOR same -> zero must be 1
        apply_test(32'hA5A5A5A5, 32'hA5A5A5A5, 4'b0011, 32'h00000000, 1'b1);
        // AND with complement -> zero must be 1
        apply_test(32'hAAAAAAAA, 32'h55555555, 4'b0000, 32'h00000000, 1'b1);

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
