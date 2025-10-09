module row_ptr_counter #(
    parameter NUM_ROWS = 4,
    parameter PTR_BITS = $clog2(NUM_ROWS)
) (
    input  wire clk,
    input  wire reset,
    output wire [PTR_BITS-1:0] row_ptr
);

    reg [PTR_BITS-1:0] row_ptr_reg;

    always @(posedge clk) begin
        if (reset) begin
            row_ptr_reg <= 0;
        end else begin
            row_ptr_reg <= row_ptr_reg + 1;
        end
    end

    assign row_ptr = row_ptr_reg;

endmodule