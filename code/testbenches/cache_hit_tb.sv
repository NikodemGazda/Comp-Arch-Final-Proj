`include "cache_hit.sv"

class cache_hit_transaction #(parameter WAYS=4, parameter TOTAL_SIZE=16, parameter RAM_DEPTH=256);

    // signals
    rand logic [$clog2(RAM_DEPTH)-1-$clog2(TOTAL_SIZE/WAYS):0] target_tag;
    rand logic [$clog2(RAM_DEPTH)-1-$clog2(TOTAL_SIZE/WAYS):0] tags [0:WAYS-1];
    rand logic valid_bits [0:WAYS-1];
    rand logic [$clog2(WAYS)-1:0] lru_way;

    // this randomization requires we use other random variable for constraints.
    // these must be randomized before the actual DUT signals
    rand int random_choice;
    rand int random_choice_2;
    rand int random_choice_3;
    constraint solve_order {
        random_choice inside {[0:1]};
        random_choice_2 inside {[0:3]};
        random_choice_3 inside {[0:1]};
        solve random_choice before target_tag, tags, valid_bits, lru_way;
        solve random_choice_2 before target_tag, tags, valid_bits, lru_way;
        solve random_choice_3 before target_tag, tags, valid_bits, lru_way;
    }

    // actual constraints

    // make sure target tag, lru way, and tags are 0 10% of the time, 1 10% of the time,
    // and everything else 80% of the time
    constraint target_tag_ranges { target_tag dist{'0 :/ 10, '1 :/ 10, [1:RAM_DEPTH/(TOTAL_SIZE/WAYS)-2] :/ 80}; }
    constraint lru_way_ranges { lru_way dist{'0 :/ 10, '1 :/ 10, [1:TOTAL_SIZE/WAYS-2] :/ 80}; }
    constraint tags_ranges {
        foreach (tags[i]) {
            tags[i] dist { '0 :/ 10, '1 :/ 10, [1:RAM_DEPTH/(TOTAL_SIZE/WAYS)-2] :/ 80 };
        }
    }
    
    // none of the tags in the tag array should ever match
    constraint tags_never_same {
        foreach (tags[i]) {
            foreach (tags[j]) {
                if (i != j) {
                    tags[i] != tags[j];
                }
            }
        }
    }

    // 50% of the time, one of the tags will match the target tag, the other 50%, none should match
    constraint target_tag_match {
        if (random_choice == 0) {
            tags[random_choice_2] == target_tag;
            if (random_choice_3 == 0) {
                valid_bits[random_choice_2] == 1'b1;
            } else {
                valid_bits[random_choice_2] == 1'b0;
            }
        } else {
            foreach (tags[i]) {
                tags[i] != target_tag;
            }
        }
    }

endclass

module cache_hit_tb;

    // constants
    localparam int NUM_DIRECTED = 0;
    localparam int NUM_TESTS = 100;
    localparam int WAYS = 4;
    localparam int TOTAL_SIZE = 16;
    localparam int RAM_DEPTH = 256;
    localparam int WIDTH = 8;

    // signals
    // general
    logic clk, rst;
    // inputs
    logic [$clog2(RAM_DEPTH)-1-$clog2(TOTAL_SIZE/WAYS):0] target_tag;
    logic [$clog2(RAM_DEPTH)-1-$clog2(TOTAL_SIZE/WAYS):0] tags [0:WAYS-1];
    logic valid_bits [0:WAYS-1];
    logic [$clog2(WAYS)-1:0] lru_way;
    // outputs
    logic hit;
    logic [$clog2(WAYS)-1:0] chosen_way;

    // instantiate DUT
    cache_hit #(.WAYS(WAYS), .TOTAL_SIZE(TOTAL_SIZE), .RAM_DEPTH(RAM_DEPTH), .WIDTH(WIDTH)) DUT (.*);

    // generate clock
    initial begin : clk_gen
        clk = '0;
        while (1) #5 clk = ~clk;
    end

    // reset inputs
    task reset();
        // assert reset and set other signals low
        rst = '1;
        target_tag = '0;
        for (int i = 0; i < WAYS; i++) begin
            tags[i] = '0;
            valid_bits[i] = '0;
        end
        lru_way = '0;

        // wait a couple cycles
        for (int i = 0; i < 5; i++)
            @(posedge clk);

        // deassert reset
        @(negedge clk);
        rst <= '0;
        @(posedge clk);

    endtask

    // directed tests
    // test 1: all tags are 0, 1, 2, 3, target tag is 0, valid bits are 0, lru way is 0
    // should return miss and chosen way should be 0

    // test 2: all tags are 0, 1, 2, 3, target tag is 0, valid bits are 0, lru way is 1
    // should return miss and chosen way should be 1

    // test 3: all tags are 0, 1, 2, 3, targt tag is 0, valid bits are 1, lru way is 2
    // should return hit and chosen way should be 0

    // test 4: all tags are 0, 1, 2, 3, targt tag is 1, valid bits are 1, lru way is 3
    // should return hit and chosen way should be 1

    // test 5: all inputs are 0s
    // should return miss and chosen way should be 0

    // test 6: all inputs are 1s
    // should return hit and chosen way should be 0

    task direct_tests(int num_loop=0);

        // test 1
        if (num_loop < 1) $display("Test 1 at time %0t", $time);
        target_tag = 0;
        for (int i = 0; i < WAYS; i++) begin
            tags[i] = i;
            valid_bits[i] = 0;
        end
        lru_way = 0;
        @(posedge clk);
        @(negedge clk);
        if (num_loop < 1) $display("hit: %b, chosen_way: %d", hit, chosen_way);

        // test 2
        if (num_loop < 1) $display("Test 2 at time %0t", $time);
        target_tag = 0;
        for (int i = 0; i < WAYS; i++) begin
            tags[i] = i;
            valid_bits[i] = 0;
        end
        lru_way = 1;
        @(posedge clk);
        @(negedge clk);
        if (num_loop < 1) $display("hit: %b, chosen_way: %d", hit, chosen_way);

        // test 3
        if (num_loop < 1) $display("Test 3 at time %0t", $time);
        target_tag = 0;
        for (int i = 0; i < WAYS; i++) begin
            tags[i] = i;
            valid_bits[i] = 1;
        end
        lru_way = 2;
        @(posedge clk);
        @(negedge clk);
        if (num_loop < 1) $display("hit: %b, chosen_way: %d", hit, chosen_way);

        // test 4
        if (num_loop < 1) $display("Test 4 at time %0t", $time);
        target_tag = 1;
        for (int i = 0; i < WAYS; i++) begin
            tags[i] = i;
            valid_bits[i] = 1;
        end
        lru_way = 3;
        @(posedge clk);
        @(negedge clk);
        if (num_loop < 1) $display("hit: %b, chosen_way: %d", hit, chosen_way);

        // test 5
        if (num_loop < 1) $display("Test 5 at time %0t", $time);
        target_tag = 0;
        for (int i = 0; i < WAYS; i++) begin
            tags[i] = 0;
            valid_bits[i] = 0;
        end
        lru_way = 0;
        @(posedge clk);
        @(negedge clk);
        if (num_loop < 1) $display("hit: %b, chosen_way: %d", hit, chosen_way);

        // test 6
        if (num_loop < 1) $display("Test 6 at time %0t", $time);
        target_tag = 1;
        for (int i = 0; i < WAYS; i++) begin
            tags[i] = 1;
            valid_bits[i] = 1;
        end
        lru_way = 1;
        @(posedge clk);
        @(negedge clk);
        if (num_loop < 1) $display("hit: %b, chosen_way: %d", hit, chosen_way);

    endtask

    // create ram_transaction object
    cache_hit_transaction #(.WAYS(WAYS), .TOTAL_SIZE(TOTAL_SIZE), .RAM_DEPTH(RAM_DEPTH)) item;

    // track failures
    int failures = 0; 
    int rand_failures = 0; 
    int num_matches = 0; 
    int num_hits = 0; 

    // drive inputs
    initial begin : drive_inputs

        // display that ram tb starting
        $display("\nStarting Cache valid testbench...");

        // reset DUT
        $display("\nResetting DUT...");
        reset();
        $display("Reset DUT.");

        // run directed tests
        if (NUM_DIRECTED > 0) $display("\nRunning directed tests...");
        for (int i = 0; i < NUM_DIRECTED; i++) begin
            direct_tests(i);
        end

        // create ram_transaction object
        item = new();

        // start tests
        $display("\nRunning random tests...");
        for (int i = 0; i < NUM_TESTS; i++) begin

            // assign random values
            if (item.randomize() == 0) begin 
                $error("Randomization failed");
                rand_failures++;
            end

            // assign to actual pins
            target_tag = item.target_tag;
            lru_way = item.lru_way;
            // assign array elements
            for (int j = 0; j < WAYS; j++) begin
                tags[j] = item.tags[j];
                valid_bits[j] = item.valid_bits[j];
            end

            // display inputs
            if (i < 8 && i > 2) begin
                $display("\nTest %d at time %0t", i-2, $time);
                $display("target_tag: %d", target_tag);
                $display("lru_way: %d", lru_way);
                $display("tags: [%d, %d, %d, %d]", tags[0], tags[1], tags[2], tags[3]);
                $display("valid_bits: [%d, %d, %d, %d]", valid_bits[0], valid_bits[1], valid_bits[2], valid_bits[3]);
            end

            // wait for posedge
            @(posedge clk);
            @(negedge clk);

            if (i < 8 && i > 2) begin
                $display("hit: %b, chosen_way: %d", hit, chosen_way);
            end
        end

        // end tests
        disable clk_gen;
        $display("\n%d tests finished with %d failires.", NUM_TESTS+6*NUM_DIRECTED, failures);
        $display("Randomization failed %d times.", rand_failures);
        $display("Tags matches target tag %d times.", num_matches);
        $display("Number of hits: %d", num_hits);

    end

    // constraint checker for target tag matching one of the input tags 50% of the time
    always_comb begin
        for (int i = 0; i < WAYS; i++) begin
            if (tags[i] == target_tag) begin
                num_matches++;
            end
        end
    end

    // constraint checker for number of hits
    always_comb begin
        for (int i = 0; i < WAYS; i++) begin
            if (hit) begin
                num_hits++;
            end
        end
    end

    // ASSERTS!!!!!!!!! to check functionality
    logic any_matches;
    always_comb begin
        any_matches = 0;
        for (int i = 0; i < WAYS; i++) begin
            if (valid_bits[i] && (tags[i] == target_tag)) begin
                any_matches = 1;
            end
        end
    end

    property miss_check;
        @(negedge clk) disable iff (rst) !hit |-> chosen_way == lru_way;
    endproperty

    property hit_check;
        @(negedge clk) disable iff (rst) hit |-> tags[chosen_way] == target_tag;
    endproperty

    property tags_match;
        @(negedge clk) disable iff (rst) any_matches |-> hit;
    endproperty

    property no_tags_match;
        @(negedge clk) disable iff (rst) !any_matches |-> !hit;
    endproperty

    assert property (miss_check) else begin
        $error("ERROR: miss detected but chosen_way=%d and lru_way=%d", chosen_way, lru_way);
        failures++;
    end

    assert property (hit_check) else begin
        $error("ERROR: hit detected but chosen way=%d, tags[%d]=%d and target_tag=%d", chosen_way, chosen_way, tags[chosen_way], target_tag);
        failures++;
    end

    assert property (tags_match) else begin
        $error("ERROR: tags match but hit=%b", hit);
        failures++;
    end

    assert property (no_tags_match) else begin
        $error("ERROR: tags don't match but hit=%b", hit);
        failures++;
    end


endmodule