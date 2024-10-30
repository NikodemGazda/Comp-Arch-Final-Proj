module cache_top #(
    parameter WIDTH=8,
    parameter WAYS=4,
    parameter TOTAL_SIZE=16,
    parameter RAM_DEPTH=256
) (
    input  logic clk, rst, we, re,
    input  logic [$clog2(RAM_DEPTH)-1:0] addr,
    input  logic [WIDTH-1:0] data_in,
    output logic [WIDTH-1:0] data_out
);

// get signals
logic [$clog2(WAYS)-1:0] way; // selects which way we want
logic [$clog2(TOTAL_SIZE/WAYS)-1:0] index; // index size should be TOTAL_SIZE/WAYS
logic [$clog2(WAYS)-1:0] replace_way; // way to replace in case of a cache miss

// assign index and tag from address
assign index = addr[$clog2(TOTAL_SIZE/WAYS)-1:0];
assign tag = addr[$clog2(RAM_DEPTH)-1:$clog2(TOTAL_SIZE/WAYS)];

// ram size == 256 which is 8 bits
// cache size is 16, but since we have 4 ways, it's index is only 4 entries == 2 bits
// which would make tag size 6 bits?
//    address    |    tag    | index
//  0b0000 0000  | 0b0000 00 | 0b00
//  0b0000 0001  | 0b0000 00 | 0b01
//  0b0000 0010  | 0b0000 00 | 0b10
//  0b0000 0011  | 0b0000 00 | 0b11
//  0b0000 0100  | 0b0000 01 | 0b00

/* 
    Cache Data
    - is the physical storage for data within the cache
    - organized into multiple ways
    - index used as cache address, total size = number of ways * index size

    ********* EDIT SO EACH WAY DATA IS OUTPUT IN PARALLEL *********
*/
// signals for data storage
logic [WIDTH-1:0] data; // tag size should be RAM_DEPTH - index size
logic [WIDTH-1:0] datas [0:WAYS-1]; // tag size should be RAM_DEPTH - index size

// cache data block
cache_data #(
    .WIDTH(WIDTH),
    .WAYS(WAYS),
    .TOTAL_SIZE(TOTAL_SIZE)
) cache_data_inst (
    .clk(clk),
    .rst(rst),
    .we(we),
    .re(re),
    .way(way),
    .index(index),
    .data_in(data_in),
    .data_out(datas)
);

/* 
    Cache Tag
    - holds the cache tags for each index and way
    ********* EDIT SO EACH WAY TAG IS OUTPUT IN PARALLEL *********
*/
// signals for tag storage
logic [$clog2(RAM_DEPTH)-$clog2(TOTAL_SIZE/WAYS)-1:0] tag; // tag size should be RAM_DEPTH - index size
logic [$clog2(RAM_DEPTH)-$clog2(TOTAL_SIZE/WAYS)-1:0] tags [0:WAYS-1]; // array of tags output from tag storage

// cache tag block
cache_tag #(
    .WIDTH($clog2(RAM_DEPTH)),
    .WAYS(WAYS),
    .TOTAL_SIZE(TOTAL_SIZE)
) cache_tag_inst (
    .clk(clk),
    .rst(rst),
    .we(we),
    .re(re),
    .way(way),
    .index(index),
    .tag_in(tag),
    .tag_out(tags)
);

/* 
    Cache Valid
    - holds the valid bit in the cache for each index and way
    ********* EDIT SO EACH WAY VALID BIT IS OUTPUT IN PARALLEL *********
*/
// signals for valid storage
logic valid_bit [0:WAYS-1]; // valid bit
logic valid_bits [0:WAYS-1]; // valid bits for all ways

// valid bit block
cache_valid #(
    .WAYS(WAYS),
    .TOTAL_SIZE(TOTAL_SIZE)
) cache_valid_inst (
    .clk(clk),
    .rst(rst),
    .we(we),
    .way(way),
    .index(index),
    .valid_out(valid_out)
);

/* 
    Way Selection Logic
    - determines which way to use for a given address
    - determines if the requested data is in the cache

    // so first determine whether hit or miss using valid bits and tags (diagram logic)
    // if hit, then we can use the way to access the data
    // if miss, use LRU to determine which way to replace
*/

/* 
    LRU Replacement Strategy Buffer
    - leastt recently used way output is combinational
    - each read/write cycle updates LRU buffer
*/
lru_buffer #( 
    .WAYS(WAYS),
    .TOTAL_SIZE(TOTAL_SIZE)
) lru_buffer_inst (
    .clk(clk),
    .rst(rst),
    .re(re),
    .we(we),
    .way(way),
    .index(index),
    .replace_way(replace_way)
);

endmodule