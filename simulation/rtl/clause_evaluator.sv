module clause_evaluator #(
    parameter COLS_PER_ROW = 4,
    parameter LIT_WIDTH = 6
) (
    input  logic [COLS_PER_ROW*LIT_WIDTH-1:0] static_row,
    input  logic [COLS_PER_ROW-1:0]           dynamic_row,
    output logic                              conflict
);

    logic [COLS_PER_ROW-1:0] active_mask;
    logic [COLS_PER_ROW-1:0] term;
    logic                    has_active_lits;

    always_comb begin
        for (int i = 0; i < COLS_PER_ROW; i++) begin
            logic [LIT_WIDTH-1:0] lit;
            lit = static_row[i*LIT_WIDTH +: LIT_WIDTH];
            active_mask[i] = (lit != 0);
            term[i] = dynamic_row[i] | (~active_mask[i]);
        end
        has_active_lits = |active_mask;
        conflict = (&term) && has_active_lits;
    end

endmodule