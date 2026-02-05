module propagation_queue #(
    parameter QUEUE_DEPTH = 32,
    parameter LIT_WIDTH = 6
) (
    input  logic                 clk,
    input  logic                 rst, // Clear queue
    input  logic                 push,
    input  logic [LIT_WIDTH-1:0] din,
    input  logic                 pop,
    output logic [LIT_WIDTH-1:0] dout,
    output logic                 empty,
    output logic                 full
);

    logic [LIT_WIDTH-1:0] mem [0:QUEUE_DEPTH-1];
    logic [$clog2(QUEUE_DEPTH)-1:0] head;
    logic [$clog2(QUEUE_DEPTH)-1:0] tail;
    logic [$clog2(QUEUE_DEPTH):0]   count;

    assign empty = (count == 0);
    assign full  = (count == QUEUE_DEPTH);
    assign dout  = mem[head];

    always_ff @(posedge clk) begin
        if (rst) begin
            head <= 0;
            tail <= 0;
            count <= 0;
        end else begin
            if (push && !full) begin
                mem[tail] <= din;
                tail <= (tail == QUEUE_DEPTH-1) ? 0 : tail + 1;
                if (!pop) count <= count + 1;
            end
            
            if (pop && !empty) begin
                head <= (head == QUEUE_DEPTH-1) ? 0 : head + 1;
                if (!push) count <= count - 1;
            end
            
            if (push && pop && !empty && !full) begin
                // Count stays same
            end
        end
    end

endmodule
