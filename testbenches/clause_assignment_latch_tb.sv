module clause_assignment_latch_tb;

    parameter NUM_CLAUSES = 16;
    parameter NUM_VARS_PER_CLAUSE = 3;
    parameter WIDTH = NUM_VARS_PER_CLAUSE * NUM_CLAUSES;

    reg clk;
    reg [WIDTH-1:0] input_latched_clauses;
    wire [WIDTH-1:0] output_latched_clauses;

    clause_assignment_latch #(
        .NUM_CLAUSES(NUM_CLAUSES),
        .NUM_VARS_PER_CLAUSE(NUM_VARS_PER_CLAUSE)
    ) dut (
        .clk(clk),
        .input_latched_clauses(input_latched_clauses),
        .output_latched_clauses(output_latched_clauses)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Test sequence
    initial begin
        $display("Starting clause_assignment_latch testbench...");
        $display("Data width: %0d bits (%0d clauses * %0d vars)", WIDTH, NUM_CLAUSES, NUM_VARS_PER_CLAUSE);
        $display("");

        // Test 1: Initial state (output should be X until first clock)
        $display("=== Test 1: Initial state ===");
        input_latched_clauses = 48'h000000000000;
        #1;
        $display("Before first clock: output = %h", output_latched_clauses);
        $display("");

        // Test 2: Latch first value
        $display("=== Test 2: Latch first value ===");
        input_latched_clauses = 48'h123456789ABC;
        $display("Input: %h", input_latched_clauses);
        @(posedge clk);
        #1;
        $display("After posedge clk: output = %h", output_latched_clauses);
        $display("Match: %s", (output_latched_clauses == 48'h123456789ABC) ? "PASS" : "FAIL");
        $display("");

        // Test 3: Output holds value when input changes (before clock)
        $display("=== Test 3: Output holds until next clock ===");
        input_latched_clauses = 48'hFEDCBA098765;
        #1;
        $display("Changed input to: %h", input_latched_clauses);
        $display("Output (before clk): %h (should still be old value)", output_latched_clauses);
        $display("Match: %s", (output_latched_clauses == 48'h123456789ABC) ? "PASS" : "FAIL");
        $display("");

        // Test 4: New value latched on next clock
        $display("=== Test 4: Latch new value ===");
        @(posedge clk);
        #1;
        $display("After posedge clk: output = %h", output_latched_clauses);
        $display("Match: %s", (output_latched_clauses == 48'hFEDCBA098765) ? "PASS" : "FAIL");
        $display("");

        // Test 5: Sequence of values
        $display("=== Test 5: Sequence of values ===");
        input_latched_clauses = 48'hAAAAAAAAAAAA;
        @(posedge clk);
        #1;
        $display("Cycle 1: input=%h, output=%h", 48'hAAAAAAAAAAAA, output_latched_clauses);

        input_latched_clauses = 48'h555555555555;
        @(posedge clk);
        #1;
        $display("Cycle 2: input=%h, output=%h", 48'h555555555555, output_latched_clauses);

        input_latched_clauses = 48'hF0F0F0F0F0F0;
        @(posedge clk);
        #1;
        $display("Cycle 3: input=%h, output=%h", 48'hF0F0F0F0F0F0, output_latched_clauses);
        $display("");

        // Test 6: All zeros
        $display("=== Test 6: All zeros ===");
        input_latched_clauses = 48'h000000000000;
        @(posedge clk);
        #1;
        $display("Input: %h, Output: %h", input_latched_clauses, output_latched_clauses);
        $display("Match: %s", (output_latched_clauses == 48'h000000000000) ? "PASS" : "FAIL");
        $display("");

        // Test 7: All ones
        $display("=== Test 7: All ones ===");
        input_latched_clauses = 48'hFFFFFFFFFFFF;
        @(posedge clk);
        #1;
        $display("Input: %h, Output: %h", input_latched_clauses, output_latched_clauses);
        $display("Match: %s", (output_latched_clauses == 48'hFFFFFFFFFFFF) ? "PASS" : "FAIL");
        $display("");

        $display("Testbench completed!");
        $finish;
    end

endmodule