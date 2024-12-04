module cache_lru #(
    parameter WAYS = 4,
    parameter TOTAL_SIZE = 16
) (
    input logic clk, rst, re, we, update,
    input logic [$clog2(WAYS)-1:0] way,
    input logic [$clog2(TOTAL_SIZE/WAYS)-1:0] index,
    output logic [$clog2(WAYS)-1:0] replace_way
);
    
    // memory array of pointers to the last used way
    // each index has its own LRU buffer
    // leftmost entry is the last used, rightmost is most recently used
    // each slot keeps track of the way currently in it
    logic [$clog2(WAYS)-1:0] last_used [0:WAYS][0:(TOTAL_SIZE/WAYS)-1];
    logic [$clog2(WAYS)-1:0] replace_way_r;

    // signal to store the address of the way we're currently using in the LRU buffer
    logic [$clog2(WAYS)-1:0] current_way_addr;

    // finding the address of the way to replace
    always_comb begin
        current_way_addr = 0;
        for (int i = 0; i < WAYS; i++) begin
            if (last_used[i][index] == way) begin
                current_way_addr = i;
            end
        end
    end

    // last used way is always the first entry
    assign replace_way = last_used[0][index];
    // assign replace_way = replace_way_r;
    // always_ff @(posedge clk or posedge rst) begin
    //     if (rst) begin
    //         replace_way_r <= 0;
    //     end else begin
    //         replace_way_r <= last_used[0][index];
    //     end
    // end

    /* UPDATE LAST USED SLOT */
    // on every update, we update the last used slots
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
        end else if (update) begin
            // the slots before the slot for the current way shouldn't shift
            for (int i = 0; i < WAYS-1; i++) begin
                // need to have this if condition because can't set
                // i = current_way_addr at compile time
                if (i >= current_way_addr) begin
                    last_used[i][index] <= last_used[i+1][index];
                end
            end
            // put the current way in the last slot
            last_used[WAYS-1][index] <= last_used[current_way_addr][index];
        end
    end

endmodule