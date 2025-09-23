module static_memory_tb;

    parameter NUM_CLAUSES = 64;
    parameter VAR_ID_BITS = 8;
    parameter NUM_CLAUSES_PER_CYCLE = 16;
    parameter NUM_VARS_PER_CLAUSE = 3;

    reg [VAR_ID_BITS-1:0] symbolic_var_id;
    reg clk;
    wire [((VAR_ID_BITS + 1)*NUM_VARS_PER_CLAUSE)*NUM_CLAUSES_PER_CYCLE-1:0] output_memory_slice;

    static_memory #(
        .NUM_CLAUSES(NUM_CLAUSES),
        .VAR_ID_BITS(VAR_ID_BITS),
        .NUM_CLAUSES_PER_CYCLE(NUM_CLAUSES_PER_CYCLE),
        .NUM_VARS_PER_CLAUSE(NUM_VARS_PER_CLAUSE)
    ) dut (
        .symbolic_var_id(symbolic_var_id),
        .clk(clk),
        .output_memory_slice(output_memory_slice)
    );

    // Clock
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Test
    initial begin
        symbolic_var_id = 0;

        // Wait for initialization
        #1;

        $display("Row | Output");
        $display("----|-------");

        // Show 8 clock cycles
        repeat (8) begin
            $display(" %0d  | %h", dut.row_ptr, output_memory_slice);
            @(posedge clk);
            #1; // Let output settle
        end

        $finish;
    end

endmodule