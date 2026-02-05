module assignment_manager #(
    parameter NUM_VARS = 16
) (
    input  logic        clk,
    input  logic        rst,
    
    // Commands
    input  logic        cmd_assign,
    input  logic [$clog2(NUM_VARS+1)-1:0] assign_var,
    input  logic        assign_val,
    input  logic        assign_forced,
    
    input  logic        cmd_pop,
    
    // Outputs
    output logic [NUM_VARS:1] assigned, // 1 if assigned
    output logic [NUM_VARS:1] values,   // Value if assigned
    
    output logic [$clog2(NUM_VARS+1)-1:0] popped_var,
    output logic                          popped_val,
    output logic                          popped_forced,
    output logic                          stack_empty
);

    // Stack Memory
    // Entry: {var, val, forced}
    localparam ENTRY_WIDTH = $clog2(NUM_VARS+1) + 1 + 1;
    
    logic [ENTRY_WIDTH-1:0] stack [0:NUM_VARS-1];
    logic [$clog2(NUM_VARS+1):0] stack_ptr; // Points to next free slot

    assign stack_empty = (stack_ptr == 0);

    // Read top of stack (for pop output, valid only if !empty)
    // Actually, pop usually implies "read and decrement".
    // Since we need the data *after* pop command in the next cycle (or same?),
    // let's output the data at (stack_ptr - 1).
    logic [ENTRY_WIDTH-1:0] top_data;
    assign top_data = (stack_ptr > 0) ? stack[stack_ptr - 1] : 0;
    
    assign popped_var    = top_data[ENTRY_WIDTH-1 : 2];
    assign popped_val    = top_data[1];
    assign popped_forced = top_data[0];

    // State Update
    always_ff @(posedge clk) begin
        if (rst) begin
            stack_ptr <= 0;
            assigned <= 0;
            values <= 0;
        end else begin
            if (cmd_assign) begin
                // Update Table
                assigned[assign_var] <= 1'b1;
                values[assign_var]   <= assign_val;
                
                // Push to Stack
                stack[stack_ptr] <= {assign_var, assign_val, assign_forced};
                stack_ptr <= stack_ptr + 1;
            end else if (cmd_pop) begin
                if (stack_ptr > 0) begin
                    // Remove from Table using the data we are about to pop
                    assigned[popped_var] <= 1'b0;
                    
                    // Decrement Stack
                    stack_ptr <= stack_ptr - 1;
                end
            end
        end
    end

endmodule
