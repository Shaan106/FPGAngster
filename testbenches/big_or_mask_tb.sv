module big_or_mask_tb;

    parameter NUM_CLAUSES = 64;
    parameter VAR_ID_BITS = 8;
    parameter NUM_CLAUSES_PER_CYCLE = 16;
    parameter NUM_VARS_PER_CLAUSE = 3;
    parameter BITMASK_WIDTH = (NUM_VARS_PER_CLAUSE * NUM_CLAUSES_PER_CYCLE);

    reg [BITMASK_WIDTH-1:0] memory_bitmask;
    reg [BITMASK_WIDTH-1:0] assignment_bitmask;
    wire [BITMASK_WIDTH-1:0] output_assignments;
    reg [BITMASK_WIDTH-1:0] expected_final;

    big_or_mask #(
        .NUM_CLAUSES(NUM_CLAUSES),
        .VAR_ID_BITS(VAR_ID_BITS),
        .NUM_CLAUSES_PER_CYCLE(NUM_CLAUSES_PER_CYCLE),
        .NUM_VARS_PER_CLAUSE(NUM_VARS_PER_CLAUSE)
    ) dut (
        .memory_bitmask(memory_bitmask),
        .assignment_bitmask(assignment_bitmask),
        .output_assignments(output_assignments)
    );

    initial begin
        $display("Starting big_or_mask testbench...");
        $display("Bitmask width: %0d bits", BITMASK_WIDTH);
        $display("Logic: output = memory_bitmask OR assignment_bitmask");
        $display("0 = True/symbolic, 1 = False");
        $display("");

        // Test 1: No existing assignments, new assignments only
        $display("=== Test 1: New assignments only ===");
        assignment_bitmask = 48'b000000000000000000000000000000000000000000000000;
        memory_bitmask =     48'b000000000000000000000000000000000000000000001010;
        #1;

        $display("Current assignments: %b", assignment_bitmask);
        $display("New False literals:  %b", memory_bitmask);
        $display("Result:              %b", output_assignments);
        $display("Expected:            %b", memory_bitmask | assignment_bitmask);
        $display("Match: %s", (output_assignments == (memory_bitmask | assignment_bitmask)) ? "PASS" : "FAIL");
        $display("");

        // Test 2: Existing assignments, no new ones
        $display("=== Test 2: Existing assignments only ===");
        assignment_bitmask = 48'b000000000000000000000000000000000000000000010100;
        memory_bitmask =     48'b000000000000000000000000000000000000000000000000;
        #1;

        $display("Current assignments: %b", assignment_bitmask);
        $display("New False literals:  %b", memory_bitmask);
        $display("Result:              %b", output_assignments);
        $display("Expected:            %b", memory_bitmask | assignment_bitmask);
        $display("Match: %s", (output_assignments == (memory_bitmask | assignment_bitmask)) ? "PASS" : "FAIL");
        $display("");

        // Test 3: Mix of existing and new assignments
        $display("=== Test 3: Mixed assignments ===");
        assignment_bitmask = 48'b000000000000000000000000000000000000000000101010;
        memory_bitmask =     48'b000000000000000000000000000000000000000000010101;
        #1;

        $display("Current assignments: %b", assignment_bitmask);
        $display("New False literals:  %b", memory_bitmask);
        $display("Result:              %b", output_assignments);
        $display("Expected:            %b", memory_bitmask | assignment_bitmask);
        $display("Match: %s", (output_assignments == (memory_bitmask | assignment_bitmask)) ? "PASS" : "FAIL");
        $display("");

        // Test 4: Overlapping assignments (idempotent)
        $display("=== Test 4: Overlapping assignments ===");
        assignment_bitmask = 48'b000000000000000000000000000000000000000000111000;
        memory_bitmask =     48'b000000000000000000000000000000000000000000110000;
        #1;

        $display("Current assignments: %b", assignment_bitmask);
        $display("New False literals:  %b", memory_bitmask);
        $display("Result:              %b", output_assignments);
        $display("Expected:            %b", memory_bitmask | assignment_bitmask);
        $display("Note: Positions 4,5 overlap - should remain 1 (idempotent)");
        $display("Match: %s", (output_assignments == (memory_bitmask | assignment_bitmask)) ? "PASS" : "FAIL");
        $display("");

        // Test 5: All bits set
        $display("=== Test 5: All False ===");
        assignment_bitmask = {BITMASK_WIDTH{1'b1}};
        memory_bitmask =     {BITMASK_WIDTH{1'b1}};
        #1;

        $display("Current assignments: all 1s");
        $display("New False literals:  all 1s");
        $display("Result should be:    all 1s");
        $display("Match: %s", (output_assignments == {BITMASK_WIDTH{1'b1}}) ? "PASS" : "FAIL");
        $display("");

        // Test 6: Progressive assignment accumulation
        $display("=== Test 6: Progressive accumulation ===");
        assignment_bitmask = 48'b000000000000000000000000000000000000000000000000;

        // Step 1: Add some assignments
        memory_bitmask = 48'b000000000000000000000000000000000000000000000011;
        #1;
        $display("Step 1 - Add bits 0,1: %b", output_assignments);
        assignment_bitmask = output_assignments;  // Update for next step

        // Step 2: Add more assignments
        memory_bitmask = 48'b000000000000000000000000000000000000000000001100;
        #1;
        $display("Step 2 - Add bits 2,3: %b", output_assignments);
        assignment_bitmask = output_assignments;  // Update for next step

        // Step 3: Add final assignments
        memory_bitmask = 48'b000000000000000000000000000000000000000000110000;
        #1;
        $display("Step 3 - Add bits 4,5: %b", output_assignments);
        $display("Final result should have bits 0,1,2,3,4,5 set");

        expected_final = 48'b000000000000000000000000000000000000000000111111;
        $display("Match: %s", (output_assignments == expected_final) ? "PASS" : "FAIL");

        $display("");
        $display("Testbench completed!");
        $finish;
    end

endmodule