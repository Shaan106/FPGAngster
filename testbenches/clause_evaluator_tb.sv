module clause_evaluator_tb;

    parameter NUM_CLAUSES = 16;
    parameter NUM_VARS_PER_CLAUSE = 3;
    parameter INPUT_WIDTH = NUM_CLAUSES * NUM_VARS_PER_CLAUSE;

    reg [INPUT_WIDTH-1:0] clauses;
    wire unsatisfied;

    clause_evaluator #(
        .NUM_CLAUSES(NUM_CLAUSES),
        .NUM_VARS_PER_CLAUSE(NUM_VARS_PER_CLAUSE)
    ) dut (
        .clauses(clauses),
        .unsatisfied(unsatisfied)
    );

    initial begin
        $display("Starting clause evaluator testbench...");
        $display("Input format: %0d bits (%0d clauses * %0d vars/clause)", INPUT_WIDTH, NUM_CLAUSES, NUM_VARS_PER_CLAUSE);
        $display("0 = True, 1 = False");
        $display("UNSAT if any clause has all variables False (111)");
        $display("");

        // Test case 1: All clauses satisfied (at least one True per clause)
        clauses = 48'b110_110_110_110_110_110_110_110_110_110_110_110_110_110_110_110;
        #10;
        $display("Test 1 - All clauses have at least one True:");
        $display("Input:  %b", clauses);
        $display("UNSAT:  %b (Expected: 0)", unsatisfied);
        $display("");

        // Test case 2: One clause unsatisfied (all False)
        clauses = 48'b110_110_110_110_110_110_110_110_110_110_110_110_110_110_110_111;
        #10;
        $display("Test 2 - Last clause all False:");
        $display("Input:  %b", clauses);
        $display("UNSAT:  %b (Expected: 1)", unsatisfied);
        $display("");

        // Test case 3: All clauses unsatisfied
        clauses = 48'b111_111_111_111_111_111_111_111_111_111_111_111_111_111_111_111;
        #10;
        $display("Test 3 - All clauses unsatisfied:");
        $display("Input:  %b", clauses);
        $display("UNSAT:  %b (Expected: 1)", unsatisfied);
        $display("");

        // Test case 4: All clauses satisfied (all True)
        clauses = 48'b000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000;
        #10;
        $display("Test 4 - All variables True:");
        $display("Input:  %b", clauses);
        $display("UNSAT:  %b (Expected: 0)", unsatisfied);
        $display("");

        // Test case 5: Custom test - you can modify this
        clauses = 48'b111_000_101_010_110_001_111_100_011_101_010_110_001_011_101_010;
        #10;
        $display("Test 5 - Custom test:");
        $display("Input:  %b", clauses);
        $display("UNSAT:  %b", unsatisfied);
        $display("");

        $display("Testbench completed.");
        $finish;
    end

endmodule