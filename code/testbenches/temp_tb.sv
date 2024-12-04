`include "logic_done.sv"

module temp_tb;

    // constants
    localparam int NUM_TESTS = 2;
    localparam int MIN_CYCLES = 1;

    // signals
    // general
    logic clk, rst;
    // inputs
    logic we, re, hit;
    // outputs
    logic pre_done, done;

    // instantiate DUT
    logic_done #(.MIN_CYCLES(MIN_CYCLES)) DUT (.*);

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

        // wait a couple cycles
        for (int i = 0; i < 5; i++)
            @(posedge clk);

        // deassert reset
        @(negedge clk);
        rst <= '0;
        @(posedge clk);

    endtask


    // drive inputs
    initial begin : drive_inputs

        // display that ram tb starting
        $display("\nStarting Logic Done testbench...");

        // reset DUT
        $display("\nResetting DUT...");
        reset();
        $display("Reset DUT.");

        // Random tests
        if (NUM_TESTS > 0) begin
            $display("\nRunning tests...");

            // rest of the random tests
            for (int i = 0; i < NUM_TESTS-1; i++) begin
                
                // print first 5 tests
                // first do re test
                if (i < NUM_TESTS) $display("\nRunning read test %d...", i+1);

                we = '0;
                re = '1;
                hit = '0;

                @(posedge clk);
                @(negedge clk);

                if (i < NUM_TESTS) $display("\nINPUTS:\nRE: %b, WE: %b, hit: %b", re, we, hit);
                if (i < NUM_TESTS) $display("OUTPUTS:\npre_done: %b, done: %b", pre_done, done);
                $display("\nread_hit_delay_all_out: [%d,%d]",DUT.read_hit_delay_all_out[0],DUT.read_hit_delay_all_out[1]);
                $display("\nread_miss_delay_all_out: [%d,%d,%d]",DUT.read_miss_delay_all_out[0],DUT.read_miss_delay_all_out[1],DUT.read_miss_delay_all_out[2]);
                $display("\nwrite_hit_delay_all_out: [%d,%d]",DUT.write_hit_delay_all_out[0],DUT.write_hit_delay_all_out[1]);
                $display("\nwrite_miss_delay_all_out: [%d,%d,%d]",DUT.write_miss_delay_all_out[0],DUT.write_miss_delay_all_out[1],DUT.write_miss_delay_all_out[2]);

                // then repeat 2 tests with neither re nor we to let the operation finish
                for (int j = 0; j < 2; j++) begin
                    @(posedge clk);
                    @(negedge clk);

                    if (i < NUM_TESTS) $display("\nINPUTS:\nRE: %b, WE: %b, hit: %b", re, we, hit);
                    if (i < NUM_TESTS) $display("OUTPUTS:\npre_done: %b, done: %b", pre_done, done);
                    $display("\nread_hit_delay_all_out: [%d,%d]",DUT.read_hit_delay_all_out[0],DUT.read_hit_delay_all_out[1]);
                    $display("\nread_miss_delay_all_out: [%d,%d,%d]",DUT.read_miss_delay_all_out[0],DUT.read_miss_delay_all_out[1],DUT.read_miss_delay_all_out[2]);
                    $display("\nwrite_hit_delay_all_out: [%d,%d]",DUT.write_hit_delay_all_out[0],DUT.write_hit_delay_all_out[1]);
                    $display("\nwrite_miss_delay_all_out: [%d,%d,%d]",DUT.write_miss_delay_all_out[0],DUT.write_miss_delay_all_out[1],DUT.write_miss_delay_all_out[2]);
                end

                // then do we test
                if (i < NUM_TESTS) $display("\nRunning write test %d...", i+1);

                we = '1;
                re = '0;
                hit = '0;

                @(posedge clk);
                @(negedge clk);
                
                if (i < NUM_TESTS) $display("\nINPUTS:\nRE: %b, WE: %b, hit: %b", re, we, hit);
                if (i < NUM_TESTS) $display("OUTPUTS:\npre_done: %b, done: %b", pre_done, done);
                $display("\nread_hit_delay_all_out: [%d,%d]",DUT.read_hit_delay_all_out[0],DUT.read_hit_delay_all_out[1]);
                $display("\nread_miss_delay_all_out: [%d,%d,%d]",DUT.read_miss_delay_all_out[0],DUT.read_miss_delay_all_out[1],DUT.read_miss_delay_all_out[2]);
                $display("\nwrite_hit_delay_all_out: [%d,%d]",DUT.write_hit_delay_all_out[0],DUT.write_hit_delay_all_out[1]);
                $display("\nwrite_miss_delay_all_out: [%d,%d,%d]",DUT.write_miss_delay_all_out[0],DUT.write_miss_delay_all_out[1],DUT.write_miss_delay_all_out[2]);
                
                // and repeat again 2 tests with neither re nor we
                for (int j = 0; j < 2; j++) begin
                    @(posedge clk);
                    @(negedge clk);

                    if (i < NUM_TESTS) $display("\nINPUTS:\nRE: %b, WE: %b, hit: %b", re, we, hit);
                    if (i < NUM_TESTS) $display("OUTPUTS:\npre_done: %b, done: %b", pre_done, done);
                    $display("\nread_hit_delay_all_out: [%d,%d]",DUT.read_hit_delay_all_out[0],DUT.read_hit_delay_all_out[1]);
                    $display("\nread_miss_delay_all_out: [%d,%d,%d]",DUT.read_miss_delay_all_out[0],DUT.read_miss_delay_all_out[1],DUT.read_miss_delay_all_out[2]);
                    $display("\nwrite_hit_delay_all_out: [%d,%d]",DUT.write_hit_delay_all_out[0],DUT.write_hit_delay_all_out[1]);
                    $display("\nwrite_miss_delay_all_out: [%d,%d,%d]",DUT.write_miss_delay_all_out[0],DUT.write_miss_delay_all_out[1],DUT.write_miss_delay_all_out[2]);
                end

                // first do re test
                if (i < NUM_TESTS) $display("\nRunning read test %d...", i+1);

                we = '0;
                re = '1;
                hit = '1;

                @(posedge clk);
                @(negedge clk);

                if (i < NUM_TESTS) $display("\nINPUTS:\nRE: %b, WE: %b, hit: %b", re, we, hit);
                if (i < NUM_TESTS) $display("OUTPUTS:\npre_done: %b, done: %b", pre_done, done);
                $display("\nread_hit_delay_all_out: [%d,%d]",DUT.read_hit_delay_all_out[0],DUT.read_hit_delay_all_out[1]);
                $display("\nread_miss_delay_all_out: [%d,%d,%d]",DUT.read_miss_delay_all_out[0],DUT.read_miss_delay_all_out[1],DUT.read_miss_delay_all_out[2]);
                $display("\nwrite_hit_delay_all_out: [%d,%d]",DUT.write_hit_delay_all_out[0],DUT.write_hit_delay_all_out[1]);
                $display("\nwrite_miss_delay_all_out: [%d,%d,%d]",DUT.write_miss_delay_all_out[0],DUT.write_miss_delay_all_out[1],DUT.write_miss_delay_all_out[2]);

                // then repeat 2 tests with neither re nor we to let the operation finish
                for (int j = 0; j < 2; j++) begin
                    @(posedge clk);
                    @(negedge clk);

                    if (i < NUM_TESTS) $display("\nINPUTS:\nRE: %b, WE: %b, hit: %b", re, we, hit);
                    if (i < NUM_TESTS) $display("OUTPUTS:\npre_done: %b, done: %b", pre_done, done);
                    $display("\nread_hit_delay_all_out: [%d,%d]",DUT.read_hit_delay_all_out[0],DUT.read_hit_delay_all_out[1]);
                    $display("\nread_miss_delay_all_out: [%d,%d,%d]",DUT.read_miss_delay_all_out[0],DUT.read_miss_delay_all_out[1],DUT.read_miss_delay_all_out[2]);
                    $display("\nwrite_hit_delay_all_out: [%d,%d]",DUT.write_hit_delay_all_out[0],DUT.write_hit_delay_all_out[1]);
                    $display("\nwrite_miss_delay_all_out: [%d,%d,%d]",DUT.write_miss_delay_all_out[0],DUT.write_miss_delay_all_out[1],DUT.write_miss_delay_all_out[2]);
                end

                // then do we test
                if (i < NUM_TESTS) $display("\nRunning write test %d...", i+1);

                we = '1;
                re = '0;
                hit = '1;

                @(posedge clk);
                @(negedge clk);
                
                if (i < NUM_TESTS) $display("\nINPUTS:\nRE: %b, WE: %b, hit: %b", re, we, hit);
                if (i < NUM_TESTS) $display("OUTPUTS:\npre_done: %b, done: %b", pre_done, done);
                $display("\nread_hit_delay_all_out: [%d,%d]",DUT.read_hit_delay_all_out[0],DUT.read_hit_delay_all_out[1]);
                $display("\nread_miss_delay_all_out: [%d,%d,%d]",DUT.read_miss_delay_all_out[0],DUT.read_miss_delay_all_out[1],DUT.read_miss_delay_all_out[2]);
                $display("\nwrite_hit_delay_all_out: [%d,%d]",DUT.write_hit_delay_all_out[0],DUT.write_hit_delay_all_out[1]);
                $display("\nwrite_miss_delay_all_out: [%d,%d,%d]",DUT.write_miss_delay_all_out[0],DUT.write_miss_delay_all_out[1],DUT.write_miss_delay_all_out[2]);
                $display("\nread_hit_delay_all_out: [%d,%d]",DUT.read_hit_delay_all_out[0],DUT.read_hit_delay_all_out[1]);
                $display("\nread_miss_delay_all_out: [%d,%d,%d]",DUT.read_miss_delay_all_out[0],DUT.read_miss_delay_all_out[1],DUT.read_miss_delay_all_out[2]);
                $display("\nwrite_hit_delay_all_out: [%d,%d]",DUT.write_hit_delay_all_out[0],DUT.write_hit_delay_all_out[1]);
                $display("\nwrite_miss_delay_all_out: [%d,%d,%d]",DUT.write_miss_delay_all_out[0],DUT.write_miss_delay_all_out[1],DUT.write_miss_delay_all_out[2]);
                
                // and repeat again 2 tests with neither re nor we
                for (int j = 0; j < 2; j++) begin
                    @(posedge clk);
                    @(negedge clk);

                    if (i < NUM_TESTS) $display("\nINPUTS:\nRE: %b, WE: %b, hit: %b", re, we, hit);
                    if (i < NUM_TESTS) $display("OUTPUTS:\npre_done: %b, done: %b", pre_done, done);
                    $display("\nread_hit_delay_all_out: [%d,%d]",DUT.read_hit_delay_all_out[0],DUT.read_hit_delay_all_out[1]);
                    $display("\nread_miss_delay_all_out: [%d,%d,%d]",DUT.read_miss_delay_all_out[0],DUT.read_miss_delay_all_out[1],DUT.read_miss_delay_all_out[2]);
                    $display("\nwrite_hit_delay_all_out: [%d,%d]",DUT.write_hit_delay_all_out[0],DUT.write_hit_delay_all_out[1]);
                    $display("\nwrite_miss_delay_all_out: [%d,%d,%d]",DUT.write_miss_delay_all_out[0],DUT.write_miss_delay_all_out[1],DUT.write_miss_delay_all_out[2]);
                end

            end
        end

        // end tests
        disable clk_gen;

        $display("\n%d tests finished.", NUM_TESTS);

    end


endmodule