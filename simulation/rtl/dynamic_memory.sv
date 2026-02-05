module dynamic_memory #(
    parameter NUM_ROWS = 32,
    parameter COLS_PER_ROW = 4
) (
    input  logic                        clk,
    input  logic                        rst,
    input  logic [$clog2(NUM_ROWS)-1:0] addr,
    input  logic                        we,
    input  logic [COLS_PER_ROW-1:0]     wdata,
    output logic [COLS_PER_ROW-1:0]     rdata
);

    logic [COLS_PER_ROW-1:0] memory [0:NUM_ROWS-1];

    // Async Read with reset override
    assign rdata = rst ? {COLS_PER_ROW{1'b0}} : memory[addr];

    always_ff @(posedge clk) begin
        if (rst) begin
            for (int i = 0; i < NUM_ROWS; i++) begin
                memory[i] <= {COLS_PER_ROW{1'b0}};
            end
        end else if (we) begin
            memory[addr] <= wdata;
        end
    end

endmodule