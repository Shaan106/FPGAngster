module big_or_mask #(
    parameter NUM_CLAUSES = 64,
    parameter VAR_ID_BITS = 8,
    parameter NUM_CLAUSES_PER_CYCLE = 16,
    parameter NUM_VARS_PER_CLAUSE = 3
) (
    input wire [(NUM_VARS_PER_CLAUSE * NUM_CLAUSES_PER_CYCLE)-1:0] memory_bitmask, // each bit represents whether the looked up var is assigned T/F given negation etc 
    input wire [(NUM_VARS_PER_CLAUSE * NUM_CLAUSES_PER_CYCLE)-1:0] assignment_bitmask,
    output wire [(NUM_VARS_PER_CLAUSE * NUM_CLAUSES_PER_CYCLE)-1:0] output_assignments
);

    // receive a bitmask from comparator (which clauses have just been assigned F)

    // receive a bitmask of current assignments (0 - either true or symbolic, 1 - false)

    // here we do OR them together to assign all the new F assignments to the current assignments

    assign output_assignments = memory_bitmask | assignment_bitmask;

endmodule