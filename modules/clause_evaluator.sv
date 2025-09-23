module clause_evaluator #(
    parameter NUM_CLAUSES = 16,
    parameter NUM_VARS_PER_CLAUSE = 3
) (
    input  wire [NUM_CLAUSES*NUM_VARS_PER_CLAUSE-1:0] clauses,
    output wire        unsatisfied
);

// 0 is True/symbolic
// 1 is False

    wire [NUM_CLAUSES-1:0] clause_results;

    // for every clause, 
    // UNSAT if
    //          every var in clause is false
    //              any clause is in that state.
    // therefore, and every clause. or all clauses
    genvar i;
    generate
        for (i = 0; i < NUM_CLAUSES; i = i + 1) begin : clause_eval
            assign clause_results[i] = &clauses[i*NUM_VARS_PER_CLAUSE +: NUM_VARS_PER_CLAUSE];
        end
    endgenerate

    assign unsatisfied = |clause_results;

endmodule