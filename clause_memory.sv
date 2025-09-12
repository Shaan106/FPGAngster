/**
 * Clause Memory Module
 * 
 * Stores clauses for the SAT solver node. Each clause contains 3 terms,
 * where each term has a variable identifier, value assignment, and negation flag.
 * 
 * Memory organization per clause:
 * - Term 0: [32:25] var_id, [24:23] value, [22] negation
 * - Term 1: [21:14] var_id, [13:12] value, [11] negation  
 * - Term 2: [10:3] var_id, [2:1] value, [0] negation
 * 
 * Value encoding: 2'b00=False, 2'b01=True, 2'b10=Unknown, 2'b11=Reserved
 */

module clause_memory #(
    parameter NUM_CLAUSES = 16,
    parameter TERMS_PER_CLAUSE = 3,
    parameter VAR_ID_WIDTH = 8,
    parameter VALUE_WIDTH = 2,
    parameter CLAUSE_WIDTH = TERMS_PER_CLAUSE * (VAR_ID_WIDTH + VALUE_WIDTH + 1)
)(
    input  logic clk,
    input  logic rst_n,
    
    // Write interface
    input  logic                            write_en,
    input  logic [$clog2(NUM_CLAUSES)-1:0] write_addr, // ie 16 write addresses,
    input  logic [CLAUSE_WIDTH-1:0]        write_data, // 3 terms * (8 id + 2 value + 1 neg) = 33 bits
    
    // Read interface
    input  logic [$clog2(NUM_CLAUSES)-1:0] read_addr, // ie 16 read addresses
    output logic [CLAUSE_WIDTH-1:0]        read_data  // 3 terms * (8 id + 2 value + 1 neg) = 33 bits
);

    // Memory array to store clauses
    logic [CLAUSE_WIDTH-1:0] memory [NUM_CLAUSES-1:0];
    
    // Initialize memory with a test 3-SAT problem
    // Problem: (A v ~B v C) ^ (~A v B v ~D) ^ (B v C v D) ^ (~A v ~C v D)
    // Clause format: [var_id, value, negation] for each of 3 terms per clause
    initial begin
        // Clause 0: (A v ~B v C) = [(0,10,0), (1,10,1), (2,10,0)]
        memory[0] = {8'd0, 2'b10, 1'b0, 8'd1, 2'b10, 1'b1, 8'd2, 2'b10, 1'b0};
        
        // Clause 1: (~A v B v ~D) = [(0,10,1), (1,10,0), (3,10,1)]  
        memory[1] = {8'd0, 2'b10, 1'b1, 8'd1, 2'b10, 1'b0, 8'd3, 2'b10, 1'b1};
        
        // Clause 2: (B v C v D) = [(1,10,0), (2,10,0), (3,10,0)]
        memory[2] = {8'd1, 2'b10, 1'b0, 8'd2, 2'b10, 1'b0, 8'd3, 2'b10, 1'b0};
        
        // Clause 3: (~A v ~C v D) = [(0,10,1), (2,10,1), (3,10,0)]
        memory[3] = {8'd0, 2'b10, 1'b1, 8'd2, 2'b10, 1'b1, 8'd3, 2'b10, 1'b0};
        
        // Initialize remaining clauses to all unknowns
        for (int i = 4; i < NUM_CLAUSES; i++) begin
            memory[i] = {8'd0, 2'b10, 1'b0, 8'd0, 2'b10, 1'b0, 8'd0, 2'b10, 1'b0};
        end
    end
    
    // Write operations (synchronous with write-through)
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            read_data <= 0;
        end else begin
            // Full clause write
            if (write_en) begin
                memory[write_addr] <= write_data;
            end
            
            // Read with write-through: if writing to the address we're reading, use write data
            if (write_en && (write_addr == read_addr)) begin
                read_data <= write_data;  // Write-through: bypass memory, use new data
            end else begin
                read_data <= memory[read_addr];  // Normal read from memory
            end
        end
    end

endmodule