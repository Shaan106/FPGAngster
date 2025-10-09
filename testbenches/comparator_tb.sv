module comparator_tb;

    parameter NUM_CLAUSES = 64;
    parameter VAR_ID_BITS = 8;
    parameter NUM_CLAUSES_PER_CYCLE = 16;
    parameter NUM_VARS_PER_CLAUSE = 3;
    parameter MEMORY_WIDTH = ((VAR_ID_BITS + 1)*NUM_VARS_PER_CLAUSE)*NUM_CLAUSES_PER_CYCLE;
    parameter BITMASK_WIDTH = (NUM_VARS_PER_CLAUSE * NUM_CLAUSES_PER_CYCLE);

    reg [VAR_ID_BITS-1:0] assign_var_id;
    reg assign_var_val;
    reg [MEMORY_WIDTH-1:0] memory_slice;
    wire [BITMASK_WIDTH-1:0] output_bitmask;
    integer count;
    integer i;

    comparator #(
        .NUM_CLAUSES(NUM_CLAUSES),
        .VAR_ID_BITS(VAR_ID_BITS),
        .NUM_CLAUSES_PER_CYCLE(NUM_CLAUSES_PER_CYCLE),
        .NUM_VARS_PER_CLAUSE(NUM_VARS_PER_CLAUSE)
    ) dut (
        .assign_var_id(assign_var_id),
        .assign_var_val(assign_var_val),
        .memory_slice(memory_slice),
        .output_bitmask(output_bitmask)
    );

    initial begin
        $display("Starting comparator testbench...");
        $display("Memory width: %0d bits, Bitmask width: %0d bits", MEMORY_WIDTH, BITMASK_WIDTH);
        $display("");

        // Test 1: Simple variable matching
        $display("=== Test 1: Variable ID matching ===");
        memory_slice = 0;

        // Put variable 5 (negated) in position 0: bits [8:0] = var_id=5, neg=1
        memory_slice[8:0] = {1'b1, 8'd5};  // neg=1, var_id=5

        // Put variable 5 (not negated) in position 10: bits [98:90] = var_id=5, neg=0
        memory_slice[98:90] = {1'b0, 8'd5};  // neg=0, var_id=5

        assign_var_id = 5;
        assign_var_val = 0;  // Assign True
        #1;

        $display("Looking for variable %0d, assigning True", assign_var_id);
        $display("Expected: bitmask[0]=1, bitmask[10]=0, others=0");
        $display("Actual bitmask: %b", output_bitmask);
        $display("Position 0: %b, Position 10: %b", output_bitmask[0], output_bitmask[10]);
        $display("");

        // Test 2: Assign False to same variable
        $display("=== Test 2: Assign False ===");
        assign_var_val = 1;  // Assign False
        #1;

        $display("Looking for variable %0d, assigning False", assign_var_id);
        $display("Expected: bitmask[0]=0, bitmask[10]=1, others=0");
        $display("Actual bitmask: %b", output_bitmask);
        $display("Position 0: %b, Position 10: %b", output_bitmask[0], output_bitmask[10]);
        $display("");

        // Test 3: Variable not found
        $display("=== Test 3: Variable not found ===");
        assign_var_id = 99;  // Variable not in memory
        assign_var_val = 0;
        #1;

        $display("Looking for variable %0d (not in memory)", assign_var_id);
        $display("Expected: all bits = 0");
        $display("Actual bitmask: %b", output_bitmask);
        $display("Sum of bits: %0d (should be 0)", $countones(output_bitmask));
        $display("");

        // Test 4: Multiple occurrences
        $display("=== Test 4: Multiple occurrences ===");
        memory_slice = 0;

        // Put variable 7 in multiple positions with different negations
        memory_slice[8:0]   = {1'b0, 8'd7};   // pos 0: var 7, neg=0
        memory_slice[17:9]  = {1'b1, 8'd7};   // pos 1: var 7, neg=1
        memory_slice[26:18] = {1'b0, 8'd7};   // pos 2: var 7, neg=0

        assign_var_id = 7;
        assign_var_val = 0;  // Assign True
        #1;

        $display("Variable 7 appears at positions 0,1,2 with neg bits 0,1,0");
        $display("Assigning True: expect bitmask[0]=0, bitmask[1]=1, bitmask[2]=0");
        $display("Actual: pos[0]=%b, pos[1]=%b, pos[2]=%b",
                 output_bitmask[0], output_bitmask[1], output_bitmask[2]);
        $display("");

        // Test case 6: Many occurrences of same variable (like x1 in actual problem)
        $display("=== Test 6: Variable with many occurrences ===");
        memory_slice = 0;

        // Put variable 1 in many positions with mixed negations
        // Position 0: x1 (neg=0)
        memory_slice[8:0] = {1'b0, 8'd1};
        // Position 2: ~x1 (neg=1)
        memory_slice[26:18] = {1'b1, 8'd1};
        // Position 5: x1 (neg=0)
        memory_slice[53:45] = {1'b0, 8'd1};
        // Position 8: ~x1 (neg=1)
        memory_slice[80:72] = {1'b1, 8'd1};
        // Position 11: x1 (neg=0)
        memory_slice[107:99] = {1'b0, 8'd1};

        assign_var_id = 1;
        assign_var_val = 1'b0;  // Assign False to x1
        #1;

        $display("Variable 1 at positions 0(neg=0), 3(neg=1), 6(neg=0), 9(neg=1), 12(neg=0)");
        $display("Assigning False to x1: positive x1 (neg=0) should become False");
        $display("Expected: bits 0, 6, 12 set to 1");
        $display("Actual bitmask: %b", output_bitmask);
        $display("pos[0]=%b, pos[3]=%b, pos[6]=%b, pos[9]=%b, pos[12]=%b",
                 output_bitmask[0], output_bitmask[2], output_bitmask[5],
                 output_bitmask[8], output_bitmask[11]);

        count = 0;
        for (i = 0; i < BITMASK_WIDTH; i = i + 1) begin
            if (output_bitmask[i]) count = count + 1;
        end
        $display("Total bits set: %0d (expected: 3)", count);
        $display("");

        $display("Testbench completed!");
        $finish;
    end

endmodule