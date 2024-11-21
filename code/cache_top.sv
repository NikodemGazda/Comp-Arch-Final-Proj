module cache_top #(
    parameter WIDTH=8,
    parameter WAYS=4,
    parameter TOTAL_SIZE=16,
    parameter RAM_DEPTH=256
) (
    input  logic clk, rst, we, re,
    input  logic [$clog2(RAM_DEPTH)-1:0] addr,
    input  logic [WIDTH-1:0] data_in,
    input  logic [WIDTH-1:0] RAM_data_in,
    output logic [WIDTH-1:0] RAM_data_out,
    output logic [$clog2(RAM_DEPTH)-1:0] RAM_addr,
    output logic done, RAM_we,
    output logic [WIDTH-1:0] data_out
);


// *******************************************
// **********   Register uP Inputs   *********
// *******************************************

logic new_operation;
logic we_r, re_r;
logic [$clog2(RAM_DEPTH)-1:0] addr_r;
logic [WIDTH-1:0] data_in_r;

// we consider a new operation to be when either re or we are high
assign new_operation = re | we;

// register uP inputs when a new operation is detected
always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        we_r <= '0;
        re_r <= '0;
        addr_r <= '0;
        data_in_r <= '0;
    end else if (new_operation) begin
        we_r <= we;
        re_r <= re;
        addr_r <= addr;
        data_in_r <= data_in;
    end
end


// *******************************************
// **********       RAM Ports        *********
// *******************************************


// Controlled in cache control block:
//  - RAM_data_in
//  - RAM_we

assign RAM_addr = addr_r; // send uP address to RAM as well
assign RAM_data_out = data_in_r; // send uP data to RAM as well


// ********************************************
// ******   Declaring/Assigning Signals   *****
// ********************************************

// signal for hit/miss logic
logic hit;

// signal for index
logic [$clog2(TOTAL_SIZE/WAYS)-1:0] index; // index size should be TOTAL_SIZE/WAYS

// signals for tag storage
logic [$clog2(RAM_DEPTH)-$clog2(TOTAL_SIZE/WAYS)-1:0] target_tag; // tag size should be RAM_DEPTH - index size
logic [$clog2(RAM_DEPTH)-$clog2(TOTAL_SIZE/WAYS)-1:0] tags [0:WAYS-1]; // array of tags output from tag storage

// signals for valid storage
logic valid_bit [0:WAYS-1]; // valid bit
logic valid_bits [0:WAYS-1]; // valid bits for all ways

// signals for way selection
logic [$clog2(WAYS)-1:0] chosen_way; // selects which way we want
logic [$clog2(WAYS)-1:0] replace_way; // way to replace in case of a cache miss

// signals for data storage
logic [WIDTH-1:0] cache_data_out; // data output from cache
logic [WIDTH-1:0] cache_data_in; // data to be written to cache
logic cache_we; // cache write enable

// assign index and tag from uP address
assign index = addr_r[$clog2(TOTAL_SIZE/WAYS)-1:0];
assign target_tag = addr_r[$clog2(RAM_DEPTH)-1:$clog2(TOTAL_SIZE/WAYS)];

// sanity check:

// ram size == 256 which is 8 bits
// cache size is 16, but since we have 4 ways, its index is only 4 entries == 2 bits
// which would make tag size 6 bits:
// 
//    address    |    tag    | index
//  0b0000 0000  | 0b0000 00 | 0b00    --
//  0b0000 0001  | 0b0000 00 | 0b01       \
//  0b0000 0010  | 0b0000 00 | 0b10         --> these two go into the same index
//  0b0000 0011  | 0b0000 00 | 0b11       /
//  0b0000 0100  | 0b0000 01 | 0b00    --


// ********************************************
// *******     Entity Instantiations     ******
// ********************************************

/* 
    Cache Data
    - is the physical storage for data within the cache
    - organized into multiple ways
    - index used as cache address, total size = number of ways * index size
    - combinational/instant reads, sequential/instant writes
*/

cache_data #(
    .WIDTH(WIDTH),
    .WAYS(WAYS),
    .TOTAL_SIZE(TOTAL_SIZE)
) cache_data_inst (
    .clk(clk),
    .rst(rst),
    .we(cache_we),
    .way(chosen_way),
    .index(index),
    .data_in(cache_data_in),
    .data_out(cache_data_out)
);

/* 
    Cache Tag
    - holds the cache tags for each index and way
    - combinational/instant reads, sequential/instant writes
*/

cache_tag #(
    .WIDTH($clog2(RAM_DEPTH)),
    .WAYS(WAYS),
    .TOTAL_SIZE(TOTAL_SIZE)
) cache_tag_inst (
    .clk(clk),
    .rst(rst),
    .we(cache_we),
    .way(chosen_way),
    .index(index),
    .tag_in(target_tag),
    .tag_out(tags)
);

/* 
    Cache Valid
    - holds the valid bit in the cache for each index and way
    - combinational/instant reads, sequential/instant writes
*/

cache_valid #(
    .WAYS(WAYS),
    .TOTAL_SIZE(TOTAL_SIZE)
) cache_valid_inst (
    .clk(clk),
    .rst(rst),
    .we(cache_we),
    .way(chosen_way),
    .index(index),
    .valid_out(valid_bits)
);

/* 
    Hit/miss Logic
    - determines which way to use for a given address
    - determines if the requested data is in the cache (hit/miss)
*/

cache_hit #(
    .WAYS(WAYS),
    .TOTAL_SIZE(TOTAL_SIZE),
    .RAM_DEPTH(RAM_DEPTH),
    .WIDTH(WIDTH)
) cache_hit_inst (
    .target_tag(target_tag),
    .tags(tags),
    .valid_bits(valid_bits),
    .lru_way(replace_way),
    .hit(hit),
    .chosen_way(chosen_way)
);

/* 
    LRU Replacement Strategy Buffer
    - leastt recently used way output is combinational
    - each read/write cycle updates LRU buffer
    - updates to buffer are sequential
*/
cache_lru #( 
    .WAYS(WAYS),
    .TOTAL_SIZE(TOTAL_SIZE)
) lru_buffer_inst (
    .clk(clk),
    .rst(rst),
    .re(re_r),
    .we(we_r),
    .way(chosen_way),
    .index(index),
    .replace_way(replace_way)
);

/* 
    Cache Control Block
    - Handles all the miscellaneous control signals and logic in the cache
    - Includes done logic, we logic, and cache data logic, and data output logic (which is registered)
*/

cache_control #(
    .WAYS(WAYS),
    .WIDTH(WIDTH)
) cache_control_inst (
    .clk(clk),
    .rst(rst),
    .we(we_r),
    .re(re_r),
    .hit(hit),
    .data_in(data_in_r),
    .data_from_RAM(RAM_data_in),
    .data_from_cache(cache_data_out),
    .done(done),
    .cache_we(cache_we),
    .cache_data_in(cache_data_in),
    .data_out(data_out)
);

assign RAM_we = we_r;

endmodule