module logic_we (
    input logic clk, rst, we, re, hit,
    output logic RAM_we, cache_we
);

    // internal signals
    logic internal_we;
    logic RAM_we_delay;

    // register for internal_we
    component_register #(
        .WIDTH(1)
    ) internal_we_reg (
        .clk(clk),
        .rst(rst),
        .data_in(re & ~hit),
        .data_out(internal_we)
    );

    // cache WE logic
    assign cache_we = (we & hit) | internal_we;

    // RAM WE logic
    // if a miss, we add an artificial delay to the RAM WE signal
    assign RAM_we = hit ? we : RAM_we_delay;

    component_register #(
        .WIDTH(1)
    ) RAM_we_reg (
        .clk(clk),
        .rst(rst),
        .data_in(we),
        .data_out(RAM_we_delay)
    );


endmodule