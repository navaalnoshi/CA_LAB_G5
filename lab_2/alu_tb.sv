// Experiment 2 – Task 2
// Self-Testing Randomized Testbench for ALU
// EE-475L Computer Architecture Lab
// UET Lahore

`timescale 1ns/1ps

module alu_tb();

    // ----------------------------
    // Signal Declarations
    // ----------------------------
    logic [31:0] operand1;
    logic [31:0] operand2;
    logic [3:0]  alu_operation;
    logic [31:0] result;
    logic        zero;

    // Variables for verification
    logic [31:0] expected_result;
    logic        expected_zero;
    int error_count = 0;

    // ----------------------------
    // Instantiate ALU (DUT)
    // ----------------------------
    alu dut (
        .operand1(operand1),
        .operand2(operand2),
        .alu_operation(alu_operation),
        .result(result),
        .zero(zero)
    );

    // ----------------------------
    // Test Procedure
    // ----------------------------
    initial begin

        $display("--------------------------------------------------");
        $display("Starting Self-Testing ALU Simulation");
        $display("--------------------------------------------------");

        // Run 50 random test cases
        repeat (50) begin

            // Random operands
            operand1 = $urandom();
            operand2 = $urandom();

            // Random ALU operation (only valid ones)
            case ($urandom_range(0,8))
                0: alu_operation = 4'b0000; // AND
                1: alu_operation = 4'b0001; // OR
                2: alu_operation = 4'b0010; // ADD
                3: alu_operation = 4'b0110; // SUB
                4: alu_operation = 4'b0011; // XOR
                5: alu_operation = 4'b0100; // SLL
                6: alu_operation = 4'b0101; // SRL
                7: alu_operation = 4'b1000; // SRA
                8: alu_operation = 4'b0111; // SLT
            endcase

            // ----------------------------
            // Golden Reference Model
            // ----------------------------
            case (alu_operation)

                4'b0000: expected_result = operand1 & operand2;
                4'b0001: expected_result = operand1 | operand2;
                4'b0010: expected_result = operand1 + operand2;
                4'b0110: expected_result = operand1 - operand2;
                4'b0011: expected_result = operand1 ^ operand2;
                4'b0100: expected_result = operand1 << operand2[4:0];
                4'b0101: expected_result = operand1 >> operand2[4:0];
                4'b1000: expected_result = $signed(operand1) >>> operand2[4:0];
                4'b0111: expected_result =
                         ($signed(operand1) < $signed(operand2)) ? 32'd1 : 32'd0;

                default: expected_result = 32'b0;

            endcase

            // ----------------------------
            // Correct ZERO flag logic
            // zero = 1 only if SUB result = 0
            // ----------------------------
            expected_zero = (alu_operation == 4'b0110) && (expected_result == 32'b0);

            // Wait for combinational logic
            #10;

            // ----------------------------
            // Compare DUT vs expected
            // ----------------------------
            if ((result !== expected_result) || (zero !== expected_zero)) begin

                $display("ERROR at time %0t", $time);
                $display("Operation: %b", alu_operation);
                $display("Operand1: %h  Operand2: %h", operand1, operand2);
                $display("Expected -> Result: %h  Zero: %b",
                          expected_result, expected_zero);
                $display("Actual   -> Result: %h  Zero: %b",
                          result, zero);

                error_count++;

            end

        end

        // ----------------------------
        // Final Report
        // ----------------------------
        $display("--------------------------------------------------");

        if (error_count == 0)
            $display("TEST PASSED: All cases matched successfully.");
        else
            $display("TEST FAILED: %0d errors found.", error_count);

        $display("--------------------------------------------------");

        $finish;

    end

endmodule
