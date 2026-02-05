module heuristic_engine #(
    parameter NUM_VARS = 16,
    parameter LIT_WIDTH = 6
) (
    input  logic [NUM_VARS:1]            assigned, 
    output logic [$clog2(NUM_VARS+1)-1:0] next_var,
    output logic                         valid
);

    always_comb begin
        next_var = 0;
        valid = 0;
        for (integer i = 1; i <= NUM_VARS; i = i + 1) begin
            if (valid == 1'b0) begin
                if (assigned[i] == 1'b0) begin
                    next_var = i[$clog2(NUM_VARS+1)-1:0];
                    valid = 1'b1;
                end
            end
        end
    end

endmodule