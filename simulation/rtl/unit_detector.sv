module unit_detector #(
    parameter COLS_PER_ROW = 4,
    parameter LIT_WIDTH = 6
) (
    input  logic [COLS_PER_ROW*LIT_WIDTH-1:0] static_row,
    input  logic [COLS_PER_ROW-1:0]           dynamic_row,
    output logic [LIT_WIDTH-1:0]              forced_literal,
    output logic                              is_unit
);

    logic [COLS_PER_ROW-1:0] is_candidate;
    logic [$clog2(COLS_PER_ROW+1)-1:0] count;
    
    always_comb begin
        count = 0;
        forced_literal = 0;
        
        for (int i = 0; i < COLS_PER_ROW; i++) begin
            logic [LIT_WIDTH-1:0] lit;
            lit = static_row[i*LIT_WIDTH +: LIT_WIDTH];
            is_candidate[i] = (lit != 0) && (dynamic_row[i] == 0);
            
            if (is_candidate[i]) begin
                count = count + 1;
                forced_literal = lit;
            end
        end
        
        is_unit = (count == 1);
        if (!is_unit) forced_literal = 0;
    end

endmodule