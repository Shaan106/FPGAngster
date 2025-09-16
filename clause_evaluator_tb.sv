/**
 * Clause Evaluator Testbench
 *
 * Comprehensive testing of the purely combinational clause evaluator module.
 * Tests single and multiple clause evaluation with all possible outcomes.
 */

module clause_evaluator_tb;

    // Test signals for different configurations
    logic [5:0]  single_clause_input;     // 1 clause * 3 terms * 2 bits
    logic [23:0] four_clause_input;       // 4 clauses * 3 terms * 2 bits
    logic [95:0] sixteen_clause_input;    // 16 clauses * 3 terms * 2 bits

    logic [1:0] single_result;
    logic [1:0] four_result;
    logic [1:0] sixteen_result;

    // Result encoding
    localparam UNSAT   = 2'b00;
    localparam SAT     = 2'b01;
    localparam UNKNOWN = 2'b10;

    // Value encoding
    localparam FALSE   = 2'b00;
    localparam TRUE    = 2'b01;
    localparam UNK     = 2'b10;

    // Instantiate DUTs with different parameters
    clause_evaluator #(.NUM_CLAUSES(1)) single_dut (
        .clause_values(single_clause_input),
        .result(single_result)
    );

    clause_evaluator #(.NUM_CLAUSES(4)) four_dut (
        .clause_values(four_clause_input),
        .result(four_result)
    );

    clause_evaluator #(.NUM_CLAUSES(16)) sixteen_dut (
        .clause_values(sixteen_clause_input),
        .result(sixteen_result)
    );

    // Test task to display results
    task display_result(input string test_name, input [1:0] expected, input [1:0] actual);
        string exp_str, act_str;

        case (expected)
            UNSAT:   exp_str = "UNSAT";
            SAT:     exp_str = "SAT";
            UNKNOWN: exp_str = "UNKNOWN";
            default: exp_str = "INVALID";
        endcase

        case (actual)
            UNSAT:   act_str = "UNSAT";
            SAT:     act_str = "SAT";
            UNKNOWN: act_str = "UNKNOWN";
            default: act_str = "INVALID";
        endcase

        if (expected == actual) begin
            $display("  ✓ PASS: %s - Expected: %s, Got: %s", test_name, exp_str, act_str);
        end else begin
            $display("  ✗ FAIL: %s - Expected: %s, Got: %s", test_name, exp_str, act_str);
        end
    endtask

    initial begin
        $display("=== Clause Evaluator Testbench ===\n");

        // Test 1: Single Clause Tests
        $display("Test 1: Single Clause Evaluation");

        // Test 1.1: All TRUE - should be SAT
        single_clause_input = {TRUE, TRUE, TRUE};  // (T v T v T) = SAT
        #1;
        display_result("All TRUE", SAT, single_result);

        // Test 1.2: All FALSE - should be UNSAT
        single_clause_input = {FALSE, FALSE, FALSE};  // (F v F v F) = UNSAT
        #1;
        display_result("All FALSE", UNSAT, single_result);

        // Test 1.3: One TRUE - should be SAT
        single_clause_input = {FALSE, TRUE, FALSE};  // (F v T v F) = SAT
        #1;
        display_result("One TRUE", SAT, single_result);

        // Test 1.4: All UNKNOWN - should be UNKNOWN
        single_clause_input = {UNK, UNK, UNK};  // (? v ? v ?) = UNKNOWN
        #1;
        display_result("All UNKNOWN", UNKNOWN, single_result);

        // Test 1.5: Mixed with UNKNOWN but no TRUE - should be UNKNOWN
        single_clause_input = {FALSE, UNK, FALSE};  // (F v ? v F) = UNKNOWN
        #1;
        display_result("Mixed FALSE/UNKNOWN", UNKNOWN, single_result);

        // Test 1.6: TRUE with UNKNOWN - should be SAT
        single_clause_input = {TRUE, UNK, FALSE};  // (T v ? v F) = SAT
        #1;
        display_result("TRUE with UNKNOWN", SAT, single_result);

        // Test 2: Four Clause Tests
        $display("\nTest 2: Four Clause Evaluation");

        // Test 2.1: All clauses SAT - should be SAT
        // Clause 0: (T v F v F), Clause 1: (F v T v F), Clause 2: (F v F v T), Clause 3: (T v T v T)
        four_clause_input = {TRUE, TRUE, TRUE,   // Clause 3
                            FALSE, FALSE, TRUE,   // Clause 2
                            FALSE, TRUE, FALSE,   // Clause 1
                            FALSE, FALSE, TRUE};  // Clause 0
        #1;
        display_result("All clauses SAT", SAT, four_result);

        // Test 2.2: One clause UNSAT - should be UNSAT
        // Clause 0: (T v F v F), Clause 1: (F v F v F), Clause 2: (F v F v T), Clause 3: (T v T v T)
        four_clause_input = {TRUE, TRUE, TRUE,    // Clause 3
                            FALSE, FALSE, TRUE,    // Clause 2
                            FALSE, FALSE, FALSE,   // Clause 1 - UNSAT
                            FALSE, FALSE, TRUE};   // Clause 0
        #1;
        display_result("One clause UNSAT", UNSAT, four_result);

        // Test 2.3: All clauses UNKNOWN - should be UNKNOWN
        four_clause_input = {UNK, UNK, FALSE,     // Clause 3
                            UNK, FALSE, UNK,       // Clause 2
                            FALSE, UNK, UNK,       // Clause 1
                            UNK, FALSE, FALSE};    // Clause 0
        #1;
        display_result("All clauses have UNKNOWN", UNKNOWN, four_result);

        // Test 2.4: Mix of SAT and UNKNOWN - should be UNKNOWN
        four_clause_input = {TRUE, FALSE, FALSE,  // Clause 3 - SAT
                            FALSE, TRUE, FALSE,    // Clause 2 - SAT
                            UNK, FALSE, FALSE,     // Clause 1 - UNKNOWN
                            TRUE, TRUE, TRUE};     // Clause 0 - SAT
        #1;
        display_result("Mix SAT and UNKNOWN", UNKNOWN, four_result);

        // Test 3: Sixteen Clause Tests (Edge case)
        $display("\nTest 3: Sixteen Clause Evaluation");

        // Test 3.1: All SAT
        for (int i = 0; i < 16; i++) begin
            sixteen_clause_input[i*6 +: 6] = {FALSE, FALSE, TRUE};  // Each clause has at least one TRUE
        end
        #1;
        display_result("16 clauses all SAT", SAT, sixteen_result);

        // Test 3.2: Last clause UNSAT
        sixteen_clause_input[15*6 +: 6] = {FALSE, FALSE, FALSE};  // Make last clause UNSAT
        #1;
        display_result("16 clauses, last UNSAT", UNSAT, sixteen_result);

        // Test 3.3: First clause UNSAT
        for (int i = 0; i < 16; i++) begin
            sixteen_clause_input[i*6 +: 6] = {FALSE, TRUE, FALSE};  // Reset all to SAT
        end
        sixteen_clause_input[0*6 +: 6] = {FALSE, FALSE, FALSE};  // Make first clause UNSAT
        #1;
        display_result("16 clauses, first UNSAT", UNSAT, sixteen_result);

        // Test 4: Timing Verification (Combinational behavior)
        $display("\nTest 4: Combinational Timing Verification");

        // Change input and immediately check output (no clock edge needed)
        single_clause_input = {TRUE, FALSE, FALSE};
        #0;  // Zero delay - combinational
        display_result("Immediate response (SAT)", SAT, single_result);

        single_clause_input = {FALSE, FALSE, FALSE};
        #0;  // Zero delay
        display_result("Immediate response (UNSAT)", UNSAT, single_result);

        single_clause_input = {UNK, FALSE, FALSE};
        #0;  // Zero delay
        display_result("Immediate response (UNKNOWN)", UNKNOWN, single_result);

        // Test 5: Pattern Tests
        $display("\nTest 5: Pattern Recognition Tests");

        // Test 5.1: Alternating TRUE/FALSE pattern
        four_clause_input = {TRUE, FALSE, TRUE,    // Clause 3 - SAT
                            FALSE, TRUE, FALSE,     // Clause 1 - SAT
                            TRUE, FALSE, TRUE,      // Clause 2 - SAT
                            FALSE, TRUE, FALSE};    // Clause 0 - SAT
        #1;
        display_result("Alternating pattern", SAT, four_result);

        // Test 5.2: Progressive unknown introduction
        four_clause_input = {TRUE, TRUE, TRUE,     // Clause 3 - SAT
                            TRUE, TRUE, UNK,        // Clause 2 - SAT
                            TRUE, UNK, UNK,         // Clause 1 - SAT
                            UNK, UNK, UNK};         // Clause 0 - UNKNOWN
        #1;
        display_result("Progressive unknown", UNKNOWN, four_result);

        $display("\n=== Testbench Complete ===");
        $display("All tests executed. Review results above.");
        $finish;
    end

endmodule