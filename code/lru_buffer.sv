module lru_buffer #(
    parameter WAYS = 4,
    parameter TOTAL_SIZE = 16
) (
    input logic clk, rst, re, we,
    input logic [$clog2(WAYS)-1:0] way,
    input logic [$clog2(TOTAL_SIZE/WAYS)-1:0] index,
    output logic [$clog2(WAYS)-1:0] replace_way
);
    
    // memory array of pointers to the last used way
    // each index has its own LRU buffer
    // leftmost entry is the last used, rightmost is most recently used
    // each slot keeps track of the way currently in it
    logic [$clog2(WAYS)-1:0] last_used [$clog2(WAYS)-1:0][0:$clog2(TOTAL_SIZE/WAYS)-1];

    // signal to store the address of the way we're currently using in the LRU buffer
    logic [$clog2(WAYS)-1:0] current_way_addr;

    // finding the address of the way to replace
    always_comb begin
        for (int i = 0; i < WAYS; i++) begin
            if (last_used[i][index] == way) begin
                current_way_addr = last_used[i][index];
            end
        end
    end

    // last used way is always the first entry
    assign replace_way = last_used[0][index];

    /* UPDATE LAST USED SLOT */
    // on every re/we cycle, we update the last used slots
    // now that we know which of the slots has the way we want to use (current_way_addr),
    // we can put it in the most recently used way slot (at the end)
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            // reset with all slots incrementing from 0 to WAYS-1
            for (int i = 0; i < WAYS; i++) begin
                for (int j = 0; j < TOTAL_SIZE/WAYS; j++) begin
                    last_used[i][j] <= i;
                end
            end
        end else (re or we) begin
            // the slots before the slot for the current way shouldn't shift
            for (int i = current_way_addr; i < WAYS-1; i++) begin
                last_used[i][index] <= last_used[i+1][index];
            end
            // put the current way in the last slot
            last_used[WAYS-1][index] <= last_used[current_way_addr][index];
        end
    end

endmodule