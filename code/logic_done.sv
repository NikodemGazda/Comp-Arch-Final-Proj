module logic_done #(
    parameter MIN_CYCLES = 2
) (
    input logic clk, rst, we, re, hit,
    output logic op_in_progress, pre_done, done
);

    // have a delay train for each scenario and then or all their outputs to get done
    localparam int READ_HIT_CYCLES = MIN_CYCLES;
    localparam int READ_MISS_CYCLES = MIN_CYCLES+1;
    localparam int WRITE_HIT_CYCLES = MIN_CYCLES;
    localparam int WRITE_MISS_CYCLES = MIN_CYCLES+1;

    // read hit
    logic read_hit_delay_out;
    logic read_hit_delay_all_out [0:READ_HIT_CYCLES];
    logic read_hit_ones_in_pipe;

    // OR-ing all the registers to see if any done is in progress--if so, don't let another in
    always_comb begin
        read_hit_ones_in_pipe = '0;
        for (int i = 1; i <= READ_HIT_CYCLES; i++) begin
            read_hit_ones_in_pipe |= read_hit_delay_all_out[i];
        end
    end

    component_delay #(
        .WIDTH(1),
        .CYCLES(READ_HIT_CYCLES)
    ) read_hit_delay (
        .clk(clk),
        .rst(rst),
        .data_in(ones_in_pipe ? '0 : (re & hit)),
        .data_all_out(read_hit_delay_all_out),
        .data_out(read_hit_delay_out)
    );

    // read miss
    logic read_miss_delay_out;
    logic read_miss_delay_all_out [0:READ_MISS_CYCLES];
    logic read_miss_ones_in_pipe;

    // OR-ing all the registers to see if any done is in progress--if so, don't let another in
    always_comb begin
        read_miss_ones_in_pipe = '0;
        for (int i = 1; i <= READ_MISS_CYCLES; i++) begin
            read_miss_ones_in_pipe |= read_miss_delay_all_out[i];
        end
    end

    component_delay #(
        .WIDTH(1),
        .CYCLES(READ_MISS_CYCLES)
    ) read_miss_delay (
        .clk(clk),
        .rst(rst),
        .data_in(ones_in_pipe ? '0 : (re & ~hit)),
        .data_all_out(read_miss_delay_all_out),
        .data_out(read_miss_delay_out)
    );

    // write hit
    logic write_hit_delay_out;
    logic write_hit_delay_all_out [0:WRITE_HIT_CYCLES];
    logic write_hit_ones_in_pipe;

    // OR-ing all the registers to see if any done is in progress--if so, don't let another in
    always_comb begin
        write_hit_ones_in_pipe = '0;
        for (int i = 1; i <= WRITE_HIT_CYCLES; i++) begin
            write_hit_ones_in_pipe |= write_hit_delay_all_out[i];
        end
    end

    component_delay #(
        .WIDTH(1),
        .CYCLES(WRITE_HIT_CYCLES)
    ) write_hit_delay (
        .clk(clk),
        .rst(rst),
        .data_in(ones_in_pipe ? '0 : (we & hit)),
        .data_all_out(write_hit_delay_all_out),
        .data_out(write_hit_delay_out)
    );

    // write miss
    logic write_miss_delay_out;
    logic write_miss_delay_all_out [0:WRITE_MISS_CYCLES];
    logic write_miss_ones_in_pipe;

    // OR-ing all the registers to see if any done is in progress--if so, don't let another in
    always_comb begin
        write_miss_ones_in_pipe = '0;
        for (int i = 1; i <= WRITE_MISS_CYCLES; i++) begin
            write_miss_ones_in_pipe |= write_miss_delay_all_out[i];
        end
    end

    component_delay #(
        .WIDTH(1),
        .CYCLES(WRITE_MISS_CYCLES)
    ) write_miss_delay (
        .clk(clk),
        .rst(rst),
        .data_in(ones_in_pipe ? '0 : (we & ~hit)),
        .data_all_out(write_miss_delay_all_out),
        .data_out(write_miss_delay_out)
    );

    // or-ing all the done delay outputs
    assign done =   read_hit_delay_out |
                    read_miss_delay_out |
                    write_hit_delay_out |
                    write_miss_delay_out;

    // or-ing all the pre_done delay outputs
    assign pre_done =   read_hit_delay_all_out[READ_HIT_CYCLES-1] |
                        read_miss_delay_all_out[READ_MISS_CYCLES-1] |
                        write_hit_delay_all_out[WRITE_HIT_CYCLES-1] |
                        write_miss_delay_all_out[WRITE_MISS_CYCLES-1];

    // or-ing all the outputs to see if there's a 1 in any pipe, meaning there's an 
    // operation in progress
    // have to redo the ones in pipe things bc they don't account for the inputs on first reg
    always_comb begin
        op_in_progress = '0;
        for (int i = 0; i <= READ_HIT_CYCLES; i++) begin
            op_in_progress |= read_hit_delay_all_out[i];
        end
        for (int i = 0; i <= READ_MISS_CYCLES; i++) begin
            op_in_progress |= read_miss_delay_all_out[i];
        end
        for (int i = 0; i <= WRITE_HIT_CYCLES; i++) begin
            op_in_progress |= write_hit_delay_all_out[i];
        end
        for (int i = 0; i <= WRITE_MISS_CYCLES; i++) begin
            op_in_progress |= write_miss_delay_all_out[i];
        end
    end

    // additional logic bc i discovered a bug
    // so when you do a read miss, at some point, the hit signal will go high
    // which will put a 1 in the read hit pipe, which will make the done signal
    // go high for an extra cycle
    // so we need to make sure that the done signal is only high for one cycle
    // by making a super ones_in_pipe signal that ORs all the ones in pipe signals
    logic ones_in_pipe;
    assign ones_in_pipe = read_hit_ones_in_pipe | read_miss_ones_in_pipe | write_hit_ones_in_pipe | write_miss_ones_in_pipe;

endmodule