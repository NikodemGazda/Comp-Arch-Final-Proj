`include "cache_data.sv"

class cache_data_transaction #(parameter WIDTH=8, parameter WAYS=4, parameter TOTAL_SIZE=16);

    // signals
    rand logic [WIDTH-1:0] data_in;
    rand logic we;
    rand logic [$clog2(WAYS)-1:0] way;
    rand logic [$clog2(TOTAL_SIZE/WAYS)-1:0] index;

    // helper signals
    logic prev_we;
    logic [$clog2(WAYS)-1:0] prev_way;
    logic [$clog2(TOTAL_SIZE/WAYS)-1:0] prev_index;

    // constraints
    // make sure data is 0 10% of the time, 1 10% of the time,
    // and everything else 80% of the time
    constraint data_ranges { data_in dist{'0 :/ 10, '1 :/ 10, [1:2**WIDTH-2] :/ 80}; }
    // same with index
    constraint index_ranges { index dist{'0 :/ 10, '1 :/ 10, [1:TOTAL_SIZE/WAYS-2] :/ 80}; }
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

module cache_data_tb;

    // constants
    localparam int DIRECTED_TESTS = 1; // determine whether to run directed tests
    localparam int NUM_TESTS = 1000;
    localparam int WIDTH = 8;
    localparam int WAYS=4;
    localparam int TOTAL_SIZE=16;

    // signals
    // general
    logic clk, rst;
    // inputs
    logic we;
    logic [$clog2(WAYS)-1:0] way;
    logic [$clog2(TOTAL_SIZE/WAYS)-1:0] index;
    logic [WIDTH-1:0] data_in;
    // outputs
    logic [WIDTH-1:0] data_out;

    // instantiate DUT
    cache_data #(.WIDTH(WIDTH), .WAYS(WAYS), .TOTAL_SIZE(TOTAL_SIZE)) DUT (.*);

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
        data_in = '0;
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
                data_in = i*WAYS+j;
                we = '1;
                @(posedge clk);
                @(negedge clk);

                // print first 5 writes
                if (i*WAYS+j < 5) begin
                    $display("Writing %d to index %d and bank %d", data_in, index, way);
                end
            end
        end
    endtask

    // read all addresses to memory
    task read_all();
        for (int i = 0; i < TOTAL_SIZE/WAYS; i++) begin
            for (int j = 0; j < WAYS; j++) begin
                index = i;
                way = j;
                data_in = '0;
                we = '0;
                @(posedge clk);
                @(negedge clk);

                // print first 5 reads
                if (i*WAYS+j < 5) begin
                    $display("Reading %d from index %d and bank %d", data_out, index, way);
                end
            end
        end
    endtask

    // create ram_transaction object
    cache_data_transaction #(.WIDTH(WIDTH), .WAYS(WAYS), .TOTAL_SIZE(TOTAL_SIZE)) item;

    // track failures
    int failures = 0;

    // drive inputs
    initial begin : drive_inputs

        // display that ram tb starting
        $display("Starting Cache Data testbench...");

        // reset DUT
        $display("Resetting DUT...");
        reset();
        $display("Reset DUT.");

        // write to all addresses and then read
        if (DIRECTED_TESTS) begin
            $display("Displaying first 5 of %d write tests...", TOTAL_SIZE);
            write_all();
            $display("Displaying first 5 of %d read tests...", TOTAL_SIZE);
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
            data_in = item.data_in;
            index = item.index;
            way = item.way;

            // display inputs
            if (i < 5) begin
                $display("Test %d at time %0t", i+1, $time);
                $display("we: %d", we);
                $display("index: %d", index);
                $display("way: %d", way);
                // data_in only relevant if we is high
                if (we) $display("data_in: %d", data_in);
            end

            // wait for posedge
            @(posedge clk);
            @(negedge clk);

            if (!we && i < 5) $display("data_out: %d", data_out);
        end

        // end tests
        disable clk_gen;
        $display("%d tests finished with %d failires.", DIRECTED_TESTS ? TOTAL_SIZE*2+NUM_TESTS : NUM_TESTS, failures);

    end

    // ASSERTS!!!!!!!!! to check functionality
    // have a reference model
    logic [WIDTH-1:0] ref_mem [0:WAYS-1][0:TOTAL_SIZE/WAYS-1];

    // reference model to mimic RAM behavior
    always_ff @(posedge clk or posedge rst) begin : ref_mem_update
        if (rst) begin
            for (int i = 0; i < WAYS; i++) begin
                for (int j = 0; j < TOTAL_SIZE/WAYS; j++) begin
                    ref_mem[i][j] <= '0;
                end
            end
        end else if (we) begin
            ref_mem[way][index] <= data_in;
        end
    end

    // check that reads is valid according to ref model, combinational so we do an immediate assertion.
    always_comb begin : out_correct_check
        if ($time() > 0 && (we == '0 || rst == '0)) begin
            assert(data_out == ref_mem[way][index]);
        end
    end

    // check that writes work
    property write_check;
        // this property is complicated so I'll break it down
        // when we is high and followed by a read,
        // and the index/way are the same for the read as with the write,
        // then we should wait a cycle for the read to happen in the next test case and see that
        // that input from the write is now the output
        @(posedge clk) disable iff (rst) (we == '0 && ($past(we) == '1) && (index == $past(index)) && (way == $past(way))) |-> data_out == $past(data_in,1);
    endproperty

    // calling assert properties
    assert property (write_check) else begin
        $error("ERROR with write_check: data_out=%d but supposed to be %d", data_out, $past(data_in));
        $display("Debug Info: Time=%0t, we=%b, past we=%b, index=%d, way=%d, data_in=%d, DUT.mem[%d][%d]=%d, past index=%d, past way=%d, past data_in=%d", $time, we, $past(we), index, way, data_in, way, index, DUT.mem[way][index], $past(index), $past(way), $past(data_in));
        failures++;
    end

endmodule