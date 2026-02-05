module sat_node #(
    parameter NUM_ROWS = 32,
    parameter COLS_PER_ROW = 4,
    parameter NUM_VARS = 16,
    parameter LIT_WIDTH = 6,
    parameter INIT_FILE = "problem.hex"
) (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        start,
    
    output logic        done,
    output logic        result_sat, // 1=SAT, 0=UNSAT
    output logic [NUM_VARS:1] assigned,
    output logic [NUM_VARS:1] values,
    
    // Debug/Verification outputs
    output logic [31:0] cycle_count,
    output logic [2:0]  state_out
);

    import sat_pkg::*;

    logic       rst;
    assign rst = ~rst_n;

    state_t state;
    assign state_out = state;

    logic [$clog2(NUM_ROWS)-1:0] row_ptr;
    logic [$clog2(NUM_ROWS)-1:0] delayed_row_ptr;
    
    // Width needs to be large enough to hold NUM_VARS + 1
    logic [$clog2(NUM_VARS+2)-1:0] rebuild_ptr;
    logic [$clog2(NUM_VARS+1)-1:0] bt_var;
    logic                          bt_val;

    // --- Sub-modules ---

    // Static Memory (Async Read)
    logic [COLS_PER_ROW*LIT_WIDTH-1:0] static_row;
    static_memory #(NUM_ROWS, COLS_PER_ROW, LIT_WIDTH, INIT_FILE) static_mem (
        .clk(clk),
        .addr(row_ptr),
        .row_out(static_row)
    );

    // Dynamic Memory (Async Read)
    logic dyn_rst;
    logic dyn_we;
    logic [COLS_PER_ROW-1:0] dyn_wdata;
    logic [COLS_PER_ROW-1:0] dyn_rdata;
    
    always_ff @(posedge clk) begin 
        delayed_row_ptr <= row_ptr;
    end

    dynamic_memory #(NUM_ROWS, COLS_PER_ROW) dyn_mem (
        .clk(clk),
        .rst(dyn_rst | rst),
        .addr(row_ptr),
        .we(dyn_we),
        .wdata(dyn_wdata),
        .rdata(dyn_rdata)
    );

    // Heuristic Engine
    logic [NUM_VARS:1] h_assigned;
    logic [$clog2(NUM_VARS+1)-1:0] h_next_var;
    logic h_valid;
    
    heuristic_engine #(NUM_VARS, LIT_WIDTH) heuristic (
        .assigned(h_assigned),
        .next_var(h_next_var),
        .valid(h_valid)
    );
    
    // Assignment Manager
    logic am_assign;
    logic [$clog2(NUM_VARS+1)-1:0] am_var;
    logic am_val;
    logic am_forced;
    logic am_pop;
    
    logic [NUM_VARS:1] am_out_assigned;
    logic [NUM_VARS:1] am_out_values;
    logic [$clog2(NUM_VARS+1)-1:0] am_pop_var;
    logic am_pop_val;
    logic am_pop_forced;
    logic am_stack_empty;
    
    assign assigned = am_out_assigned;
    assign values   = am_out_values;
    assign h_assigned = am_out_assigned;
    
    assignment_manager #(NUM_VARS) am (
        .clk(clk),
        .rst(rst),
        .cmd_assign(am_assign),
        .assign_var(am_var),
        .assign_val(am_val),
        .assign_forced(am_forced),
        .cmd_pop(am_pop),
        .assigned(am_out_assigned),
        .values(am_out_values),
        .popped_var(am_pop_var),
        .popped_val(am_pop_val),
        .popped_forced(am_pop_forced),
        .stack_empty(am_stack_empty)
    );

    // Propagation Queue
    logic pq_rst;
    logic pq_push;
    logic [LIT_WIDTH-1:0] pq_din;
    logic pq_pop;
    logic [LIT_WIDTH-1:0] pq_dout;
    logic pq_empty;
    logic pq_full;
    
    propagation_queue #(NUM_VARS*2, LIT_WIDTH) pq (
        .clk(clk),
        .rst(pq_rst | rst),
        .push(pq_push),
        .din(pq_din),
        .pop(pq_pop),
        .dout(pq_dout),
        .empty(pq_empty),
        .full(pq_full)
    );

    // --- Combinational Logic ---
    
    logic [LIT_WIDTH-1:0] current_prop_literal;
    logic                 prop_lit_valid; 

    logic [COLS_PER_ROW-1:0] match_mask;
    comparator #(COLS_PER_ROW, LIT_WIDTH) comp (
        .static_row(static_row),
        .target_literal(current_prop_literal),
        .match_mask(match_mask)
    );
    
    assign dyn_wdata = dyn_rdata | match_mask;
    
    logic conflict_detected;
    clause_evaluator #(COLS_PER_ROW, LIT_WIDTH) evaluator (
        .static_row(static_row),
        .dynamic_row(dyn_wdata), 
        .conflict(conflict_detected)
    );
    
    logic [LIT_WIDTH-1:0] unit_forced_lit;
    logic unit_detected;
    unit_detector #(COLS_PER_ROW, LIT_WIDTH) u_det (
        .static_row(static_row),
        .dynamic_row(dyn_wdata), 
        .forced_literal(unit_forced_lit),
        .is_unit(unit_detected)
    );

    // --- Helpers ---
    function logic [LIT_WIDTH-1:0] make_lit(input int v, input logic val);
        return (val) ? ((v << 1) + 1) : (v << 1); 
    endfunction

    function logic [LIT_WIDTH-1:0] negate_lit(input logic [LIT_WIDTH-1:0] l);
        return l ^ 1;
    endfunction
    
    always_ff @(posedge clk) begin
        if (rst) cycle_count <= 0;
        else cycle_count <= cycle_count + 1;
    end

    // --- FSM ---
    
    typedef enum logic [2:0] {
        ST_IDLE, ST_DECIDE, ST_PROPAGATE, ST_BACKTRACK, ST_FLIP_DECISION, ST_REBUILD_QUEUE, ST_SAT, ST_UNSAT
    } internal_state_t;
    
    internal_state_t st;
    assign state = state_t'(st);

    logic pipeline_valid;
    logic queue_wait;

    always_ff @(posedge clk) begin
        if (rst) begin
            st <= ST_IDLE;
            row_ptr <= 0;
            current_prop_literal <= 0;
            prop_lit_valid <= 0;
            rebuild_ptr <= 1;
            done <= 0;
            result_sat <= 0;
            am_assign <= 0;
            am_pop <= 0;
            pq_push <= 0;
            pq_din <= 0;
            pq_pop <= 0;
            dyn_we <= 0;
            dyn_rst <= 0;
            pq_rst <= 0;
            pipeline_valid <= 0;
            queue_wait <= 0;
        end else begin
            am_assign <= 0;
            am_pop <= 0;
            pq_push <= 0;
            pq_pop <= 0;
            dyn_we <= 0;
            dyn_rst <= 0;
            pq_rst <= 0;
            
            case (st)
                ST_IDLE: begin
                    if (start) st <= ST_DECIDE;
                end
                
                ST_DECIDE: begin
                    if (h_valid) begin
                        am_assign <= 1;
                        am_var <= h_next_var;
                        am_val <= 0;
                        am_forced <= 0;
                        pq_push <= 1;
                        pq_din <= make_lit(h_next_var, 0);
                        st <= ST_PROPAGATE;
                        prop_lit_valid <= 0;
                        queue_wait <= 1; 
                    end else begin
                        st <= ST_SAT;
                    end
                end
                
                ST_PROPAGATE: begin
                    if (!prop_lit_valid) begin
                        if (queue_wait) begin
                            queue_wait <= 0;
                        end else if (pq_empty) begin
                            st <= ST_DECIDE;
                        end else begin
                            pq_pop <= 1;
                            current_prop_literal <= pq_dout;
                            prop_lit_valid <= 1;
                            row_ptr <= 0; 
                            pipeline_valid <= 0;
                        end
                    end else begin
                        if (!pipeline_valid) begin
                            if (conflict_detected) begin
                                st <= ST_BACKTRACK;
                                prop_lit_valid <= 0;
                            end else begin
                                dyn_we <= 1;
                                pipeline_valid <= 1;
                            end
                        end else begin
                            if (unit_detected) begin
                                logic [LIT_WIDTH-1:0] forced_L = unit_forced_lit;
                                logic [LIT_WIDTH-1:0] false_L = negate_lit(forced_L);
                                logic [$clog2(NUM_VARS+1)-1:0] u_var = forced_L >> 1;
                                logic u_val = forced_L[0];
                                if (!am_out_assigned[u_var]) begin
                                    am_assign <= 1;
                                    am_var <= u_var;
                                    am_val <= u_val;
                                    am_forced <= 1;
                                    pq_push <= 1;
                                    pq_din <= false_L;
                                end
                            end
                            
                            if (row_ptr == NUM_ROWS - 1) begin
                                prop_lit_valid <= 0;
                            end else begin
                                row_ptr <= row_ptr + 1;
                                pipeline_valid <= 0;
                            end
                        end
                    end
                end
                
                ST_BACKTRACK: begin
                    if (am_stack_empty) begin
                        st <= ST_UNSAT;
                    end else begin
                        if (am_pop_forced) begin
                            am_pop <= 1; 
                        end else begin
                            am_pop <= 1; 
                            bt_var <= am_pop_var;
                            bt_val <= am_pop_val; 
                            st <= ST_FLIP_DECISION;
                        end
                    end
                end
                
                ST_FLIP_DECISION: begin
                    am_assign <= 1;
                    am_var <= bt_var;
                    am_val <= ~bt_val; 
                    am_forced <= 1;    
                    dyn_rst <= 1; 
                    pq_rst <= 1;
                    rebuild_ptr <= 1;
                    st <= ST_REBUILD_QUEUE;
                end
                
                ST_REBUILD_QUEUE: begin
                    if (rebuild_ptr > NUM_VARS) begin
                        st <= ST_PROPAGATE;
                        prop_lit_valid <= 0;
                        queue_wait <= 1;
                    end else begin
                        if (am_out_assigned[rebuild_ptr]) begin
                            pq_push <= 1;
                            pq_din <= make_lit(rebuild_ptr, am_out_values[rebuild_ptr]);
                        end
                        rebuild_ptr <= rebuild_ptr + 1;
                    end
                end
                
                ST_SAT: begin
                    done <= 1;
                    result_sat <= 1;
                end
                
                ST_UNSAT: begin
                    done <= 1;
                    result_sat <= 0;
                end
            endcase
        end
    end

endmodule
