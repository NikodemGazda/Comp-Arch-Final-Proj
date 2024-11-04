// this module handles all the miscellaneous control signals and logic in the cache
module cache_control #(
    parameter WAYS = 4,
    parameter TOTAL_SIZE = 16,
    parameter WIDTH = 8
) (
    input logic clk, rst, we, re, hit,
    input logic [WIDTH-1:0] data_in, data_from_RAM, data_from_cache,
    output logic done, cache_we, RAM_we,
    output logic [WIDTH-1:0] cache_data_in [0:WAYS-1],
    output logic [WIDTH-1:0] data_out,
);

    // we logic
    logic_we logic_we_inst (
        .clk(clk),
        .rst(rst),
        .we(we),
        .re(re),
        .hit(hit),
        .RAM_we(RAM_we),
        .cache_we(cache_we)
    );

    // done logic
    logic_done logic_done_inst (
        .clk(clk),
        .rst(rst),
        .we(we),
        .re(re),
        .hit(hit),
        .done(done)
    );

    // cache data logic : either writing data from the uP or from the RAM
    assign cache_data_in = cache_we ? data_in : data_from_RAM;

    // data output logic
    logic [WIDTH-1:0] which_data;

    // if we're not doing a read, send 0s
    // if it's a hit, send the data from the cache
    // if it's a miss, send the data from the RAM
    // and only output data when done
    assign which_data = re ? (hit ? (data_from_cache) : data_from_RAM) : '0;
    assign done_out = done ? data_out_done_gated : '0;

    component_register #(
        .WIDTH(WIDTH)
    ) data_out_reg (
        .clk(clk),
        .rst(rst),
        .data_in(which_data),
        .data_out(data_out_done_gated)
    );


endmodule