module node #(
    parameter NUM_CLAUSES = 16,
    parameter VAR_ID_BITS = 8,
    parameter NUM_CLAUSES_PER_CYCLE = 16,
    parameter NUM_VARS_PER_CLAUSE = 3,
    parameter PTR_BITS = $clog2(NUM_CLAUSES / NUM_CLAUSES_PER_CYCLE)
) (
    input  wire clk,
    input  wire reset,
    input  wire assign_var_val, // are we assigning T (0) or F (1) to the variable?
    input  wire [(NUM_VARS_PER_CLAUSE * NUM_CLAUSES_PER_CYCLE)-1:0] clauses_in,
    input  wire [VAR_ID_BITS-1:0] vars_assignment_number,
    output wire [(NUM_VARS_PER_CLAUSE * NUM_CLAUSES_PER_CYCLE)-1:0] clauses_out,
    output wire is_node_unsat
);

    // based on diagram_v2
    /// --------------------------------------------------------------------------------------------------------------------
    // PATH 1: clause -> clause_evaluator -> isUnsat_register -> is_node_unsat

    // Wire to hold clause evaluation result
    wire current_clause_evaluation;

    // Instantiate clause evaluator
    clause_evaluator #(
        .NUM_CLAUSES(NUM_CLAUSES_PER_CYCLE),
        .NUM_VARS_PER_CLAUSE(NUM_VARS_PER_CLAUSE)
    ) eval (
        .clauses(clauses_in),
        .unsatisfied(current_clause_evaluation)
    );

    // Instantiate unsat register
    isUnsat_register unsat_reg (
        .current_clause_evaluation(current_clause_evaluation),
        .clk(clk),
        .reset(reset),
        .is_unsat(is_node_unsat)
    );

    /// --------------------------------------------------------------------------------------------------------------------
    // PATH 2a: clk -> row_ptr_counter -> static_memory -> comparator -> comparator_bitmask
    // PATH 2b: (vars_assignment_number + 1) -> comparator -> comparator_bitmask

    localparam NUM_ROWS = NUM_CLAUSES / NUM_CLAUSES_PER_CYCLE;
    localparam MEMORY_WIDTH = ((VAR_ID_BITS + 1)*NUM_VARS_PER_CLAUSE)*NUM_CLAUSES_PER_CYCLE;

    wire [PTR_BITS-1:0] row_ptr;
    wire [MEMORY_WIDTH-1:0] memory_slice;
    wire [(NUM_VARS_PER_CLAUSE * NUM_CLAUSES_PER_CYCLE)-1:0] comparator_bitmask;
    wire [VAR_ID_BITS-1:0] next_var_assignment;

    // Next variable assignment (vars_assignment_number + 1)
    assign next_var_assignment = vars_assignment_number + 1;

    // Instantiate row pointer counter
    row_ptr_counter #(
        .NUM_ROWS(NUM_ROWS),
        .PTR_BITS(PTR_BITS)
    ) counter (
        .clk(clk),
        .reset(reset),
        .row_ptr(row_ptr)
    );

    // Instantiate static memory
    static_memory #(
        .NUM_CLAUSES(NUM_CLAUSES),
        .VAR_ID_BITS(VAR_ID_BITS),
        .NUM_CLAUSES_PER_CYCLE(NUM_CLAUSES_PER_CYCLE),
        .NUM_VARS_PER_CLAUSE(NUM_VARS_PER_CLAUSE),
        .PTR_BITS(PTR_BITS)
    ) mem (
        .row_ptr(row_ptr),
        .output_memory_slice(memory_slice)
    );

    // assign var val - are we assigning T (0) or F (1) to the variable?
    // assume for now, assigning T (0)
    // wire assign_var_val = 1'b0; // TODO: Connect to actual assignment value

    // Instantiate comparator
    comparator #(
        .NUM_CLAUSES(NUM_CLAUSES),
        .VAR_ID_BITS(VAR_ID_BITS),
        .NUM_CLAUSES_PER_CYCLE(NUM_CLAUSES_PER_CYCLE),
        .NUM_VARS_PER_CLAUSE(NUM_VARS_PER_CLAUSE)
    ) comp (
        .assign_var_id(next_var_assignment),
        .assign_var_val(assign_var_val),
        .memory_slice(memory_slice),
        .output_bitmask(comparator_bitmask)
    );

    /// --------------------------------------------------------------------------------------------------------------------
    // PATH 3a: comparator_bitmask -> big_or -> clauses_out
    // PATH 3b: clauses_in -> (latches for timing) -> big_or -> clauses_out

    wire [(NUM_VARS_PER_CLAUSE * NUM_CLAUSES_PER_CYCLE)-1:0] latched_clauses;

    // Latch clauses_in for timing alignment
    clause_assignment_latch #(
        .NUM_CLAUSES(NUM_CLAUSES_PER_CYCLE),
        .NUM_VARS_PER_CLAUSE(NUM_VARS_PER_CLAUSE)
    ) latch (
        .clk(clk),
        .input_latched_clauses(clauses_in),
        .output_latched_clauses(latched_clauses)
    );

    // Combine comparator bitmask with latched clauses using big_or
    big_or_mask #(
        .NUM_CLAUSES(NUM_CLAUSES),
        .VAR_ID_BITS(VAR_ID_BITS),
        .NUM_CLAUSES_PER_CYCLE(NUM_CLAUSES_PER_CYCLE),
        .NUM_VARS_PER_CLAUSE(NUM_VARS_PER_CLAUSE)
    ) big_or (
        .memory_bitmask(comparator_bitmask),
        .assignment_bitmask(latched_clauses),
        .output_assignments(clauses_out)
    );

endmodule