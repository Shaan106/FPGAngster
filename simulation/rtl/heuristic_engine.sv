module heuristic_engine #(
    parameter NUM_VARS = 16,
    parameter LIT_WIDTH = 6
) (
    input  logic [NUM_VARS:1]            assigned, 
    output logic [$clog2(NUM_VARS+1)-1:0] next_var,
    output logic                         valid
);

    // Using a simpler loop style that iverilog handles better for priority encoding
    always @* begin
        integer i;
        next_var = 0;
        valid = 0;
        for (i = 1; i <= 16; i = i + 1) begin
            if (i <= NUM_VARS) begin
                if (assigned[i] == 1'b0 && valid == 1'b0) begin
                    next_var = i[$clog2(NUM_VARS+1)-1:0];
                    valid = 1'b1;
                end
            end
        end
    end

endmodule
