module static_memory #(
    parameter NUM_CLAUSES = 64,
    parameter VAR_ID_BITS = 8,
    parameter NUM_CLAUSES_PER_CYCLE = 16,
    parameter NUM_VARS_PER_CLAUSE = 3,
    parameter PTR_BITS = $clog2(NUM_CLAUSES / NUM_CLAUSES_PER_CYCLE)
) (
    input  wire [PTR_BITS-1:0] row_ptr,
    output wire [((VAR_ID_BITS + 1)*NUM_VARS_PER_CLAUSE)*NUM_CLAUSES_PER_CYCLE-1:0] output_memory_slice
);

    // [var_id, neg] per var
    // 3 vars per clause
    // 16 clauses "per cycle"

    // create storage
    // "2D" array
    // each row is of size ((VAR_ID_BITS + 1)*NUM_VARS_PER_CLAUSE)*NUM_CLAUSES_PER_CYCLE-1:0
    localparam ROW_WIDTH = ((VAR_ID_BITS + 1)*NUM_VARS_PER_CLAUSE)*NUM_CLAUSES_PER_CYCLE;
    localparam NUM_ROWS = NUM_CLAUSES / NUM_CLAUSES_PER_CYCLE;

    reg [ROW_WIDTH-1:0] memory [NUM_ROWS-1:0];

    // output current memory slice
    assign output_memory_slice = memory[row_ptr];

    // initialize memory with data
    initial begin

        // Initialize memory array - add your data here
        // Format: memory[row] = {clause15, clause14, ..., clause1, clause0};
        // Each clause: {var2_id[7:0], var2_neg, var1_id[7:0], var1_neg, var0_id[7:0], var0_neg}
        // neg=0 means positive literal, neg=1 means negated literal
        // Variables are numbered starting from 1 (x1, x2, x3, x4, x5)

        // 16 clause 3-SAT problem from test_case.md
        // All clauses fit in row 0 (16 clauses per cycle)
        memory[0] = {
            // Clause 15: and all x0 | x1 | x2
            1'b0, 8'd0, 1'b0, 8'd1, 1'b0, 8'd2, 
            // Clause 14: 
            1'b0, 8'd0, 1'b0, 8'd1, 1'b0, 8'd2, 
            // Clause 13:
            1'b0, 8'd0, 1'b0, 8'd1, 1'b0, 8'd2, 
            // Clause 12:
            1'b0, 8'd0, 1'b0, 8'd1, 1'b0, 8'd2, 
            // Clause 11:
            1'b0, 8'd0, 1'b0, 8'd1, 1'b0, 8'd2, 
            // Clause 10:
            1'b0, 8'd0, 1'b0, 8'd1, 1'b0, 8'd2, 
            // Clause 9:
            1'b0, 8'd0, 1'b0, 8'd1, 1'b0, 8'd2, 
            // Clause 8:
            1'b0, 8'd0, 1'b0, 8'd1, 1'b0, 8'd2, 
            // Clause 7:
            1'b0, 8'd0, 1'b0, 8'd1, 1'b0, 8'd2, 
            // Clause 6:
            1'b0, 8'd0, 1'b0, 8'd1, 1'b0, 8'd2, 
            // Clause 5:
            1'b0, 8'd0, 1'b0, 8'd1, 1'b0, 8'd2, 
            // Clause 4:
            1'b0, 8'd0, 1'b0, 8'd1, 1'b0, 8'd2, 
            // Clause 3:
            1'b0, 8'd0, 1'b0, 8'd1, 1'b0, 8'd2, 
            // Clause 2:
            1'b0, 8'd0, 1'b0, 8'd1, 1'b0, 8'd2, 
            // Clause 1:
            1'b0, 8'd0, 1'b0, 8'd1, 1'b0, 8'd2, 
            // Clause 0:
            1'b0, 8'd0, 1'b0, 8'd1, 1'b0, 8'd2  
            
        };


    end

endmodule