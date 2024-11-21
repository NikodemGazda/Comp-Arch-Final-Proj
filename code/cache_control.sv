`include "logic_we.sv"
`include "logic_done.sv"
`include "component_register.sv"
`include "component_delay.sv"

// this module handles all the miscellaneous control signals and logic in the cache
module cache_control #(
    parameter WAYS = 4,
    parameter WIDTH = 8
) (
    input logic clk, rst, we, re, hit,
    input logic [$clog2(WAYS)-1:0] chosen_way,
    input logic [WIDTH-1:0] data_in, data_from_RAM,
    input logic [WIDTH-1:0] data_from_cache [0:WAYS-1],
    output logic done, cache_we,
    output logic [WIDTH-1:0] cache_data_in,
    output logic [WIDTH-1:0] data_out
);

    /************ we logic ************/
    logic_we logic_we_inst (
        .clk(clk),
        .rst(rst),
        .we(we),
        .re(re),
        .hit(hit),
        .cache_we(cache_we)
    );

    /************ done logic ************/
    logic_done #(
        .MIN_CYCLES(1)
    ) logic_done_inst (
        .clk(clk),
        .rst(rst),
        .we(we),
        .re(re),
        .hit(hit),
        .done(done)
    );

    // pre-done logic for cache data in
    logic pre_done;
    logic_done #(
        .MIN_CYCLES(0)
    ) cache_data_in_done (
        .clk(clk),
        .rst(rst),
        .we(we),
        .re(re),
        .hit(hit),
        .done(pre_done)
    );

    /************ cache data logic ************/
    // either writing data from the uP or from the RAM
    assign cache_data_in = we ? data_in : data_from_RAM;

    /************ data output logic ************/
    logic [WIDTH-1:0] which_data;

    // if we're not doing a read, send 0s
    // if we are doing a read, if it's a hit, send the data from the cache
    // if it's a miss, send the data from the RAM
    // and only output data when done
    assign which_data = re ? (hit ? (data_from_cache[chosen_way]) : data_from_RAM) : '0;

    component_register #(
        .WIDTH(WIDTH)
    ) data_out_reg_cycle_1 (
        .clk(clk),
        .rst(rst),
        .en(pre_done),
        .data_in(which_data),
        .data_out(data_out)
    );

    // empty delay block because we get include errors if it's not here!!!!! for some reason!!!
    component_delay ugh();

endmodule