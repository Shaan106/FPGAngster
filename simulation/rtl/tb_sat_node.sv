module tb_sat_node;

    // Parameters
    localparam NUM_ROWS = 3; // From test case
    localparam COLS_PER_ROW = 4;
    localparam NUM_VARS = 3;
    localparam LIT_WIDTH = 6;
    localparam INIT_FILE = "rtl/problem.hex"; // In current dir when running simulation

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
        // Dump waves
        $dumpfile("sat_node.vcd");
        $dumpvars(0, tb_sat_node);

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
        
        $display("Simulation Done at Cycle: %d", cycle_count);
        $display("Result: %s", result_sat ? "SAT" : "UNSAT");
        
        if (result_sat) begin
            $display("Assignments (v1..v3): %b %b %b", values[1], values[2], values[3]);
        end
        
        if (result_sat === 1'b1) 
            $display("TEST PASSED");
        else 
            $display("TEST FAILED");
            
        $finish;
    end
    
    // Timeout
    initial begin
        #10000;
        $display("TIMEOUT");
        $finish;
    end

endmodule
