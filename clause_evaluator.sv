/**
 * Clause Evaluator Module - Purely Combinational
 *
 * Evaluates multiple 3-SAT clauses in parallel using combinational logic.
 * Takes n clauses as input, performs OR within each clause, then ANDs all results.
 *
 * Input format: Packed array of clause values (2 bits per term, 3 terms per clause)
 * Output: 2'b00=UNSAT, 2'b01=SAT, 2'b10=UNKNOWN
 *
 * This is a zero-latency combinational module - no clock required.
 */

module clause_evaluator #(
    parameter NUM_CLAUSES = 1,        // Number of clauses to evaluate in parallel
    parameter TERMS_PER_CLAUSE = 3,   // Fixed at 3 for 3-SAT
    parameter VALUE_WIDTH = 2         // 2 bits per value (00=False, 01=True, 10=Unknown)
)(
    input  logic [NUM_CLAUSES*TERMS_PER_CLAUSE*VALUE_WIDTH-1:0] clause_values,
    output logic [1:0] result  // 00=UNSAT, 01=SAT, 10=UNKNOWN
);

    // Local parameters for result encoding
    localparam UNSAT   = 2'b00;
    localparam SAT     = 2'b01;
    localparam UNKNOWN = 2'b10;

    // Value encoding from inputs
    localparam VAL_FALSE   = 2'b00;
    localparam VAL_TRUE    = 2'b01;
    localparam VAL_UNKNOWN = 2'b10;

    // Intermediate signals for each clause evaluation
    logic [1:0] clause_results [NUM_CLAUSES-1:0];

    // Unpack the input into a 2D array for easier manipulation
    logic [VALUE_WIDTH-1:0] terms [NUM_CLAUSES-1:0][TERMS_PER_CLAUSE-1:0];

    // Unpack the flat input into 2D array
    genvar i, j;
    generate
        for (i = 0; i < NUM_CLAUSES; i++) begin : unpack_clauses
            for (j = 0; j < TERMS_PER_CLAUSE; j++) begin : unpack_terms
                assign terms[i][j] = clause_values[(i*TERMS_PER_CLAUSE + j)*VALUE_WIDTH +: VALUE_WIDTH];
            end
        end
    endgenerate

    // Evaluate each clause (OR operation within clause)
    generate
        for (i = 0; i < NUM_CLAUSES; i++) begin : eval_clauses
            always_comb begin
                // Check if any term is TRUE (clause is satisfied)
                if (terms[i][0] == VAL_TRUE ||
                    terms[i][1] == VAL_TRUE ||
                    terms[i][2] == VAL_TRUE) begin
                    clause_results[i] = SAT;
                end
                // Check if all terms are FALSE (clause is unsatisfied)
                else if (terms[i][0] == VAL_FALSE &&
                         terms[i][1] == VAL_FALSE &&
                         terms[i][2] == VAL_FALSE) begin
                    clause_results[i] = UNSAT;
                end
                // Otherwise, clause contains unknowns
                else begin
                    clause_results[i] = UNKNOWN;
                end
            end
        end
    endgenerate

    // Combine all clause results (AND operation across clauses)
    logic has_unsat;
    logic has_unknown;

    always_comb begin
        // Initialize flags
        has_unsat = 1'b0;
        has_unknown = 1'b0;

        // Check all clause results
        for (int k = 0; k < NUM_CLAUSES; k++) begin
            if (clause_results[k] == UNSAT) begin
                has_unsat = 1'b1;
            end
            if (clause_results[k] == UNKNOWN) begin
                has_unknown = 1'b1;
            end
        end

        // Determine final result based on flags
        if (has_unsat) begin
            result = UNSAT;
        end
        else if (has_unknown) begin
            result = UNKNOWN;
        end
        else begin
            result = SAT;
        end
    end

endmodule