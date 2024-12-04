`include "cache_top.sv"
`include "ram.sv"

module top_level #(
    parameter WIDTH=8,
    parameter WAYS=4,
    parameter TOTAL_SIZE=16,
    parameter RAM_DEPTH=256
) (
    input  logic clk, rst, we, re,
    input  logic [$clog2(RAM_DEPTH)-1:0] addr,
    input  logic [WIDTH-1:0] data_in,
    output logic done, op_in_progress,
    output logic [WIDTH-1:0] data_out
);
    // signals between cache and ram
    logic RAM_we;
    logic [WIDTH-1:0] RAM_data_in, RAM_data_out;
    logic [$clog2(RAM_DEPTH)-1:0] RAM_addr;

    // instantiate cache_top
    cache_top #(
        .WIDTH(WIDTH),
        .WAYS(WAYS),
        .TOTAL_SIZE(TOTAL_SIZE),
        .RAM_DEPTH(RAM_DEPTH)
    ) cache_top_inst (
        .clk(clk),
        .rst(rst),
        .we(we),
        .re(re),
        .addr(addr),
        .data_in(data_in),
        .RAM_data_in(RAM_data_out), // these are swapped bc im silly
        .RAM_data_out(RAM_data_in), // but it's meant to be like this
        .RAM_addr(RAM_addr),
        .op_in_progress(op_in_progress),
        .done(done),
        .RAM_we(RAM_we),
        .data_out(data_out)
    );

    // instantiate ram
    ram #(
        .WIDTH(WIDTH),
        .DEPTH(RAM_DEPTH)
    ) ram_inst (
        .clk(clk),
        .rst(rst),
        .we(RAM_we),
        .addr(RAM_addr),
        .data_in(RAM_data_in),
        .data_out(RAM_data_out)
    );

endmodule