`include "component_delay.sv"

class delay_transaction #(parameter WIDTH = 8, parameter CYCLES = 4);

    // signals
    rand logic [WIDTH-1:0] data_in;

    // constraints
    // make sure data is 0 10% of the time, 1 10% of the time,
    // and everything else 80% of the time
    constraint data_ranges { data_in dist{'0 :/ 10, '1 :/ 10, [1:2**WIDTH-2] :/ 80}; }

endclass

module delay_tb;

    // constants
    localparam int DIRECTED_TESTS = 1; // determine whether to run directed tests
    localparam int NUM_TESTS = 1000;
    localparam int WIDTH = 8;
    localparam int CYCLES = 4;

    // signals
    logic clk, rst;
    logic [WIDTH-1:0] data_in;
    logic [WIDTH-1:0] data_out;

    // instantiate DUT
    component_delay #(.WIDTH(WIDTH), .CYCLES(CYCLES)) DUT (.*);

    // generate clock
    initial begin : clk_gen
        clk = '0;
        while (1) #5 clk = ~clk;
    end

    // reset inputs
    task reset();
        // assert reset and set other signals low
        rst = '1;
        data_in = '0;

        // wait a couple cycles
        for (int i = 0; i < 5; i++)
            @(posedge clk);

        // deassert reset
        @(negedge clk);
        rst <= '0;
        @(posedge clk);

    endtask

    // write all possible values to register
    task write_all();
        for (int i = 0; i < WIDTH; i++) begin
            data_in = i;
            @(posedge clk);
            @(negedge clk);

            // print first 5 writes
            if (i < 5) begin
                $display("Writing %d", data_in);
            end
        end
    endtask

    // create register_transaction object
    delay_transaction #(.WIDTH(WIDTH), .CYCLES(CYCLES)) item;

    // track failures
    int failures = 0;

    // drive inputs
    initial begin : drive_inputs

        // display that ram tb starting
        $display("Starting component_delay testbench...");

        // reset DUT
        $display("Resetting DUT...");
        reset();
        $display("Reset DUT.");

        // write to all addresses and then read
        if (DIRECTED_TESTS) begin
            $display("Displaying first 5 write tests...");
            write_all();
            $display("All directed write tests completed.");
        end
        
        // print first couple of tests
        $display("Displaying first 5 of %d random tests...", NUM_TESTS);

        // create register_transaction object
        item = new();

        // start tests
        for (int i = 0; i < NUM_TESTS; i++) begin

            // assign random values
            if (item.randomize() == 0) $error("Randomization failed");

            // assign to actual pins
            data_in = item.data_in;

            // display inputs
            if (i < 5) begin
                $display("Test %d at time %0t", i+1, $time);
                $display("data_in: %d", data_in);
            end

            // wait for posedge
            @(posedge clk);
            @(negedge clk);

        end

        // end tests
        disable clk_gen;
        $display("%d tests finished with %d failires.", DIRECTED_TESTS ? 256+NUM_TESTS : NUM_TESTS, failures);

    end

    // ASSERTS!!!!!!!!! to check functionality
    // get a counter to wait for CYCLES cycles after reset
    int counter = 0;
    always_ff @(posedge clk) begin
        if (rst) begin
            counter <= 0;
        end else if (counter < CYCLES-1) begin
            counter <= counter + 1;
        end
    end

    // check delay outputs are valid
    property out_correct_check;
        @(posedge clk) disable iff (rst || counter < CYCLES-1) data_out == $past(data_in, CYCLES);
    endproperty

    // check that outputs are zero after reset
    property out_zero_check;
        @(posedge clk) disable iff (counter == CYCLES-1) data_out == 0;
    endproperty

    // calling assert properties
    assert property (out_correct_check) else begin
        $display("ERROR with out_correct_check: out=%d but supposed to be %d", data_out, $past(data_in, CYCLES));
        failures++;
    end

    assert property (out_zero_check) else begin
        $display("ERROR with out_zero_check: out=%d and counter=%d but out supposed to be %d", data_out, counter, '0);
        failures++;
    end

endmodule