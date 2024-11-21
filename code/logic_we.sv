module logic_we (
    input logic clk, rst, we, re, hit,
    output logic cache_we
);

    // internal signals
    logic internal_we;

    // register for internal_we
    component_register #(
        .WIDTH(1)
    ) internal_we_reg (
        .clk(clk),
        .rst(rst),
        .en(1'b1),
        .data_in(re & ~hit),
        .data_out(internal_we)
    );

    // assign cache_wex
    assign cache_we = we | internal_we;

endmodule