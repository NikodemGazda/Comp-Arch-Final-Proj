`include "cache_control.sv"

class cache_control_transaction #(parameter WAYS=4, parameter WIDTH=8);

    // signals
    logic we, re;
    rand logic hit;
    rand logic [WIDTH-1:0] data_in, data_from_RAM;
    rand logic [$clog2(WAYS)-1:0] chosen_way;
    rand logic [WIDTH-1:0] data_from_cache [0:WAYS-1];

    // constraints

    // make sure way and index are 0 10% of the time, 1 10% of the time,
    // and everything else 80% of the time
    constraint way_ranges { chosen_way dist{'0 :/ 10, '1 :/ 10, [1:(WAYS)-2] :/ 80}; }
    constraint data_in_ranges { data_in dist{'0 :/ 10, '1 :/ 10, [1:(2**WIDTH)-2] :/ 80}; }
    constraint data_from_RAM_ranges { data_from_RAM dist{'0 :/ 10, '1 :/ 10, [1:(2**WIDTH)-2] :/ 80}; }
    constraint data_from_cache_ranges {
        foreach (data_from_cache[i]) {
            data_from_cache[i] dist{'0 :/ 10, '1 :/ 10, [1:(2**WIDTH)-2] :/ 80};
        }
    }

    // if re || we is 1, hit should have a 50% chance of being 1,
    // but hit shouldn't be high when re ||we neither are
    constraint hit_re_we { 
        if (re || we) {
            hit dist {'0 :/ 1, '1 :/ 1};
        } else {
            hit == '0;
        }   
    }

endclass

module cache_control_tb;

    // constants
    localparam int NUM_TESTS = 10;
    localparam int WIDTH = 8;
    localparam int WAYS = 4;
    localparam int HIT_DELAY = 1;
    localparam int MISS_DELAY = 2;

    // track failures
    int failures = 0; 
    int rand_failures = 0; 

    // signals
    // general
    logic clk, rst;
    // inputs
    logic we, re, hit;
    logic [$clog2(WAYS)-1:0] chosen_way;
    logic [WIDTH-1:0] data_in, data_from_RAM;
    logic [WIDTH-1:0] data_from_cache [0:WAYS-1];
    // outputs
    logic done, cache_we;
    logic [WIDTH-1:0] cache_data_in;
    logic [WIDTH-1:0] data_out;

    // instantiate DUT
    cache_control #(.WAYS(WAYS), .WIDTH(WIDTH)) DUT (.*);

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
        hit = '0;
        chosen_way = '0;
        data_in = '0;
        data_from_RAM = '0;
        for (int i = 0; i < WAYS; i++) data_from_cache[i] = '0;

        // wait a couple cycles
        for (int i = 0; i < 5; i++)
            @(posedge clk);

        // deassert reset
        @(negedge clk);
        rst <= '0;
        @(posedge clk);

    endtask

    // Random test neither read nor write enable:
    task test_random_0(int test_num=1);

        // declaring the transaction objects
        cache_control_transaction #(.WAYS(WAYS), .WIDTH(WIDTH)) item;

        item = new();

        item.re = 0;
        item.we = 0;

        if (item.randomize() == 0) begin 
            $error("Randomization failed");
            rand_failures++;
        end

        // assign pins
        re = item.re;
        we = item.we;
        hit = item.hit;
        chosen_way = item.chosen_way;
        data_in = item.data_in;
        data_from_RAM = item.data_from_RAM;
        for (int i = 0; i < WAYS; i++) data_from_cache[i] = item.data_from_cache[i];

        // waiting on clock and reporting results/errors
        @(posedge clk);
        @(negedge clk);
        
    endtask

    // Random test write enable:
    task test_random_we(int test_num=1);

        // declaring the transaction objects
        cache_control_transaction #(.WAYS(WAYS), .WIDTH(WIDTH)) item;

        item = new();

        item.re = 0;
        item.we = 1;

        if (item.randomize() == 0) begin 
            $error("Randomization failed");
            rand_failures++;
        end

        // assign pins
        re = item.re;
        we = item.we;
        hit = item.hit;
        chosen_way = item.chosen_way;
        data_in = item.data_in;
        data_from_RAM = item.data_from_RAM;
        for (int i = 0; i < WAYS; i++) data_from_cache[i] = item.data_from_cache[i];

        // waiting on clock and reporting results/errors
        @(posedge clk);
        @(negedge clk);
        
    endtask

    // Random test read enable:
    task test_random_re(int test_num=1);

        // declaring the transaction objects
        cache_control_transaction #(.WAYS(WAYS), .WIDTH(WIDTH)) item;

        item = new();

        item.re = 1;
        item.we = 0;

        if (item.randomize() == 0) begin 
            $error("Randomization failed");
            rand_failures++;
        end

        // assign pins
        re = item.re;
        we = item.we;
        hit = item.hit;
        chosen_way = item.chosen_way;
        data_in = item.data_in;
        data_from_RAM = item.data_from_RAM;
        for (int i = 0; i < WAYS; i++) data_from_cache[i] = item.data_from_cache[i];

        // waiting on clock and reporting results/errors
        @(posedge clk);
        @(negedge clk);
        
    endtask

    // drive inputs
    initial begin : drive_inputs

        // display that ram tb starting
        $display("\nStarting Cache Control Block testbench...");

        // reset DUT
        $display("\nResetting DUT...");
        reset();
        $display("Reset DUT.");

        // Random tests
        if (NUM_TESTS > 0) begin
            $display("\nRunning random tests...");

            // rest of the random tests
            for (int i = 0; i < NUM_TESTS-1; i++) begin
                
                // print first 5 tests
                // first do re test
                if (i < NUM_TESTS) $display("\nRunning read random test %d...", i+1);
                test_random_re();
                if (i < NUM_TESTS) $display("\nINPUTS:\nRE: %b, WE: %b, hit: %b, chosen_way: %d,\ndata_in: %d, data_from_cache: [%d,%d,%d,%d],\ndata_from_RAM: %d", re, we, hit, chosen_way, data_in, data_from_cache[0], data_from_cache[1], data_from_cache[2], data_from_cache[3], data_from_RAM);
                if (i < NUM_TESTS) $display("OUTPUTS:\ndone: %b, cache_we: %b,\ncache_data_in: %d, data_out: %d", done, cache_we, cache_data_in, data_out);
                
                // then repeat 2 tests with neither re nor we to let the operation finish
                for (int j = 0; j < 2; j++) begin
                    test_random_0();
                    if (i < NUM_TESTS) $display("\nINPUTS:\nRE: %b, WE: %b, hit: %b, chosen_way: %d,\ndata_in: %d, data_from_cache: [%d,%d,%d,%d],\ndata_from_RAM: %d", re, we, hit, chosen_way, data_in, data_from_cache[0], data_from_cache[1], data_from_cache[2], data_from_cache[3], data_from_RAM);
                    if (i < NUM_TESTS) $display("OUTPUTS:\ndone: %b, cache_we: %b,\ncache_data_in: %d, data_out: %d", done, cache_we, cache_data_in, data_out);
                end

                // then do we test
                if (i < NUM_TESTS) $display("\nRunning write random test %d...", i+1);
                test_random_we();
                if (i < NUM_TESTS) $display("\nINPUTS:\nRE: %b, WE: %b, hit: %b, chosen_way: %d,\ndata_in: %d, data_from_cache: [%d,%d,%d,%d],\ndata_from_RAM: %d", re, we, hit, chosen_way, data_in, data_from_cache[0], data_from_cache[1], data_from_cache[2], data_from_cache[3], data_from_RAM);
                if (i < NUM_TESTS) $display("OUTPUTS:\ndone: %b, cache_we: %b,\ncache_data_in: %d, data_out: %d", done, cache_we, cache_data_in, data_out);
                
                // and repeat again 2 tests with neither re nor we
                for (int j = 0; j < 2; j++) begin
                    test_random_0();
                    if (i < NUM_TESTS) $display("\nINPUTS:\nRE: %b, WE: %b, hit: %b, chosen_way: %d,\ndata_in: %d, data_from_cache: [%d,%d,%d,%d],\ndata_from_RAM: %d", re, we, hit, chosen_way, data_in, data_from_cache[0], data_from_cache[1], data_from_cache[2], data_from_cache[3], data_from_RAM);
                    if (i < NUM_TESTS) $display("OUTPUTS:\ndone: %b, cache_we: %b,\ncache_data_in: %d, data_out: %d", done, cache_we, cache_data_in, data_out);
                end

            end
        end

        // end tests
        disable clk_gen;

        $display("\n%d tests finished with %d failires.", NUM_TESTS, failures);
        $display("Randomization failed %d times.", rand_failures);

    end

    // ASSERTS!!!!!!!!! to check functionality
    /***** WE LOGIC *****/
    // cache_we is we OR the previous cycle of re and miss
    property we_logic_check;
        @(posedge clk) disable iff (rst) cache_we == (we | $past(re && ~hit));
    endproperty

    assert property (we_logic_check) else begin
        $error("we_logic_check failed: cache_we == %b when we == %b, past re == %b, past hit == %b, and past re&&~hit == %b.", cache_we, we, $past(re), $past(hit), $past(re && ~hit));
        failures++;
    end

    /***** DONE LOGIC *****/
    // done is high 2 cycles after hit and (we or re) and 3 cycles after miss and (we or re)
    property done_high;
        @(posedge clk) disable iff (rst) (done == '1) |-> $past(re && hit,HIT_DELAY) || $past(we && hit,HIT_DELAY) || $past(re && ~hit,MISS_DELAY) || $past(we && ~hit,MISS_DELAY);
    endproperty

    assert property (done_high) else begin
        $error("done_high failed: done == %b when past(%d) re hit == %b and we hit == %b and past(%d) re miss == %b and we miss == %b.", done, HIT_DELAY, $past(re && hit,HIT_DELAY), $past(we && hit,HIT_DELAY), MISS_DELAY, $past(re && ~hit,MISS_DELAY), $past(we && ~hit,MISS_DELAY));
        failures++;
    end
    
    // done is low unless past conditions are met
    property done_low;                  
        @(posedge clk) disable iff (rst) (done == '0) |-> !$past(re && hit,HIT_DELAY) && !$past(we && hit,HIT_DELAY) && !$past(re && ~hit,MISS_DELAY) && !$past(we && ~hit,MISS_DELAY);
    endproperty

    assert property (done_low) else begin
        $error("done_low failed: done == %b when past(%d) re hit == %b and we hit == %b and past(%d) re miss == %b and we miss == %b.", done, HIT_DELAY, $past(re && hit,HIT_DELAY), $past(we && hit,HIT_DELAY), MISS_DELAY, $past(re && ~hit,MISS_DELAY), $past(we && ~hit,MISS_DELAY));
        failures++;
    end

    // done is 1 or 0
    property done_1_or_0;
        @(negedge clk) disable iff (rst) (done == '1) || (done == '0);
    endproperty

    assert property (done_1_or_0) else begin
        $error("done_1_or_0 failed: done == %b.", done);
        failures++;
    end

    /***** CACHE DATA LOGIC *****/
    // cache_data_in is data_in when WE and is data_from_RAM otherwise 
    // *immediate assertion
    always_comb begin
        if (we && $time() > 0 && !rst) begin
            if(cache_data_in != data_in) begin
                $error("cache_data_in failed: cache_data_in == %d when we == %b and data_in == %d.", cache_data_in, we, data_in);
                failures++;
            end
        end else if (!we && $time() > 0 && !rst) begin
            if(cache_data_in != data_from_RAM) begin
                $error("cache_data_in failed: cache_data_in == %d when we == %b and data_from_RAM == %d.", cache_data_in, we, data_from_RAM);
                failures++;
            end
        end
    end

    /***** DATA OUT LOGIC *****/
    // if re and hit, data_out next cycle is data_from_cache[chosen_way] from prev cycle, disable iff done is low
        // apparently this is required or it gives me a dumb error
        logic past_chosen_way;
        always_ff @(posedge clk) begin
            past_chosen_way <= chosen_way;
        end

    property data_out_re_hit;
        @(posedge clk) disable iff (rst) (re && hit) |=> data_out == $past(data_from_cache[past_chosen_way]);
    endproperty

    // assert property (data_out_re_hit) else begin
    //     $error("data_out_re_hit failed: data_out == %d when past re == %b, hit == %b, done == %b, and past data_from_cache[%d] == %d.", data_out, $past(re), $past(hit), done, $past(chosen_way), $past(data_from_cache[$past(chosen_way)]);
    //     failures++;
    // end
    
    // // if re and miss, data_out next cycle is data_from_RAM from prev cycle, disable iff done is low
    // property data_out_re_miss;
    //     @(posedge clk) disable iff (rst || !done) (re && !hit) |=> data_out == $past(data_from_RAM);
    // endproperty

    // assert property (data_out_re_miss) else begin
    //     $error("data_out_re_miss failed: data_out == %d when past re == %b, hit == %b, done == %b, and past data_from_RAM == %d.", data_out, $past(re), $past(hit), done, $past(data_from_RAM));
    //     failures++;
    // end

endmodule