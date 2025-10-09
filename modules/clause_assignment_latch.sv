module clause_assignment_latch #(
    parameter NUM_CLAUSES = 16,
    parameter NUM_VARS_PER_CLAUSE = 3
) (
    input  wire clk,
    input  wire [(NUM_VARS_PER_CLAUSE * NUM_CLAUSES)-1:0] input_latched_clauses,
    output wire [(NUM_VARS_PER_CLAUSE * NUM_CLAUSES)-1:0] output_latched_clauses
);

    // latch to hold current clause assignments
    reg [(NUM_VARS_PER_CLAUSE * NUM_CLAUSES)-1:0] latched_clauses_reg;

    // update latched clauses on clock edge
    always @(posedge clk) begin
        latched_clauses_reg <= input_latched_clauses;
    end

    // output current latched value
    assign output_latched_clauses = latched_clauses_reg;

endmodule