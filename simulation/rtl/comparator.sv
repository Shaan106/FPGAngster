module comparator #(
    parameter COLS_PER_ROW = 4,
    parameter LIT_WIDTH = 6
) (
    input  logic [COLS_PER_ROW*LIT_WIDTH-1:0] static_row,
    input  logic [LIT_WIDTH-1:0]              target_literal,
    output logic [COLS_PER_ROW-1:0]           match_mask
);

    always_comb begin
        for (int i = 0; i < COLS_PER_ROW; i++) begin
            logic [LIT_WIDTH-1:0] lit;
            lit = static_row[i*LIT_WIDTH +: LIT_WIDTH];
            if (lit == target_literal && lit != 0) begin
                match_mask[i] = 1'b1;
            end else begin
                match_mask[i] = 1'b0;
            end
        end
    end

endmodule