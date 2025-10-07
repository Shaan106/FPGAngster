module isUnsat_register (
    input wire current_clause_evaluation,
    input wire clk,
    input wire reset,
    output wire is_unsat
);
    /*
    The idea here is to keep memory of previous clause evaluations
    and see whether we are ever unsat.
    if we are ever unsat, we hold a high signal to show something was unsat
    */

    reg unsat_reg;

    always @(posedge clk) begin
        if (reset) begin
            unsat_reg <= 1'b0;
        end else begin
            unsat_reg <= unsat_reg | current_clause_evaluation;
        end
    end

    assign is_unsat = unsat_reg;

endmodule