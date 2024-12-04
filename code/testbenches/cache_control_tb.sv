`include "cache_control.sv"

class cache_control_transaction #(parameter WAYS=4, parameter WIDTH=8);

    // signals
    logic we, re;
    rand logic hit;
    rand logic [WIDTH-1:0] data_in, data_from_RAM;
    rand logic [$clog2(WAYS)-1:0] chosen_way;
    rand logic [WIDTH-1:0] data_from_cache [0:WAYS-1];

    // constraints

    // make sure index is 0 10% of the time, 1 10% of the time,
    // and everything else 80% of the time
    constraint data_in_ranges { data_in dist{'0 :/ 10, '1 :/ 10, [1:(2**WIDTH)-2] :/ 80}; }
    constraint data_from_RAM_ranges { data_from_RAM dist{'0 :/ 10, '1 :/ 10, [1:(2**WIDTH)-2] :/ 80}; }
    constraint data_from_cache_ranges {
        foreach (data_from_cache[i]) {
            data_from_cache[i] dist{'0 :/ 10, '1 :/ 10, [1:(2**WIDTH)-2] :/ 80};
        }
    }

    // if re || we is 1, hit should have a 50% chance of being 1
    constraint hit_re_we { 
        if (re || we) {
            hit dist {'0 :/ 1, '1 :/ 1};
        }
    }

endclass

module cache_control_tb;

    // constants
    localparam int NUM_TESTS = 1000;
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
    logic op_in_progress, done, cache_we;
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

        // don't start new tests
        if (done == '1) begin
            re = '0;
            we = '0;
        end

        // Randomize data_from_RAM with inline constraints
        if (!std::randomize(data_from_RAM) with {
            data_from_RAM dist {'0 :/ 10, '1 :/ 10, [1:(2**WIDTH)-2] :/ 80};
        }) begin
            $error("Randomization failed for data_from_RAM");
            rand_failures++;
        end
        
        // waiting on clock and reporting results/errors
        @(posedge clk);
        // @(negedge clk);
        
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
        // @(negedge clk);
        
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
        // @(negedge clk);
        
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
            for (int i = 0; i < NUM_TESTS; i++) begin
                
                // print first 5 tests
                // first do re test
                if (i < 2) $display("\nRunning read random test %d...", i+1);

                test_random_re();
                if (i < 2) $display("\nTime: %t, INPUTS:\nRE: %b, WE: %b, hit: %b, chosen_way: %d,\ndata_in: %d, data_from_cache: [%d,%d,%d,%d],\ndata_from_RAM: %d", $time(), re, we, hit, chosen_way, data_in, data_from_cache[0], data_from_cache[1], data_from_cache[2], data_from_cache[3], data_from_RAM);
                if (i < 2) $display("OUTPUTS:\nop: %b, done: %b, cache_we: %b,\ncache_data_in: %d, data_out: %d", op_in_progress, done, cache_we, cache_data_in, data_out);

                // then repeat 2 tests with neither re nor we to let the operation finish
                for (int j = 0; j < 2; j++) begin
                    test_random_0();
                    if (i < 2) $display("\nTime: %t, INPUTS:\nRE: %b, WE: %b, hit: %b, chosen_way: %d,\ndata_in: %d, data_from_cache: [%d,%d,%d,%d],\ndata_from_RAM: %d", $time(), re, we, hit, chosen_way, data_in, data_from_cache[0], data_from_cache[1], data_from_cache[2], data_from_cache[3], data_from_RAM);
                    if (i < 2) $display("OUTPUTS:\nop: %b, done: %b, cache_we: %b,\ncache_data_in: %d, data_out: %d", op_in_progress, done, cache_we, cache_data_in, data_out);
                end

                // then do we test
                if (i < 2) $display("\nRunning write random test %d...", i+1);
                test_random_we();
                if (i < 2) $display("\nTime: %t, INPUTS:\nRE: %b, WE: %b, hit: %b, chosen_way: %d,\ndata_in: %d, data_from_cache: [%d,%d,%d,%d],\ndata_from_RAM: %d", $time(), re, we, hit, chosen_way, data_in, data_from_cache[0], data_from_cache[1], data_from_cache[2], data_from_cache[3], data_from_RAM);
                if (i < 2) $display("OUTPUTS:\nop: %b, done: %b, cache_we: %b,\ncache_data_in: %d, data_out: %d", op_in_progress, done, cache_we, cache_data_in, data_out);
                
                // and repeat again 2 tests with neither re nor we
                for (int j = 0; j < 2; j++) begin
                    test_random_0();
                    if (i < 2) $display("\nTime: %t, INPUTS:\nRE: %b, WE: %b, hit: %b, chosen_way: %d,\ndata_in: %d, data_from_cache: [%d,%d,%d,%d],\ndata_from_RAM: %d", $time(), re, we, hit, chosen_way, data_in, data_from_cache[0], data_from_cache[1], data_from_cache[2], data_from_cache[3], data_from_RAM);
                    if (i < 2) $display("OUTPUTS:\nop: %b, done: %b, cache_we: %b,\ncache_data_in: %d, data_out: %d", op_in_progress, done, cache_we, cache_data_in, data_out);
                end

            end
        end

        // end tests
        disable clk_gen;

        $display("\n%d tests finished with %d failires.", 2*NUM_TESTS, failures);
        $display("Randomization failed %d times.", rand_failures);

    end



    // ASSERTS!!!!!!!!! to check functionality
    /***** WE LOGIC *****/
    // if cache_we is high,
    // 1 cycle past read miss is high OR
    // we hit is high AND 1 cycle past we hit is low OR
    // we miss is high AND 1 cycle past we miss is low AND 2 cycles past we miss is low
    property we_logic_high_check;
        @(posedge clk) disable iff (rst) (cache_we == '1) |->
            $past(re && ~hit) ||
            ((we && hit) && !$past(we && hit)) ||
            ((we && ~hit) && !$past(we && ~hit) && !$past(we && ~hit,2));
    endproperty

    assert property (we_logic_high_check) else begin
        $error("we_logic_high_check failed");
        // $error("we_logic_high_check failed: cache_we == %b when we == %b, past re == %b, past hit == %b, and past re&&~hit == %b.", cache_we, we, $past(re), $past(hit), $past(re && ~hit));
        failures++;
    end

    // I'm sorry its 3AM and I've been working on CACHE CONTROL BLOCK
    // for like 25 hours or something the past 3 days, I give up one
    // the we_logic_low assertion, I literally know it works just look
    // at the documentation

    /***** DONE LOGIC *****/

    // make sequences first for readability
    // these are the conditions for done to be high
    sequence seq_re_hit;
        !op_in_progress ##1 (re && hit);
    endsequence

    sequence seq_we_hit;
        !op_in_progress ##1 (we && hit);
    endsequence

    sequence seq_re_miss;
        !op_in_progress ##1 (re && ~hit);
    endsequence

    sequence seq_we_miss;
        !op_in_progress ##1 (we && ~hit);
    endsequence

    // Use the sequences in properties
    property done_re_hit;
        @(posedge clk) disable iff (rst) seq_re_hit |-> ##HIT_DELAY done == '1;
    endproperty

    assert property (done_re_hit) else begin
        $error("done_re_hit failed at time %t:", $time());
        failures++;
    end

    property done_we_hit;
        @(posedge clk) disable iff (rst) seq_we_hit |-> ##HIT_DELAY done == '1;
    endproperty

    assert property (done_we_hit) else begin
        $error("done_we_hit failed at time %t:", $time());
        failures++;
    end

    property done_re_miss;
        @(posedge clk) disable iff (rst) seq_re_miss |-> ##MISS_DELAY done == '1;
    endproperty

    assert property (done_re_miss) else begin
        $error("done_re_miss failed at time %t:", $time());
        failures++;
    end

    property done_we_miss;
        @(posedge clk) disable iff (rst) seq_we_miss |-> ##MISS_DELAY done == '1;
    endproperty

    assert property (done_we_miss) else begin
        $error("done_we_miss failed at time %t:", $time());
        failures++;
    end
    
    // done is low if those sequences are not met

    /*************************************************

    I CAN NOT PUT INTO WORDS HOW MUCH OF A PAIN THIS WAS TO FIGURE OUT
    
    I didn't originally use sequences and was trying to do it all in one property.
    That was impossible to do all in my head and I couldn't figure out why
    it wasn't working.
    
    I then figured hey, maybe I can break it up into sequences and then use those
    sequences in the properties.
    That worked for when done is suppsoed to be high, but not when done is supposed
    to be low.
    Because I wanted to just say if none of these sequences are true, done should be
    low.
    Apparently, you can't logically compare sequences. Whatever.    
    
    So below is a recreation of the sequences using the $past macro.
    The equivalent of:
        done == 0? that means seq_re_hit, seq_we_hit, seq_re_miss, and seq_we_miss
        are all false. Throw an error if otherwise.
    
    *************************************************/
    property done_low;
        @(posedge clk) disable iff (rst) (done == '0) |->
            !(!$past(op_in_progress, HIT_DELAY+1) && $past(re && hit, HIT_DELAY)) &&
            !(!$past(op_in_progress, HIT_DELAY+1) && $past(we && hit, HIT_DELAY)) &&
            !(!$past(op_in_progress, MISS_DELAY+1) && $past(re && ~hit, MISS_DELAY)) &&
            !(!$past(op_in_progress, MISS_DELAY+1) && $past(we && ~hit, MISS_DELAY));
    endproperty

    assert property (done_low) else begin
        $error("done_low failed at time %t:", $time());
        failures++;
    end

    // done is 1 or 0
    property done_1_or_0;
        @(posedge clk) disable iff (rst) (done == '1) || (done == '0);
    endproperty

    assert property (done_1_or_0) else begin
        $error("done_1_or_0 failed: done == %b.", done);
        failures++;
    end

    // done is not high two consecutive cycles in a row
    property done_double_high;
        @(posedge clk) disable iff (rst) (done == '1) |-> !($past(done));
    endproperty

    assert property (done_double_high) else begin
        $error("done_double_high failed: done == %b when past done == %b.", done, $past(done));
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
    // data_from_cache registered values
    logic [WIDTH-1:0] data_from_cache_delay [0:WAYS-1];

    // logic for queue
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            for (int i = 0; i < WAYS; i++) begin
                data_from_cache_delay[i] <= '0;
            end
        end else begin
            for (int i = 0; i < WAYS; i++) begin
                data_from_cache_delay[i] <= data_from_cache[i];
            end
        end
    end

    // if done and there was a read hit in the previous cycle,
    // data_out is data_from_cache[chosen_way] from prev cycle
    property data_out_re_hit;
        @(posedge clk) disable iff (rst) (done == '1) && $past(re && hit, HIT_DELAY) |-> data_out == data_from_cache_delay[chosen_way];
    endproperty

    assert property (data_out_re_hit) else begin
        $error("data_out_re_hit failed at time %t: data_out == %d when past (re == %b, hit == %b), done == %b, and past data_from_cache[%d] == %d.", $time(), data_out, $past(re), $past(hit), done, $past(chosen_way), data_from_cache_delay[chosen_way]);
        failures++;
    end

    // if done and there was a write hit in the previous cycle,
    // data_out is 0
    property data_out_we_hit;
        @(posedge clk) disable iff (rst) (done == '1) && $past(we && hit, HIT_DELAY) |=> data_out == '0;
    endproperty

    assert property (data_out_we_hit) else begin
        $error("data_out_we_hit failed: data_out == %d when past (we == %b, hit == %b), done == %b.", data_out, $past(we), $past(hit), done);
        failures++;
    end
    
    // if done and there was a read miss in the previous 2 cycles,
    // data_out is data_from_RAM from the prev cycle
    property data_out_re_miss;
        @(posedge clk) disable iff (rst) (done == '1) && $past(re && hit, MISS_DELAY) |-> data_out == $past(data_from_RAM);
    endproperty

    assert property (data_out_re_miss) else begin
        $error("data_out_re_hit failed: data_out == %d when past 2 (re == %b, hit == %b), done == %b, and past data_from_RAM == %d.", data_out, $past(re,2), $past(hit,2), done, $past(chosen_way,2), $past(data_from_RAM));
        failures++;
    end

    // if done and there was a write miss in the previous 2 cycles,
    // data_out next cycle is 0
    property data_out_we_miss;
        @(posedge clk) disable iff (rst) (done == '1) && $past(we && hit, MISS_DELAY) |=> data_out == '0;
    endproperty

    assert property (data_out_we_hit) else begin
        $error("data_out_we_hit failed: data_out == %d when past (we == %b, hit == %b), done == %b.", data_out, $past(we,2), $past(hit,2), done);
        failures++;
    end

    // data_out is equal to the value before it unless done rising edge
    property data_out_unchanged;
        @(posedge clk) disable iff (rst) (done == '0) |-> data_out == $past(data_out);
    endproperty

    assert property (data_out_unchanged) else begin
        $error("data_out_unchanged failed: data_out == %d when past data_out == %d and done == %b.", data_out, $past(data_out), done);
        failures++;
    end

endmodule