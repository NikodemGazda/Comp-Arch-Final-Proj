`include "cache_valid.sv"

class cache_valid_transaction #(parameter WAYS=4, parameter TOTAL_SIZE=16);

    // signals
    rand logic we;
    rand logic rst;
    rand logic [$clog2(WAYS)-1:0] way;
    rand logic [$clog2(TOTAL_SIZE/WAYS)-1:0] index;

    // helper signals
    logic prev_we;
    logic [$clog2(WAYS)-1:0] prev_way;
    logic [$clog2(TOTAL_SIZE/WAYS)-1:0] prev_index;

    // constraints
    // make sure index is 0 10% of the time, 1 10% of the time,
    // and everything else 80% of the time
    constraint index_ranges { index dist{'0 :/ 10, '1 :/ 10, [1:TOTAL_SIZE/WAYS-2] :/ 80}; }
    constraint rst_constraint { rst dist{'0 :/ 95, '1 :/ 5}; }
    // way can be random with an equal chance for 0-3
    // write enable can stay at 50% chance

    // but we want to make sure our reads are also valid directly after a write
    constraint read_after_write {
        prev_we == 1'b1 -> (we == 1'b0 && index == prev_index && way == prev_way);
    }

    function void post_randomize();
        // store previous values
        prev_we = we;
        prev_index = index;
        prev_way = way;
    endfunction

endclass

module cache_valid_tb;

    // constants
    localparam int DIRECTED_TESTS = 1; // determine whether to run directed tests
    localparam int NUM_TESTS = 1000;
    localparam int WAYS=4;
    localparam int TOTAL_SIZE=16;

    // signals
    // general
    logic clk, rst;
    // inputs
    logic we;
    logic [$clog2(WAYS)-1:0] way;
    logic [$clog2(TOTAL_SIZE/WAYS)-1:0] index;
    // outputs
    logic valid_out [0:WAYS-1];

    // instantiate DUT
    cache_valid #(.WAYS(WAYS), .TOTAL_SIZE(TOTAL_SIZE)) DUT (.*);

    // generate clock
    initial begin : clk_gen
        clk = '0;
        while (1) #5 clk = ~clk;
    end

    // reset inputs
    task reset();
        // assert reset and set other signals low
        rst = '1;
        we = '0;
        index = '0;
        way = '0;

        // wait a couple cycles
        for (int i = 0; i < 5; i++)
            @(posedge clk);

        // deassert reset
        @(negedge clk);
        rst <= '0;
        @(posedge clk);

    endtask

    // write all addresses to memory
    task write_all();
        for (int i = 0; i < TOTAL_SIZE/WAYS; i++) begin
            for (int j = 0; j < WAYS; j++) begin
                index = i;
                way = j;
                we = '1;
                @(posedge clk);
                @(negedge clk);

                // print first 5 writes
                if (i*WAYS+j < 5) begin
                    $display("Setting valid bit in index %d and bank %d", index, way);
                end
            end
        end
    endtask

    // read all addresses to memory
    task read_all();
        for (int i = 0; i < TOTAL_SIZE/WAYS; i++) begin
            index = i;
            way = '0;
            we = '0;
            @(posedge clk);
            @(negedge clk);

            // print first 5 reads
            if (i < 5) begin
                $display("Reading [%d,%d,%d,%d] from index %d", valid_out[0], valid_out[1], valid_out[2], valid_out[3], index);
            end
        end
    endtask

    // create ram_transaction object
    cache_valid_transaction #(.WAYS(WAYS), .TOTAL_SIZE(TOTAL_SIZE)) item;

    // track failures
    int failures = 0;

    // this never seems to load for me
    // initial begin : wave_capture
    //     $dumpfile("dump.vcd");
    //     $dumpvars(0, cache_valid_tb);
    // end

    // drive inputs
    initial begin : drive_inputs

        // display that ram tb starting
        $display("Starting Cache valid testbench...");

        // reset DUT
        $display("Resetting DUT...");
        reset();
        $display("Reset DUT.");

        // write to all addresses and then read
        if (DIRECTED_TESTS) begin
            $display("Displaying first 5 of %d write tests...", TOTAL_SIZE);
            write_all();
            $display("Displaying all %d read tests...", TOTAL_SIZE);
            read_all();
            $display("All read/write tests completed.");
        end
        
        // print first couple of tests
        $display("Displaying first 5 of %d random tests...", NUM_TESTS);

        // create ram_transaction object
        item = new();

        // start tests
        for (int i = 0; i < NUM_TESTS; i++) begin

            // assign random values
            if (item.randomize() == 0) $error("Randomization failed");

            // assign to actual pins
            we = item.we;
            rst = item.rst;
            index = item.index;
            way = item.way;

            // display inputs
            if (i < 5) begin
                $display("Test %d at time %0t", i+1, $time);
                $display("we: %d", we);
                $display("rst: %d", rst);
                $display("index: %d", index);
                $display("way: %d", way);
            end

            // wait for posedge
            @(posedge clk);
            @(negedge clk);

            if (!we && i < 5) $display("valid_out: [%d, %d, %d, %d]", valid_out[0], valid_out[1], valid_out[2], valid_out[3]);
        end

        // end tests
        disable clk_gen;
        $display("%d tests finished with %d failires.", DIRECTED_TESTS ? TOTAL_SIZE*2+NUM_TESTS : NUM_TESTS, failures);

    end

    // ASSERTS!!!!!!!!! to check functionality
    // have a reference model
    logic ref_mem [0:WAYS-1][0:TOTAL_SIZE/WAYS-1];

    // reference model to mimic RAM behavior
    always_ff @(posedge clk or posedge rst) begin : ref_mem_update
        if (rst) begin
            for (int i = 0; i < WAYS; i++) begin
                for (int j = 0; j < TOTAL_SIZE/WAYS; j++) begin
                    ref_mem[i][j] <= '0;
                end
            end
        end else if (we) begin
            ref_mem[way][index] <= 1'b1;
        end
    end

    property out_correct_check_0;
        @(negedge clk) disable iff (rst) valid_out[0] == ref_mem[0][index];
    endproperty

    property out_correct_check_1;
        @(negedge clk) disable iff (rst) valid_out[1] == ref_mem[1][index];
    endproperty

    property out_correct_check_2;
        @(negedge clk) disable iff (rst) valid_out[2] == ref_mem[2][index];
    endproperty

    property out_correct_check_3;
        @(negedge clk) disable iff (rst) valid_out[3] == ref_mem[3][index];
    endproperty

    assert property (out_correct_check_0) else begin
        $error("ERROR: valid_out[0]=%d but supposed to be %d, index: %d", valid_out[0], ref_mem[0][index], index);
        failures++;
    end

    assert property (out_correct_check_1) else begin
        $error("ERROR: valid_out[1]=%d but supposed to be %d, index: %d", valid_out[1], ref_mem[1][index], index);
        failures++;
    end

    assert property (out_correct_check_2) else begin
        $error("ERROR: valid_out[2]=%d but supposed to be %d, index: %d", valid_out[2], ref_mem[2][index], index);
        failures++;
    end

    assert property (out_correct_check_3) else begin
        $error("ERROR: valid_out[3]=%d but supposed to be %d, index: %d", valid_out[3], ref_mem[3][index], index);
        failures++;
    end

endmodule