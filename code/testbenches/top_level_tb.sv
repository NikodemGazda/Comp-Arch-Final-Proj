class top_level_transaction #(parameter WIDTH=8, parameter RAM_DEPTH=256);

    // signals
    rand logic we, re;
    rand logic [$clog2(RAM_DEPTH)-1:0] addr;
    rand logic [WIDTH-1:0] data_in;

    // constraints

    // make sure index is 0 10% of the time, 1 10% of the time,
    // and everything else 80% of the time
    constraint data_in_ranges { data_in dist{'0 :/ 10, '1 :/ 10, [1:(2**WIDTH)-2] :/ 80}; }

    // re and we should never be 1 or 0 at the same time
    constraint re_we_not_and { (re ^ we); }

endclass

module top_level_tb;

    // constants
    localparam int NUM_DIRECTED_TESTS = 0;
    localparam int NUM_TESTS = 100;
    localparam int WIDTH = 8;
    localparam int WAYS = 4;
    localparam int TOTAL_SIZE = 16;
    localparam int RAM_DEPTH = 256;
    string message = "This cache/RAM has been implemented in SystemVerilog and features a RAM (of parameterized size) and an N-set associative cache, configurable at compile time, with the replacement strategy being last recently used, demonstrating a complete functional model.";
    string response = "";

    // assertion constants
    localparam int HIT_DELAY = 2;
    localparam int MISS_DELAY = 3;

    // track failures and tests
    int total_tests = 0;
    int failures = 0; 
    int rand_failures = 0; 

    // signals
    // general
    logic clk, rst;
    // inputs
    logic we, re;
    logic [$clog2(RAM_DEPTH)-1:0] addr;
    logic [WIDTH-1:0] data_in;
    // outputs
    logic op_in_progress, done;
    logic [WIDTH-1:0] data_out;

    // instantiate DUT
    top_level #(
        .WIDTH(WIDTH),
        .WAYS(WAYS),
        .TOTAL_SIZE(TOTAL_SIZE),
        .RAM_DEPTH(RAM_DEPTH)
    ) DUT (.*);

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
        data_in = '0;
        addr = '0;

        // wait a couple cycles
        for (int i = 0; i < 5; i++)
            @(posedge clk);

        // deassert reset
        @(negedge clk);
        rst <= '0;
        @(posedge clk);

    endtask

    // directed testcases:
    // Test 1: write to every RAM address and then read from every RAM address
    // - tests for write misses and read misses
    // Test 2: immediately write twice and read for every RAM address
    // - tests for write hits and read hits
    // Test 3: Writes the following message to the RAM and then reads it back,
    //         concatenating each byte to a string and printing it to the console:
    // 
    //      This cache/RAM has been implemented in SystemVerilog and features
    //      a RAM (of parameterized size) and an N-set associative cache,
    //      configurable at compile time, with the replacement strategy being
    //      last recently used, demonstrating a complete functional model.

    task directed_test_1();

        // display testing info
        $display("\nStarting Directed Test 1...");
        $display("\nStarting Write Tests!!!");

        // write to every RAM address
        for (int i = 0; i < RAM_DEPTH; i++) begin

            // set inputs
            addr = i;
            data_in = i;
            we = '1;
            re = '0;
            
            // testing info for first 5 writes
            if (i < 5) $display("\nTime: %t, INPUTS:\nRE: %b, WE: %b,\nADDR: %d, DATA_IN: %d", $time(), re, we, addr, data_in);
            // #1;
            // if (i < 5) $display("new_operation: %b, RE_R, WE_R: %b, %b", DUT.cache_top_inst.new_operation, DUT.cache_top_inst.re_r, DUT.cache_top_inst.we_r);
            // if (i < 5)$display("First posedge approaching:\n");
            // wait until done is high
            for (int j = 0; j < 4; j++) begin

                @(posedge clk);

                // unset we because we || re signals a new operation
                we = '0;

                // display all outputs for first 5 writes
                #1;
                // if (i < 5) $display("\nTime: %t, INPUTS:\nRE: %b, WE: %b,\nADDR: %d, DATA_IN: %d", $time(), re, we, addr, data_in);
                if (i < 5) $display("Time: %t,\nOUTPUTS:\nOP: %b, DONE: %b, DATA_OUT: %d", $time(), op_in_progress, done, data_out);
                // if (i < 5) $display("new_operation: %b, RE_R, WE_R: %b, %b", DUT.cache_top_inst.new_operation, DUT.cache_top_inst.re_r, DUT.cache_top_inst.we_r);

                // check for done 
                // if (done == '1);
            end

            // wait one more cycle for done to clear
            @(posedge clk);
        end

        // read from every RAM address
        $display("\nStarting Read Tests!!!");
        for (int i = 0; i < RAM_DEPTH; i++) begin

            // set inputs
            addr = i;
            data_in = '0;
            we = '0;
            re = '1;

            // testing info for first 5 reads
            if (i < 5) $display("\nTime: %t, INPUTS:\nRE: %b, WE: %b,\nADDR: %d, DATA_IN: %d", $time(), re, we, addr, data_in);
            // #1;
            // if (i < 5) $display("new_operation: %b, RE_R, WE_R: %b, %b", DUT.cache_top_inst.new_operation, DUT.cache_top_inst.re_r, DUT.cache_top_inst.we_r);
            // if (i < 5)$display("First posedge approaching:\n");

            // wait until done is high
            for (int j = 0; j < 4; j++) begin

                @(posedge clk);

                // unset we because we || re signals a new operation
                re = '0;

                // display all outputs for first 5 reads
                #1;
                // if (i < 5) $display("\nTime: %t, INPUTS:\nRE: %b, WE: %b,\nADDR: %d, DATA_IN: %d", $time(), re, we, addr, data_in);
                if (i < 5) $display("Time: %t,\nOUTPUTS:\nOP: %b, DONE: %b, DATA_OUT: %d", $time(), op_in_progress, done, data_out);
                // if (i < 5) $display("read miss pipe: [%b, %b, %b]",
                //     DUT.cache_top_inst.cache_control_inst.logic_done_inst.read_miss_delay.mem[0],
                //     DUT.cache_top_inst.cache_control_inst.logic_done_inst.read_miss_delay.mem[1],
                //     DUT.cache_top_inst.cache_control_inst.logic_done_inst.read_miss_delay.mem[2]);
                // if (i < 5) $display("read hit pipe: [%b, %b]",
                //     DUT.cache_top_inst.cache_control_inst.logic_done_inst.read_hit_delay.mem[0],
                //     DUT.cache_top_inst.cache_control_inst.logic_done_inst.read_hit_delay.mem[1]);
                // if (i < 5) $display("new_operation: %b, RE_R, WE_R: %b, %b", DUT.cache_top_inst.new_operation, DUT.cache_top_inst.re_r, DUT.cache_top_inst.we_r);

                // check for done 
                // if (done == '1) break;
            end

            // testing info for first 5 reads
            // if (i < 5) $display("\nTime: %t, READING: %d from ADDR: %d", $time(), data_out, addr);

            // wait one more cycle for done to clear
            @(posedge clk);
        end

    endtask

    task directed_test_2();

        // display testing info
        $display("\nStarting Directed Test 2...");

        // testing every RAM address
        for (int i = 0; i < RAM_DEPTH; i++) begin

            // write twice to every RAM address
            // first is write miss
            if (i < 5) $display("\nStarting Write Miss...");
            // set inputs
            addr = i;
            data_in = i;
            we = '1;
            re = '0;

            // read inputs for write miss
            if (i < 5) $display("\nTime: %t, INPUTS:\nRE: %b, WE: %b,\nADDR: %d, DATA_IN: %d", $time(), re, we, addr, data_in);

            for (int j = 0; j < 4; j++) begin

                @(posedge clk);

                // unset we because we || re signals a new operation
                we = '0;

                // display all outputs for first 5 writes
                #1;
                if (i < 5) $display("Time: %t,\nOUTPUTS:\nOP: %b, DONE: %b, DATA_OUT: %d", $time(), op_in_progress, done, data_out);

                // check for done 
                if (done == '1) begin
                    if (i < 5) begin
                        $display("Last hit/miss, r/w: %b, %b", last_hit_miss, last_r_w);
                        $display("REF MODEL:");
                        for (int i = 0; i < TOTAL_SIZE/WAYS; i++) begin
                            for (int j = 0; j < WAYS; j++) begin
                                $display("ref_model[%d][%d]: %d", j, i, ref_model[j][i]);
                            end
                        end
                    end
                    break;
                end
            end

            // wait one more cycle for done to clear
            @(posedge clk);

            // next is write hit
            if (i < 5) $display("\nStarting Write Hit...");
            // set inputs
            addr = i;
            data_in = i+1;
            we = '1;
            re = '0;

            // read inputs for write miss
            if (i < 5) $display("\nTime: %t, INPUTS:\nRE: %b, WE: %b,\nADDR: %d, DATA_IN: %d", $time(), re, we, addr, data_in);

            for (int j = 0; j < 4; j++) begin

                @(posedge clk);

                // unset we because we || re signals a new operation
                we = '0;

                // display all outputs for first 5 writes
                #1;
                if (i < 5) $display("Time: %t,\nOUTPUTS:\nOP: %b, DONE: %b, DATA_OUT: %d", $time(), op_in_progress, done, data_out);

                // check for done 
                if (done == '1) begin
                    if (i < 5) begin
                        $display("Last hit/miss, r/w: %b, %b", last_hit_miss, last_r_w);
                        $display("REF MODEL:");
                        for (int i = 0; i < TOTAL_SIZE/WAYS; i++) begin
                            for (int j = 0; j < WAYS; j++) begin
                                $display("ref_model[%d][%d]: %d", j, i, ref_model[j][i]);
                            end
                        end
                    end
                    break;
                end
            end

            // wait one more cycle for done to clear
            @(posedge clk);

            // now read from the address
            if (i < 5) $display("\nStarting Read Hit...");
            // set inputs
            addr = i;
            data_in = '0;
            we = '0;
            re = '1;

            // read inputs for write miss
            if (i < 5) $display("\nTime: %t, INPUTS:\nRE: %b, WE: %b,\nADDR: %d, DATA_IN: %d", $time(), re, we, addr, data_in);

            for (int j = 0; j < 4; j++) begin

                @(posedge clk);

                // unset we because we || re signals a new operation
                re = '0;

                // display all outputs for first 5 writes
                #1;
                if (i < 5) $display("Time: %t,\nOUTPUTS:\nOP: %b, DONE: %b, DATA_OUT: %d", $time(), op_in_progress, done, data_out);

                // check for done 
                if (done == '1) begin
                    if (i < 5) begin
                        $display("Last hit/miss, r/w: %b, %b", last_hit_miss, last_r_w);
                        $display("REF MODEL:");
                        for (int i = 0; i < TOTAL_SIZE/WAYS; i++) begin
                            for (int j = 0; j < WAYS; j++) begin
                                $display("ref_model[%d][%d]: %d", j, i, ref_model[j][i]);
                            end
                        end
                    end
                    break;
                end
            end

            // wait one more cycle for done to clear
            @(posedge clk);

        end

    endtask

    task directed_test_3();
        
        // display testing info
        $display("\nStarting Directed Test 3...");
        $display("\nStarting Write Tests!!!");

        // write to every RAM address
        $display("Writing the following message:");

        for (int i = 0; i < message.len(); i++) begin
            // print new line every 52 characters
            if (i%52 == 0) $display();            

            $write("%c", message[i]);
        end

        for (int i = 0; i < RAM_DEPTH; i++) begin

            // set inputs
            addr = i;
            data_in = message[i];
            we = '1;
            re = '0;
            
            for (int j = 0; j < 4; j++) begin

                @(posedge clk);

                // unset we because we || re signals a new operation
                we = '0;

                // check for done 
                #1 if (done == '1) break;

            end

            // wait one more cycle for done to clear
            @(posedge clk);
        end

        // read from every RAM address
        $display("\nStarting Read Tests!!!");
        for (int i = 0; i < RAM_DEPTH; i++) begin

            // set inputs
            addr = i;
            data_in = '0;
            we = '0;
            re = '1;

            for (int j = 0; j < 4; j++) begin

                @(posedge clk);

                // unset we because we || re signals a new operation
                re = '0;

                // check for done 
                #1;
                if (done == '1) begin
                    // response.putc(response.len(), data_out);
                    response = {response, data_out};
                    break;
                end
            end

            // wait one more cycle for done to clear
            @(posedge clk);
        end

        // display returned message
        $display("Reading the following response:");

        for (int i = 0; i < response.len(); i++) begin
            // print new line every 52 characters
            if (i%52 == 0) $display();            

            $write("%c", response[i]);
        end
    endtask

    // Random test write enable:
    task test_random(int test_num=1);

        // declaring the transaction objects
        top_level_transaction #(.WIDTH(WIDTH), .RAM_DEPTH(RAM_DEPTH)) item;

        item = new();

        for (int i = 0; i < NUM_TESTS; i++) begin

            // print test num
            $display("\nStarting Random Test %d...", i);

            if (item.randomize() == 0) begin 
                $error("Randomization failed");
                rand_failures++;
            end

            // assign pins
            re = item.re;
            we = item.we;
            addr = item.addr;
            data_in = item.data_in;

            // print first 5 testcase
            // if (test_num < 5) $display("Time: %t,\nINPUTS: RE: %b, WE: %b, ADDR: %d, DATA_IN: %d", $time(), re, we, addr, data_in);
            $display("Time: %t,\nINPUTS: RE: %b, WE: %b, ADDR: %d, DATA_IN: %d", $time(), re, we, addr, data_in);

            // waiting on clock and done signal
            for (int j = 0; j < 4; j++) begin

                @(posedge clk);

                // unset we and re because we || re signals a new operation
                we = '0;
                re = '0;

                // check for done 
                #1
                $display("Time: %t,\nOUTPUTS: OP: %b, DONE: %b, DATA_OUT: %d", $time(), op_in_progress, done, data_out);
                if (i > 45 && i < 70) $display("RE_R and WE_R: %b, %b", DUT.cache_top_inst.re_r, DUT.cache_top_inst.we_r);
                if (i > 45 && i < 70) $display("LRU contents: [%d, %d, %d, %d]",
                    DUT.cache_top_inst.cache_lru_inst.last_used[0][1],
                    DUT.cache_top_inst.cache_lru_inst.last_used[1][1],
                    DUT.cache_top_inst.cache_lru_inst.last_used[2][1],
                    DUT.cache_top_inst.cache_lru_inst.last_used[3][1]);
                if (i > 45 && i < 70) $display("Cache Tag contents: [%d, %d, %d, %d]",
                    DUT.cache_top_inst.cache_tag_inst.tags[0][1],
                    DUT.cache_top_inst.cache_tag_inst.tags[1][1],
                    DUT.cache_top_inst.cache_tag_inst.tags[2][1],
                    DUT.cache_top_inst.cache_tag_inst.tags[3][1]);
                
                if (done == '1) begin
                    break;
                end
            end
            @(posedge clk);
        end
        
    endtask


    // drive inputs
    initial begin : drive_inputs

        // display that ram tb starting
        $display("\nStarting Top-Level testbench...");

        // reset DUT
        $display("\nResetting DUT...");
        reset();
        $display("Reset DUT.");

        // directed tests
        if (NUM_DIRECTED_TESTS > 0) begin
            $display("\nStarting Directed Tests...");

            directed_test_1();
            
            $display("\nDirected Test 1 finished. Staring Directed Test 2.");
            
            directed_test_2();
            
            $display("\nDirected Test 2 finished. Staring Directed Test 3.");

            directed_test_3();
        end

        // Random tests
        test_random();

        // end tests
        disable clk_gen;

        // display results
        if (NUM_DIRECTED_TESTS > 0) begin
            // directed test 1 has 256 writes and 256 reads
            total_tests += 256*2;
            // directed test 2 does two writes and a read 256 times
            total_tests += 256*3;
            // directed test 3 does 256 writes and 256 reads to write and read the message
            total_tests += 256*2;
        end

        // random tests
        if (NUM_TESTS > 0) begin
            total_tests += NUM_TESTS;
        end
        $display("\n%d tests finished with %d failires.", total_tests, failures);
        $display("Randomization failed %d times.", rand_failures);

    end

    // reference models and all extra signals needed for assertions

    // to store data for address
    logic [WIDTH-1:0] ref_data [0:RAM_DEPTH-1];

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            for (int i = 0; i < RAM_DEPTH; i++) begin
                ref_data[i] <= '0;
            end
        end else if (we) begin
            ref_data[addr] <= data_in;
        end
    end

    // index from address
    logic [$clog2(TOTAL_SIZE/WAYS)-1:0] index_from_addr;
    assign index_from_addr = addr[$clog2(TOTAL_SIZE/WAYS)-1:0];

    // reference model to track LRU address for each index
    //        addr bit width    |     number of ways per index  |   number of indices
    logic [$clog2(RAM_DEPTH)-1:0] ref_model    [0:WAYS-1]         [0:TOTAL_SIZE/WAYS-1];
    
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            for (int i = 0; i < WAYS; i++) begin
                for (int j = 0; j < TOTAL_SIZE/WAYS; j++) begin
                    ref_model[i][j] <= '0;  
                end
            end
        // every time done is high,
        end else if (done) begin
            // shift every index's LRU value to the right once (rightmost gets dropped)
            // and then make the most recent LRU value equal to the address that's currently input
            for (int i = 1; i < WAYS; i++) begin
                ref_model[i][index_from_addr] <= ref_model[i-1][index_from_addr];
            end
            ref_model[0][index_from_addr] <= addr;
            
            // UNLESS that address is already in the bufffer, in which case,
            // that address still goes into the most recently used slot, but the
            // other spot that that was supposed to go in just doesn't get a new value
            // but since i don't really know how to use variables in synchronous SV,
            // it's gonna be complicated
            for (int i = 0; i < WAYS-1; i++) begin
                if (ref_model[i][index_from_addr] == addr) begin
                    for (int j = i+1; j < WAYS; j++) begin
                        ref_model[j][index_from_addr] <= ref_model[j][index_from_addr];
                    end
                    break;
                end
            end 
        end
    end

    // last operation
    logic last_r_w; // 0 for read, 1 for write
    logic last_hit_miss; // 0 for hit, 1 for miss
    logic [$clog2(RAM_DEPTH)-1:0] last_addr; // 0 for hit, 1 for miss

    // track last operation
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            last_r_w <= '0;
            last_hit_miss <= '0;
            last_addr <= '0;
        end else if (we || re) begin
            // if the address is in the buffer, it's a hit
            if ((ref_model[0][index_from_addr] == addr) || 
                (ref_model[1][index_from_addr] == addr) ||
                (ref_model[2][index_from_addr] == addr) ||
                (ref_model[3][index_from_addr] == addr)) begin
                    last_hit_miss <= '0;
            end else begin
                // if the address is not in the buffer, it's a miss
                last_hit_miss <= '1;
            end

            // update last_r_w
            if (re) begin
                last_r_w <= '0;
            end else if (we) begin
                last_r_w <= '1;
            end
            
            // update last addr
            last_addr <= addr;
        end
    end

    // ASSERTS!!!!!!!!! to check functionality

    // out_correct_check: This assertion checks that when the done signal goes
    // high on a read, the data output is equal to the contents of the reference model.
    property out_correct_check;
        @(posedge clk) disable iff (rst) (done && !last_r_w) |-> (data_out == ref_data[last_addr]);
    endproperty

    assert property (out_correct_check) else begin
        $display("Output data is incorrect for read at time %t.", $time());
        $display("Expected: %d, Got: %d", ref_data[last_addr], data_out);
        failures++;
    end
    
    // out_write_check: This assertion checks that the when the done signal goes
    // high on a write, the data output is equal to 0.
    property out_write_check;
        @(posedge clk) disable iff (rst) (done && last_r_w) |-> (data_out == '0);
    endproperty

    assert property (out_write_check) else begin
        $display("Output data is incorrect for write at time %t.", $time());
        $display("Expected: %d, Got: %d", '0, data_out);
        failures++;
    end

    // out_stable_check: This assertion ensures that outputs remain unchanged until
    //  a done signal goes high.
    property out_stable_check;
        @(posedge clk) disable iff (rst) !done |-> $stable(data_out);
    endproperty

    assert property (out_stable_check) else begin
        $display("Output data is changing before done signal at time %t.", $time());
        $display("Expected: %d, Got: %d", $past(data_out), data_out);
        failures++;
    end

    // done_pulse_check: This assertion checks that the done signal is only ever high
    //  for one cycle at a time, since each operation takes at least 2 cycles.
    property done_pulse_check;
        @(posedge clk) disable iff (rst) done |=> !done;
    endproperty

    assert property (done_pulse_check) else begin
        $display("Done signal is high for more than one cycle at time %t.", $time());
        failures++;
    end

    // miss_delay_check: This assertion ensures that operations we expect to be misses
    // have a delay of 3 cycles.
    property miss_delay_check;
        @(posedge clk) disable iff (rst) (done == '1) && (last_hit_miss == '1) |-> $past(we || re, MISS_DELAY);
    endproperty

    assert property (miss_delay_check) else begin
        $display("Miss operation does not have %d cycle delay at time %t.", MISS_DELAY, $time());
        failures++;
    end

    // hit_delay_check: This assertion ensures that operations we expect to be hits
    // have a delay of 2 cycles.
    property hit_delay_check;
        @(posedge clk) disable iff (rst) (done == '1) && (last_hit_miss == '0) |-> $past(we || re, HIT_DELAY);
    endproperty

    assert property (hit_delay_check) else begin
        $display("Hit operation does not have %d cycle delay at time %t.", HIT_DELAY, $time());
        $display("Last hit/miss, r/w, done: %b, %b, %b", last_hit_miss, last_r_w, done);
        $display("Past we: %b, Past re: %b", $past(we, HIT_DELAY), $past(re, HIT_DELAY));
        failures++;
    end

    // making sure we're running the tests right by not setting re || we
    // for more than 1 cycle at a time
    property re_we_pulse_check;
        @(posedge clk) disable iff (rst) (re || we) |=> !(re || we);
    endproperty

    assert property (re_we_pulse_check) else begin
        $display("doing a read/write right after another at time %t.", $time());
        failures++;
    end

endmodule