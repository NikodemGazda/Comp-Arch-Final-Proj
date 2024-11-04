module logic_done (
    input logic clk, rst, we, re, hit,
    output logic done
);

    // have a delay train for each scenario and then or all their outputs to get done

    // read hit
    logic read_hit_delay_out;
    delay #(
        .WIDTH(WIDTH),
        .CYCLES(2)
    ) read_hit_delay (
        .clk(clk),
        .rst(rst),
        .in(re & hit),
        .out(read_hit_delay_out)
    );

    // read miss
    logic read_miss_delay_out;
    delay #(
        .WIDTH(WIDTH),
        .CYCLES(3)
    ) read_hit_delay (
        .clk(clk),
        .rst(rst),
        .in(re & ~hit),
        .out(read_miss_delay_out)
    );

    // write hit
    logic write_hit_delay_out;
    delay #(
        .WIDTH(WIDTH),
        .CYCLES(2)
    ) write_hit_delay (
        .clk(clk),
        .rst(rst),
        .in(we & hit),
        .out(write_hit_delay_out)
    );

    // write miss
    logic write_miss_delay_out;
    delay #(
        .WIDTH(WIDTH),
        .CYCLES(3)
    ) write_hit_delay (
        .clk(clk),
        .rst(rst),
        .in(we & ~hit),
        .out(write_miss_delay_out)
    );

    // or-ing all the done delay outputs
    assign done =   read_hit_delay_out |
                    read_miss_delay_out |
                    write_hit_delay_out |
                    write_miss_delay_out;

endmodule