module comparator #(
    parameter NUM_CLAUSES = 64,
    parameter VAR_ID_BITS = 8,
    parameter NUM_CLAUSES_PER_CYCLE = 16,
    parameter NUM_VARS_PER_CLAUSE = 3
) (
    input  wire [VAR_ID_BITS-1: 0] assign_var_id, // which clause IDs we are trying to look up
    input  wire assign_var_val, // which clause IDs we are trying to look up
    input  wire [((VAR_ID_BITS + 1)*NUM_VARS_PER_CLAUSE)*NUM_CLAUSES_PER_CYCLE-1:0] memory_slice,
    output wire [(NUM_VARS_PER_CLAUSE * NUM_CLAUSES_PER_CYCLE)-1:0] output_bitmask // each bit represents whether the looked up var is assigned T/F given negation etc 
);


// memory_slice looks like:
// { [var1_id (8), var1_neg (1)], [var2_id (8), var2_neg (1)], [var3_id (8), var3_neg (1)] } * 16 clauses

// want to make a comparator that takes in a var_id and provides "locations" of that var_id as T/F

    wire [(NUM_VARS_PER_CLAUSE * NUM_CLAUSES_PER_CYCLE)-1:0] assign_var_TF_bitmask;

    genvar i;
    generate
        for (i = 0; i < NUM_CLAUSES_PER_CYCLE * NUM_VARS_PER_CLAUSE; i = i + 1) begin : var_compare
            // starting bit of current var to look at in memory slice
            localparam VAR_START_BIT = i * (VAR_ID_BITS + 1);

            // get var_id and negation bit
            wire [VAR_ID_BITS-1:0] current_var_id = memory_slice[VAR_START_BIT +: VAR_ID_BITS];
            wire current_neg_bit = memory_slice[VAR_START_BIT + VAR_ID_BITS];

            // if current_var_id == assign_var_id, update our bitmask
            assign assign_var_TF_bitmask[i] = (current_var_id == assign_var_id) ? current_neg_bit : 1'b0;
        end
    endgenerate

    // if assign_var_val is 1 (which in our case is false), we want to flip the bits in the bitmask
    // because assigning F to !A means (!A) is true
    assign output_bitmask = assign_var_val ? ~assign_var_TF_bitmask : assign_var_TF_bitmask;

endmodule