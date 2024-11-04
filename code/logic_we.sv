module logic_we (
    input logic clk, rst, we, re, hit,
    output logic RAM_we, cache_we
);

    // internal signals
    logic internal_we;

    // register for internal_we
    register #(
        .WIDTH(1)
    ) internal_we_reg (
        .clk(clk),
        .rst(rst),
        .data_in(re & ~hit),
        .data_out(internal_we)
    );

    // cache WE logic
    assign cache_we = (we & hit) | internal_we;
    assign RAM_we = we;


endmodule