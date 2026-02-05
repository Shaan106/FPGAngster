module tb_sat_node;

    // Parameters with defaults, overridable by compiler flags
    `ifdef NUM_ROWS
        localparam NUM_ROWS = `NUM_ROWS;
    `else
        localparam NUM_ROWS = 32;
    `endif

    `ifdef COLS_PER_ROW
        localparam COLS_PER_ROW = `COLS_PER_ROW;
    `else
        localparam COLS_PER_ROW = 4;
    `endif

    `ifdef NUM_VARS
        localparam NUM_VARS = `NUM_VARS;
    `else
        localparam NUM_VARS = 16;
    `endif

    `ifdef LIT_WIDTH
        localparam LIT_WIDTH = `LIT_WIDTH;
    `else
        localparam LIT_WIDTH = 6;
    `endif

    `ifdef INIT_FILE
        localparam string INIT_FILE = `INIT_FILE;
    `else
        localparam string INIT_FILE = "problem.hex";
    `endif

    // Signals
    logic clk;
    logic rst_n;
    logic start;
    logic done;
    logic result_sat;
    logic [NUM_VARS:1] assigned;
    logic [NUM_VARS:1] values;
    logic [31:0] cycle_count;
    logic [2:0] state_out;

    // Instantiate DUT
    sat_node #(
        .NUM_ROWS(NUM_ROWS),
        .COLS_PER_ROW(COLS_PER_ROW),
        .NUM_VARS(NUM_VARS),
        .LIT_WIDTH(LIT_WIDTH),
        .INIT_FILE(INIT_FILE)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .done(done),
        .result_sat(result_sat),
        .assigned(assigned),
        .values(values),
        .cycle_count(cycle_count),
        .state_out(state_out)
    );

    // Clock Generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Test Sequence
    initial begin
        `ifdef VCD_FILE
            $dumpfile(`VCD_FILE);
            $dumpvars(0, tb_sat_node);
        `endif

        // Initialize
        rst_n = 0;
        start = 0;
        
        // Reset Pulse
        #20;
        rst_n = 1;
        #10;
        
        // Start
        start = 1;
        #10;
        start = 0;
        
        // Wait for completion
        wait(done);
        #20;
        
        // Structured Output for Parsing
        $display("RESULT: %s", result_sat ? "SAT" : "UNSAT");
        $display("CYCLES: %d", cycle_count);
        
        if (result_sat) begin
            $write("ASSIGNMENTS: ");
            for (int i = 1; i <= NUM_VARS; i++) begin
                $write("%b", values[i]);
            end
            $display(""); // Newline
        end
            
        $finish;
    end
    
    // Timeout
    initial begin
        #100000; // Increased timeout
        $display("RESULT: TIMEOUT");
        $finish;
    end

endmodule