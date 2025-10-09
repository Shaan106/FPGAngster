module static_memory_tb;

    parameter NUM_CLAUSES = 64;
    parameter VAR_ID_BITS = 8;
    parameter NUM_CLAUSES_PER_CYCLE = 16;
    parameter NUM_VARS_PER_CLAUSE = 3;
    parameter NUM_ROWS = NUM_CLAUSES / NUM_CLAUSES_PER_CYCLE;
    parameter PTR_BITS = $clog2(NUM_ROWS);

    reg clk;
    reg reset;
    wire [PTR_BITS-1:0] row_ptr;
    wire [((VAR_ID_BITS + 1)*NUM_VARS_PER_CLAUSE)*NUM_CLAUSES_PER_CYCLE-1:0] output_memory_slice;

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
    ) dut (
        .row_ptr(row_ptr),
        .output_memory_slice(output_memory_slice)
    );

    // Clock
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Test
    initial begin
        reset = 1;

        // Wait for initialization and release reset
        @(posedge clk);
        #1;
        reset = 0;

        // Wait a cycle for reset to take effect
        @(posedge clk);
        #1;

        $display("Row | Output");
        $display("----|-------");

        // Show 8 clock cycles
        repeat (8) begin
            $display(" %0d  | %h", row_ptr, output_memory_slice);
            @(posedge clk);
            #1; // Let output settle
        end

        $display("");
        $display("Test completed!");
        $finish;
    end

endmodule