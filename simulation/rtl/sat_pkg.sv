package sat_pkg;
    // Default Parameters (can be overridden in modules, but good for types)
    localparam NUM_ROWS = 32;
    localparam COLS_PER_ROW = 4;
    localparam NUM_VARS = 16;
    
    // Literal Width: 1 bit for sign + bits for var ID
    // var_id ranges from 1 to NUM_VARS. 2*NUM_VARS + 1 is max literal.
    localparam LIT_WIDTH = $clog2(2 * NUM_VARS + 2); 

    typedef logic [LIT_WIDTH-1:0] literal_t;
    typedef logic [COLS_PER_ROW-1:0][LIT_WIDTH-1:0] row_t;
    typedef logic [COLS_PER_ROW-1:0] row_mask_t;

    // FSM States
    typedef enum logic [2:0] {
        IDLE,
        DECIDE,
        PROPAGATE,
        BACKTRACK,
        SAT,
        UNSAT
    } state_t;

endpackage
