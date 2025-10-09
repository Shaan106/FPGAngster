module comparator #(
    parameter NUM_CLAUSES = 64,
    parameter VAR_ID_BITS = 8,
    parameter NUM_CLAUSES_PER_CYCLE = 16,
    parameter NUM_VARS_PER_CLAUSE = 3
) (
    input  wire [VAR_ID_BITS-1: 0] assign_var_id, // which clause IDs we are trying to look up
    input  wire assign_var_val, // 
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

            // if current_var_id == assign_var_id, check if literal becomes False
            // XOR the negation bit with assignment value:
            //   - If assigning True (0) to x: x is satisfied (0), ~x becomes False (1)
            //   - If assigning False (1) to x: x becomes False (1), ~x is satisfied (0)

            wire temp_bit = (current_var_id == assign_var_id) ? (assign_var_val) : 1'b0; // have we found var
            // wire temp_bit = (current_var_id == assign_var_id) ? (1'b1) : 1'b0; // have we found var
            // negate if current_neg_bit is 1 
            assign assign_var_TF_bitmask[i] = (current_neg_bit) ? ~temp_bit : temp_bit;
            // assign assign_var_TF_bitmask[i] = temp_bit;
        end
    endgenerate

    assign output_bitmask = assign_var_TF_bitmask;

endmodule