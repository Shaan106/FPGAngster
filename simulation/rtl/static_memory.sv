module static_memory #(
    parameter NUM_ROWS = 32,
    parameter COLS_PER_ROW = 4,
    parameter LIT_WIDTH = 6,
    parameter INIT_FILE = "problem.hex"
) (
    input  logic                               clk, // clk not used for async read
    input  logic [$clog2(NUM_ROWS)-1:0]        addr,
    output logic [COLS_PER_ROW*LIT_WIDTH-1:0]  row_out
);

    logic [COLS_PER_ROW*LIT_WIDTH-1:0] memory [0:NUM_ROWS-1];

    initial begin
        for (int i = 0; i < NUM_ROWS; i++) memory[i] = 0;
        if (INIT_FILE != "") begin
            $readmemh(INIT_FILE, memory);
            $display("[RTL] StaticMemory loaded from %s. Row 0: %h", INIT_FILE, memory[0]);
        end
    end

    // Async Read
    assign row_out = memory[addr];

endmodule
