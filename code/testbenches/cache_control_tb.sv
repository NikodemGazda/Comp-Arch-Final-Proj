`include "cache_control.sv"

class cache_control_transaction #(parameter WAYS=4, parameter WIDTH=8);

    // signals
    logic we, re, hit;
    logic [WIDTH-1:0] data_in, data_from_RAM;
    logic [$clog2(WAYS)-1:0] chosen_way;
    logic [WIDTH-1:0] data_from_cache [0:WAYS-1];

    // constraints

    // make sure way and index are 0 10% of the time, 1 10% of the time,
    // and everything else 80% of the time
    constraint way_ranges { way dist{'0 :/ 10, '1 :/ 10, [1:(WAYS)-2] :/ 80}; }
    constraint index_ranges { way dist{'0 :/ 10, '1 :/ 10, [1:(TOTAL_SIZE/WAYS)-2] :/ 80}; }

    // re/we constraint that the or of the two signals is 0 50% of the time, 1 50% of the time
    constraint re_we { (re || we) dist {'0 :/ 1, '1 :/ 1}; }

endclass

module cache_control_tb;

    // constants
    // localparam int NUM_DIRECTED = 0;
    // localparam int NUM_TESTS = 0;
    localparam int NUM_DIRECTED = 10;
    localparam int NUM_TESTS = 100;
    localparam int WIDTH = 8;
    localparam int WAYS = 4;
    localparam int TOTAL_SIZE = 16;

    // track failures
    int failures = 0; 
    int rand_failures = 0; 

    // signals
    // general
    logic clk, rst;
    // inputs
    logic we, re, hit;
    logic [WIDTH-1:0] data_in, data_from_RAM;
    logic [$clog2(WAYS)-1:0] chosen_way,
    logic [WIDTH-1:0] data_from_cache [0:WAYS-1];,
    // outputs
    logic done, cache_we, RAM_we;
    logic [WIDTH-1:0] cache_data_in;
    logic [WIDTH-1:0] data_out;

    // instantiate DUT
    cache_control #(.WAYS(WAYS), .TOTAL_SIZE(TOTAL_SIZE)) DUT (.*);

    // generate clock
    initial begin : clk_gen
        clk = '0;
        while (1) #5 clk = ~clk;
    end

    /************** TASKS **************/

    // reset inputs
    task reset();
        // assert reset and set other signals low
        rst = '1;
        re = '0;
        we = '0;
        way = '0;
        index = '0;

        // wait a couple cycles
        for (int i = 0; i < 5; i++)
            @(posedge clk);

        // deassert reset
        @(negedge clk);
        rst <= '0;
        @(posedge clk);

    endtask

    // Sequential directed tests
    task test_seq(logic [1:0] a=0,logic [1:0] b=0);

        // setting inputs based on directed test number
        re = '0;
        we = '1;
        way = b;
        index = a;

        // waiting on clock and reporting results/errors
        @(posedge clk);
        @(negedge clk);

    endtask

    // directed tests
    // Test 1: all inputs are low (read/write enable, way, index)
    // Repetitions of this testcase should continually output 0 as the replacement way/bank.
    // Test 2: all inputs are high 
    // Repetitions of this testcase should continually output 0 as the replacement way/bank as well since bank 3 (2b’11 in binary) will continually be the most recently used bank.

    task test_directed(int num_loop=0, int test_num=1);

        // setting inputs based on directed test number
        if (test_num == 1) begin
            re = '0;
            we = '0;
            way = '0;
            index = '0;
        end else begin
            re = '1;
            we = '1;
            way = '1;
            index = '1;
        end

        // waiting on clock and reporting results/errors
        @(posedge clk);
        @(negedge clk);
        // some minor error checking
        if (replace_way != '0) $error("output replacement way is not 0");

    endtask

    // Random Tests:
    // Test 1 (100 repetitions): Neither read nor write enable are ever asserted to test that the
        // LRU buffer should only ever update when the enables are asserted. The way and index inputs
        // are randomized according to the global constraints listed below (including reset).
    // Test 2 (100 repetitions): Read enable is asserted every cycle, write enable is never asserted.
        // The way, index, and reset inputs are randomized as in test 1.
    // Test 3 (100 repetitions): Same as test 2 but replace read enable with write enable.
    // Test 4 (700 repetitions): All inputs are randomized with the constraint that read enable and
        // write enable are never both asserted at the same time, as this shouldn’t happen in the cache
        // block itself.

    // Random test 1:
    task test_random(int test_num=1);

        // declaring the transaction objects
        cache_control_transaction #(.WAYS(WAYS), .TOTAL_SIZE(TOTAL_SIZE)) item;

        item = new();

        if (item.randomize() == 0) begin 
            $error("Randomization failed");
            rand_failures++;
        end

        // assign pins
        re = item.re;
        we = item.we;
        way = item.way;
        index = item.index;

        // waiting on clock and reporting results/errors
        @(posedge clk);
        @(negedge clk);
        
    endtask

    // drive inputs
    initial begin : drive_inputs

        // display that ram tb starting
        $display("\nStarting Cache LRU Buffer testbench...");

        // reset DUT
        $display("\nResetting DUT...");
        reset();
        $display("Reset DUT.");

        // run directed tests
        if (NUM_DIRECTED > 0) begin
            $display("\nRunning directed tests...");
            for (int k = 0; k < 4; k++) $display("Internal LRU Buffer: [%d, %d, %d, %d]", DUT.last_used[0][k], DUT.last_used[1][k], DUT.last_used[2][k], DUT.last_used[3][k]);
        end

        // Sequential directed tests
        if (NUM_DIRECTED > 0) begin
            for (int i = 0; i < 4; i++) begin
                for (int j = 0; j < 4; j++) begin
                    test_seq(i, j);
                    $display("Sequential Directed Test %d at time %0t", i*4+j, $time);
                    $display("Re: %b, We: %b, Way: %d, Index: %d, output replacement way: %d", re, we, way, index, replace_way);
                    for (int k = 0; k < 4; k++) $display("Internal LRU Buffer: [%d, %d, %d, %d]", DUT.last_used[0][k], DUT.last_used[1][k], DUT.last_used[2][k], DUT.last_used[3][k]);
                end
            end
        end

        // test 1
        for (int i = 0; i < NUM_DIRECTED; i++) begin
            test_directed(i, 1);
            $display("\nDirected Test 1 Repetition %d at time %0t", i, $time);
            $display("Re: %b, We: %b, Way: %b, Index: %b, output replacement way: %b", re, we, way, index, replace_way);
            $display("Internal LRU Buffer: %d, %d, %d, %d", DUT.last_used[0][index], DUT.last_used[1][index], DUT.last_used[2][index], DUT.last_used[3][index]);
        end
        
        // test 2
        for (int i = 0; i < NUM_DIRECTED; i++) begin
            test_directed(i, 2);
            $display("\nDirected Test 2 Repetition %d at time %0t", i, $time);
            $display("Re: %b, We: %b, Way: %b, Index: %b, output replacement way: %b", re, we, way, index, replace_way);
            $display("Internal LRU Buffer: %d, %d, %d, %d", DUT.last_used[0][index], DUT.last_used[1][index], DUT.last_used[2][index], DUT.last_used[3][index]);
        end

        // Random tests
        if (NUM_TESTS > 0) begin
            $display("\nRunning random tests...");

            // print first results for each test
            test_random(1); // random test 1

            $display("\nInternal LRU Buffer: %d, %d, %d, %d", DUT.last_used[0][index], DUT.last_used[1][index], DUT.last_used[2][index], DUT.last_used[3][index]);
            $display("\nRandom test 1 repetition 1:");
            $display("Re: %b, We: %b, Way: %b, Index: %b, output replacement way: %b", re, we, way, index, replace_way);
            $display("Internal LRU Buffer: %d, %d, %d, %d", DUT.last_used[0][index], DUT.last_used[1][index], DUT.last_used[2][index], DUT.last_used[3][index]);

            test_random(2); // random test 2

            $display("\nRandom test 2 repetition 1:\noutput replacement way: %b", replace_way);
            $display("Re: %b, We: %b, Way: %b, Index: %b, output replacement way: %b", re, we, way, index, replace_way);
            $display("Internal LRU Buffer: %d, %d, %d, %d", DUT.last_used[0][index], DUT.last_used[1][index], DUT.last_used[2][index], DUT.last_used[3][index]);

            test_random(3); // random test 3

            $display("\nRandom test 3 repetition 1:\noutput replacement way: %b", replace_way);
            $display("Re: %b, We: %b, Way: %b, Index: %b, output replacement way: %b", re, we, way, index, replace_way);
            $display("Internal LRU Buffer: %d, %d, %d, %d", DUT.last_used[0][index], DUT.last_used[1][index], DUT.last_used[2][index], DUT.last_used[3][index]);

            // run test 4 7 times total
            for (int j = 0; j < 7; j++) begin
                test_random(4); // random test 4

                $display("\nRandom test 4 repetition %d:\noutput replacement way: %b", j, replace_way);
                $display("Re: %b, We: %b, Way: %b, Index: %b, output replacement way: %b", re, we, way, index, replace_way);
                $display("Internal LRU Buffer: %d, %d, %d, %d", DUT.last_used[0][index], DUT.last_used[1][index], DUT.last_used[2][index], DUT.last_used[3][index]);
            end

            // rest of the random tests
            for (int i = 0; i < NUM_TESTS-1; i++) begin
                test_random(1); // random test 1
                test_random(2); // random test 2
                test_random(3); // random test 3

                // run test 4 7 times total
                for (int j = 0; j < 7; j++) begin
                    test_random(4); // random test 4
                end
            end
        end

        // end tests
        disable clk_gen;
        // NUM_TESTS is for random tests, each random test has 10 unique tests
        // NUM_DIRECTED is the number of directed tests, of which there are 2 unique ones
        // There are also sequential directed tests, which have 16 unqiue tests independent of the number of directed tests.
        $display("\n%d tests finished with %d failires.", 10*NUM_TESTS+2*NUM_DIRECTED+16*(NUM_DIRECTED > 0 ? 1 : 0), failures);
        $display("Randomization failed %d times.", rand_failures);

    end

    // ASSERTS!!!!!!!!! to check functionality

endmodule