module static_memory #(
    parameter NUM_CLAUSES = 64,
    parameter VAR_ID_BITS = 8,
    parameter NUM_CLAUSES_PER_CYCLE = 16,
    parameter NUM_VARS_PER_CLAUSE = 3
) (
    input  wire clk, // clk - used forwhich "slice" of memory we are currently looking at
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

    // pointer to current row in memory
    localparam PTR_BITS = $clog2(NUM_ROWS);
    reg [PTR_BITS-1:0] row_ptr;

    always @(posedge clk) begin
        row_ptr <= row_ptr + 1;
    end

    // output current memory slice
    assign output_memory_slice = memory[row_ptr];

    // initialize memory with data
    initial begin
        // Initialize row pointer
        row_ptr = 0;

        // Initialize memory array - add your data here
        // Format: memory[row] = {clause15, clause14, ..., clause1, clause0};
        // Each clause: {var2_id, var2_neg, var1_id, var1_neg, var0_id, var0_neg}

        // Example initialization (modify as needed):
        memory[0] = 0;  // Row 0 data
        memory[1] = 432'h123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF;  // Row 1 test pattern
        memory[2] = 432'hFEDCBA0987654321FEDCBA0987654321FEDCBA0987654321FEDCBA0987654321;  // Row 2 test pattern
        memory[3] = 432'h555555555555555555555555555555555555555555555555555555555555555;  // Row 3 alternating pattern
    end

endmodule