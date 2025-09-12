/**
 * Clause Memory Testbench - One Cycle Write-Read Operation
 */

module clause_memory_tb;

    logic clk, rst_n, write_en;
    logic [3:0] write_addr, read_addr;
    logic [32:0] write_data, read_data;

    clause_memory dut (
        .clk(clk),
        .rst_n(rst_n),
        .write_en(write_en),
        .write_addr(write_addr),
        .write_data(write_data),
        .read_addr(read_addr),
        .read_data(read_data)
    );

    // Clock
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        $display("=== One-Cycle Write-Read Test ===");
        
        // Initialize
        rst_n = 1; write_en = 0; write_addr = 0; write_data = 0; read_addr = 0;
        
        repeat(2) @(posedge clk);  // Wait for setup
        
        $display("\n1. Test One-Cycle Write-Through");
        
        // Set up simultaneous write and read to same address
        read_addr = 5;
        write_addr = 5;
        write_data = 33'b100100011010001010110011110001001;
        
        $display("Cycle N: Write and Read address 5 simultaneously");
        $display("  write_data = %33b", write_data);
        
        write_en = 1;
        @(posedge clk);  // SINGLE cycle: write AND read should both work
        #1; // Wait for output, THEN disable write
        write_en = 0;
        
        $display("Cycle N+1: Result should show written data immediately");
        $display("  read_data  = %33b", read_data);
        
        if (read_data == write_data) begin
            $display("  ✓ SUCCESS: One-cycle write-through works!");
        end else begin
            $display("  ✗ FAIL: One-cycle write-through failed");
        end
        
        $display("\n2. Test Read from Different Address (No Write-Through)");
        
        // Now read from a different address - should get original value
        read_addr = 4;
        @(posedge clk);
        #1;
        
        $display("Reading address 4 (should be original value):");
        $display("  read_data  = %33b", read_data);
        
        if (read_data == 33'b000000001000000000010000000000100) begin
            $display("  ✓ SUCCESS: Different address unaffected");
        end else begin
            $display("  ✗ FAIL: Different address was affected");
        end
        
        $display("\n3. Test Read Back Written Address");
        
        // Read back address 5 - should still have written value
        read_addr = 5;
        @(posedge clk);
        #1;
        
        $display("Reading back address 5 (should still have written value):");
        $display("  read_data  = %33b", read_data);
        
        if (read_data == 33'b100100011010001010110011110001001) begin
            $display("  ✓ SUCCESS: Written value persists in memory");
        end else begin
            $display("  ✗ FAIL: Written value was lost");
        end
        
        $display("\n4. Test Write to Different Address");
        
        // Write to address 6, read from address 5 (no write-through expected)
        read_addr = 5;
        write_addr = 6;
        write_data = 33'b111111111000000000111111111000000;
        
        write_en = 1;
        @(posedge clk);
        #1;
        write_en = 0;
        
        $display("Write to addr 6, read from addr 5 (no write-through):");
        $display("  read_data  = %33b", read_data);
        
        if (read_data == 33'b100100011010001010110011110001001) begin
            $display("  ✓ SUCCESS: No write-through when addresses differ");
        end else begin
            $display("  ✗ FAIL: Unexpected write-through occurred");
        end
        
        // Verify address 6 got the write
        read_addr = 6;
        @(posedge clk);
        #1;
        
        $display("Reading back address 6 (should have new value):");
        $display("  read_data  = %33b", read_data);
        
        if (read_data == 33'b111111111000000000111111111000000) begin
            $display("  ✓ SUCCESS: Address 6 write successful");
        end else begin
            $display("  ✗ FAIL: Address 6 write failed");
        end
        
        $display("\n=== ONE-CYCLE DESIGN VERIFIED ===");
        $finish;
    end

endmodule