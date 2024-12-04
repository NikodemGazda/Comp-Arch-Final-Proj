module logic_we (
    input logic clk, rst, we, re, hit,
    output logic cache_we
);

    // internal signals
    logic re_miss_reg_out;
    logic we_hit_reg_out;
    logic we_miss_reg_1_out;
    logic we_miss_reg_2_out;

    // register for read miss
    component_register #(
        .WIDTH(1)
    ) re_miss_reg (
        .clk(clk),
        .rst(rst),
        .en(1'b1),
        .data_in(re_miss_reg_out ? '0 : (re & ~hit)),
        .data_out(re_miss_reg_out)
    );

    // register for write hit
    component_register #(
        .WIDTH(1)
    ) we_hit_reg (
        .clk(clk),
        .rst(rst),
        .en(1'b1),
        .data_in(we && hit),
        .data_out(we_hit_reg_out)
    );

    // registers for write miss
    component_register #(
        .WIDTH(1)
    ) we_miss_reg_1 (
        .clk(clk),
        .rst(rst),
        .en(1'b1),
        .data_in(we && ~hit),
        .data_out(we_miss_reg_1_out)
    );

    component_register #(
        .WIDTH(1)
    ) we_miss_reg_2 (
        .clk(clk),
        .rst(rst),
        .en(1'b1),
        .data_in(we_miss_reg_1_out),
        .data_out(we_miss_reg_2_out)
    );

    // assign cache_wex
    assign cache_we = re_miss_reg_out |
                      (we_hit_reg_out ? '0 : (we && hit)) |
                      ((we_miss_reg_1_out | we_miss_reg_2_out) ? '0 : (we && ~hit));

endmodule