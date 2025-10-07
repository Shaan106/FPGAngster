module isUnsat_register_tb;

    reg current_clause_evaluation;
    reg clk;
    reg reset;
    wire is_unsat;

    isUnsat_register dut (
        .current_clause_evaluation(current_clause_evaluation),
        .clk(clk),
        .reset(reset),
        .is_unsat(is_unsat)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Test sequence
    initial begin
        $display("Starting isUnsat_register testbench...");
        $display("Testing sticky unsat behavior");
        $display("");

        // Test 1: Reset behavior
        $display("=== Test 1: Reset clears unsat ===");
        reset = 1;
        current_clause_evaluation = 0;
        @(posedge clk);
        #1;
        $display("After reset: is_unsat = %b (expected: 0)", is_unsat);
        $display("Match: %s", (is_unsat == 0) ? "PASS" : "FAIL");
        $display("");

        // Test 2: No unsat clauses
        $display("=== Test 2: All clauses satisfied ===");
        reset = 0;
        current_clause_evaluation = 0;
        repeat (5) begin
            @(posedge clk);
            #1;
            $display("Cycle with clause_eval=0: is_unsat = %b", is_unsat);
        end
        $display("Match: %s", (is_unsat == 0) ? "PASS" : "FAIL");
        $display("");

        // Test 3: First unsat clause
        $display("=== Test 3: First unsat clause detected ===");
        current_clause_evaluation = 1;
        @(posedge clk);
        #1;
        $display("After first unsat clause: is_unsat = %b (expected: 1)", is_unsat);
        $display("Match: %s", (is_unsat == 1) ? "PASS" : "FAIL");
        $display("");

        // Test 4: Sticky behavior - stays high
        $display("=== Test 4: Sticky behavior (stays high) ===");
        current_clause_evaluation = 0;
        repeat (5) begin
            @(posedge clk);
            #1;
            $display("Cycle with clause_eval=0: is_unsat = %b (should stay 1)", is_unsat);
        end
        $display("Match: %s", (is_unsat == 1) ? "PASS" : "FAIL");
        $display("");

        // Test 5: Multiple unsat clauses
        $display("=== Test 5: Multiple unsat clauses ===");
        current_clause_evaluation = 1;
        repeat (3) begin
            @(posedge clk);
            #1;
            $display("Cycle with clause_eval=1: is_unsat = %b", is_unsat);
        end
        $display("Match: %s", (is_unsat == 1) ? "PASS" : "FAIL");
        $display("");

        // Test 6: Reset after unsat
        $display("=== Test 6: Reset after unsat ===");
        reset = 1;
        @(posedge clk);
        #1;
        $display("After reset (was unsat): is_unsat = %b (expected: 0)", is_unsat);
        $display("Match: %s", (is_unsat == 0) ? "PASS" : "FAIL");
        $display("");

        // Test 7: Can set unsat again after reset
        $display("=== Test 7: Can set unsat again after reset ===");
        reset = 0;
        current_clause_evaluation = 0;
        @(posedge clk);
        #1;
        $display("Cycle 1 after reset (eval=0): is_unsat = %b", is_unsat);

        current_clause_evaluation = 1;
        @(posedge clk);
        #1;
        $display("Cycle 2 after reset (eval=1): is_unsat = %b (expected: 1)", is_unsat);
        $display("Match: %s", (is_unsat == 1) ? "PASS" : "FAIL");

        $display("");
        $display("Testbench completed!");
        $finish;
    end

endmodule