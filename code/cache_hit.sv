module cache_hit #(
    parameter WAYS = 4,
    parameter TOTAL_SIZE = 16,
    parameter RAM_DEPTH = 256,
    parameter WIDTH = 8
) (
    input  logic [$clog2(RAM_DEPTH)-1-$clog2(TOTAL_SIZE/WAYS):0] target_tag,
    input  logic [$clog2(RAM_DEPTH)-1-$clog2(TOTAL_SIZE/WAYS):0] tags [0:WAYS-1],
    input  logic valid_bits [0:WAYS-1],
    input  logic [$clog2(WAYS)-1:0] lru_way,
    output logic hit,
    output logic [$clog2(WAYS)-1:0] chosen_way
);

    // so first determine whether hit or miss using valid bits and tags (diagram logic)
    // if hit, then we can use the way to access the data
    // if miss, use LRU to determine which way to replace
    always_comb begin

        // default is miss
        hit = 0;
        chosen_way = 0;

        // check each tag/valid bit for a hit
        for (int i = 0; i < WAYS; i++) begin
            if (valid_bits[i] && (tags[i] == target_tag)) begin
                hit = 1;
                chosen_way = i;
            end
        end

        // if miss, use LRU way
        if (!hit) begin
            chosen_way = lru_way;
        end
    end

endmodule