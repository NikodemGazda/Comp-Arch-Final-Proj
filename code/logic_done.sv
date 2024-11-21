module logic_done #(
    parameter MIN_CYCLES = 2
) (
    input logic clk, rst, we, re, hit,
    output logic done
);

    // have a delay train for each scenario and then or all their outputs to get done

    // read hit
    logic read_hit_delay_out;
    logic reset_reg_read_hit_signal;

    component_register #(
        .WIDTH(1)
    ) reset_reg_read_hit (
        .clk(clk),
        .rst(rst),
        .en(1'b1),
        .data_in(read_hit_delay_out),
        .data_out(reset_reg_read_hit_signal)
    );
    
    component_delay #(
        .WIDTH(1),
        .CYCLES(MIN_CYCLES)
    ) read_hit_delay (
        .clk(clk),
        .rst(rst | reset_reg_read_hit_signal),
        .data_in(re & hit),
        .data_out(read_hit_delay_out)
    );

    // read miss
    logic read_miss_delay_out;
    logic reset_reg_read_miss_signal;

    component_register #(
        .WIDTH(1)
    ) reset_reg_read_miss (
        .clk(clk),
        .rst(rst),
        .en(1'b1),
        .data_in(read_miss_delay_out),
        .data_out(reset_reg_read_miss_signal)
    );

    component_delay #(
        .WIDTH(1),
        .CYCLES(MIN_CYCLES + 1)
    ) read_miss_delay (
        .clk(clk),
        .rst(rst | reset_reg_read_miss_signal),
        .data_in(re & ~hit),
        .data_out(read_miss_delay_out)
    );

    // write hit
    logic write_hit_delay_out;
    logic reset_reg_write_hit_signal;

    component_register #(
        .WIDTH(1)
    ) reset_reg_write_hit (
        .clk(clk),
        .rst(rst),
        .en(1'b1),
        .data_in(write_hit_delay_out),
        .data_out(reset_reg_write_hit_signal)
    );

    component_delay #(
        .WIDTH(1),
        .CYCLES(MIN_CYCLES)
    ) write_hit_delay (
        .clk(clk),
        .rst(rst | reset_reg_write_hit_signal),
        .data_in(we & hit),
        .data_out(write_hit_delay_out)
    );

    // write miss
    logic write_miss_delay_out;
    logic reset_reg_write_miss_signal;

    component_register #(
        .WIDTH(1)
    ) reset_reg_write_miss (
        .clk(clk),
        .rst(rst),
        .en(1'b1),
        .data_in(write_miss_delay_out),
        .data_out(reset_reg_write_miss_signal)
    );

    component_delay #(
        .WIDTH(1),
        .CYCLES(MIN_CYCLES + 1)
    ) write_miss_delay (
        .clk(clk),
        .rst(rst | reset_reg_write_miss_signal),
        .data_in(we & ~hit),
        .data_out(write_miss_delay_out)
    );

    // or-ing all the done delay outputs
    assign done =   read_hit_delay_out |
                    read_miss_delay_out |
                    write_hit_delay_out |
                    write_miss_delay_out;

endmodule