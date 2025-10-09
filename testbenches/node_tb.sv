module node_tb;

    parameter NUM_CLAUSES = 16;
    parameter VAR_ID_BITS = 8;
    parameter NUM_CLAUSES_PER_CYCLE = 16;
    parameter NUM_VARS_PER_CLAUSE = 3;
    parameter PTR_BITS = $clog2(NUM_CLAUSES / NUM_CLAUSES_PER_CYCLE);
    parameter CLAUSE_WIDTH = NUM_VARS_PER_CLAUSE * NUM_CLAUSES_PER_CYCLE;

    reg clk;
    reg reset;
    reg assign_var_val;
    reg [CLAUSE_WIDTH-1:0] clauses_in;
    reg [VAR_ID_BITS-1:0] vars_assignment_number;
    wire [CLAUSE_WIDTH-1:0] clauses_out;
    wire is_node_unsat;

    // Instantiate node
    node #(
        .NUM_CLAUSES(NUM_CLAUSES),
        .VAR_ID_BITS(VAR_ID_BITS),
        .NUM_CLAUSES_PER_CYCLE(NUM_CLAUSES_PER_CYCLE),
        .NUM_VARS_PER_CLAUSE(NUM_VARS_PER_CLAUSE),
        .PTR_BITS(PTR_BITS)
    ) dut (
        .clk(clk),
        .reset(reset),
        .assign_var_val(assign_var_val),
        .clauses_in(clauses_in),
        .vars_assignment_number(vars_assignment_number),
        .clauses_out(clauses_out),
        .is_node_unsat(is_node_unsat)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Test sequence
    initial begin
        $display("Starting node testbench with 3-SAT test case");
        $display("Problem: 16 clauses, 5 variables");
        $display("");
        $display("Initial assignments from test_case.md:");
        $display("  x1 = 1 (False)");
        $display("  x2 = 0 (True)");
        $display("  x3 = 0 (True)");
        $display("  x4 = 0 (True)");
        $display("  x5 = unassigned");
        $display("");
        $display("Test parameters:");
        $display("  vars_assignment_number = 4 (already assigned var 4)");
        $display("  assign_var_val = 1 (assigning False to next variable)");
        $display("  next_var_assignment = 5 (will assign False to x5)");
        $display("");

        // Initialize inputs
        reset = 1;
        assign_var_val = 1'b1;  // Assigning False
        // vars_assignment_number = 8'b11111111;  // Already assigned up to var 
        vars_assignment_number = 8'd1;  // Already assigned up to var 

        // Build clauses_in based on initial assignments
        // Format: 48 bits, 1 bit per variable position (3 vars * 16 clauses)
        // For each variable position in each clause:
        //   - If variable is assigned and makes literal False: 1
        //   - Otherwise: 0
        //
        // Initial assignments: x1=False, x2=True, x3=True, x4=True, x5=unassigned
        // For each clause, we need to check each literal:

        // Clauses: x0 | x1 | x2 for all
        // x0 = 0 (T), x1 = 1 (F), x2 = 2 (unassigned)
        clauses_in = {
            3'b010, // clause 15
            3'b010, // clause 14
            3'b010, // clause 13
            3'b010, // clause 12
            3'b010, // clause 11
            3'b010, // clause 10
            3'b010, // clause 9
            3'b010, // clause 8
            3'b010, // clause 7
            3'b010, // clause 6
            3'b010, // clause 5
            3'b010, // clause 4
            3'b010, // clause 3
            3'b010, // clause 2
            3'b010, // clause 1
            3'b010  // clause 0
        };

        $display("Initial clauses_in: %b", clauses_in);
        $display("");

        // Release reset
        @(posedge clk);
        #1;
        reset = 0;
        #1;

        $display("=== TEST CASE 1: Assign False to x5 ===");
        $display("assign_var_id: %0d, assign_var_val: %b", dut.vars_assignment_number, assign_var_val);
        $display("");
        $display("next_var_assignment: %d", dut.next_var_assignment);
        $display("");
        $display("memory_slice from static_memory: %b", dut.memory_slice);
        $display("");
        $display("Cycle | row_ptr | is_unsat | comparator_bitmask | latched_clauses | clauses_out");
        $display("------|---------|----------|--------------------|-----------------|--------------");
        $display("  %0d   |    %0d    |    %b     | %b         | %h      | %b",
                     $time/10, dut.row_ptr, is_node_unsat,
                     dut.comparator_bitmask, dut.latched_clauses, clauses_out);

        // Run for several cycles to see the dataflow
        repeat (10) begin
            @(posedge clk);
            #1;
            $display("  %0d   |    %0d    |    %b     | %b         | %h      | %b",
                     $time/10 - 1, dut.row_ptr, is_node_unsat,
                     dut.comparator_bitmask, dut.latched_clauses, clauses_out);
        end

        $display("");
        $display("Analysis:");
        $display("  - Next variable to assign: x5 (vars_assignment_number + 1 = 5)");
        $display("  - Assignment value: False (assign_var_val = 1)");
        $display("  - Comparator should find x5 occurrences in memory");
        $display("  - Comparator bitmask should mark literals that become False");
        $display("  - clauses_out should accumulate new False assignments");
        $display("");
        $display("Final is_node_unsat: %b", is_node_unsat);
        $display("");

        $display("========================================");
        $display("Testbench completed!");
        $finish;
    end

endmodule