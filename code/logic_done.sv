module logic_done (
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
        .data_in(read_hit_delay_out),
        .data_out(reset_reg_read_hit_signal)
    );
    
    component_delay #(
        .WIDTH(WIDTH),
        .CYCLES(2)
    ) read_hit_delay (
        .clk(clk),
        .rst(rst | reset_reg_read_hit_signal),
        .in(re & hit),
        .out(read_hit_delay_out)
    );

    // read miss
    logic read_miss_delay_out;
    logic reset_reg_read_miss_signal;

    component_register #(
        .WIDTH(1)
    ) reset_reg_read_miss (
        .clk(clk),
        .rst(rst),
        .data_in(read_miss_delay_out),
        .data_out(reset_reg_read_miss_signal)
    )

    component_delay #(
        .WIDTH(WIDTH),
        .CYCLES(3)
    ) read_miss_delay (
        .clk(clk),
        .rst(rst | reset_reg_read_miss_signal),
        .in(re & ~hit),
        .out(read_miss_delay_out)
    );

    // write hit
    logic write_hit_delay_out;
    logic reset_reg_write_hit_signal;

    component_register #(
        .WIDTH(1)
    ) reset_reg_write_hit (
        .clk(clk),
        .rst(rst),
        .data_in(write_hit_delay_out),
        .data_out(reset_reg_write_hit_signal)
    );

    component_delay #(
        .WIDTH(WIDTH),
        .CYCLES(2)
    ) write_hit_delay (
        .clk(clk),
        .rst(rst | reset_reg_write_hit_signal),
        .in(we & hit),
        .out(write_hit_delay_out)
    );

    // write miss
    logic write_miss_delay_out;
    logic reset_reg_write_miss_signal;

    component_register #(
        .WIDTH(1)
    ) reset_reg_write_miss (
        .clk(clk),
        .rst(rst),
        .data_in(write_miss_delay_out),
        .data_out(reset_reg_write_miss_signal)
    );

    component_delay #(
        .WIDTH(WIDTH),
        .CYCLES(3)
    ) write_hit_delay (
        .clk(clk),
        .rst(rst | reset_reg_write_miss_signal),
        .in(we & ~hit),
        .out(write_miss_delay_out)
    );

    // or-ing all the done delay outputs
    assign done =   read_hit_delay_out |
                    read_miss_delay_out |
                    write_hit_delay_out |
                    write_miss_delay_out;

endmodule