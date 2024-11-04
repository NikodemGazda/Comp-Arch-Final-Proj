class ram_transaction #(parameter WIDTH = 8, parameter DEPTH = 256); ;

    // signals
    rand logic [WIDTH-1:0] data_in;
    rand logic we;
    rand logic [$clog2(DEPTH)-1:0] addr;

    // helper signals
    logic [WIDTH-1:0] prev_we;
    logic [$clog2(DEPTH)-1:0] prev_addr;

    // constraints
    // make sure data is 0 10% of the time, 1 10% of the time,
    // and everything else 80% of the time
    constraint data_ranges { data_in dist{'0 :/ 10, '1 :/ 10, [1:2**WIDTH-2] :/ 80}; }
    // same with addr
    constraint addr_ranges { addr dist{'0 :/ 10, '1 :/ 10, [1:DEPTH-2] :/ 80}; }
    // write enable can stay at 50% chance

    // but we want to make sure our reads are also valid directly after a write
    constraint read_after_write {
        prev_we == 1'b1 -> (we == 1'b0 && addr == prev_addr);
    }

    function void post_randomize();
        // store previous values
        prev_we = we;
        prev_addr = addr;
    endfunction

endclass

module ram_tb;

    // constants
    localparam int DIRECTED_TESTS = 1; // determine whether to run directed tests
    localparam int NUM_TESTS = 1000;
    localparam int WIDTH = 8;
    localparam int DEPTH = 256;

    // signals
    logic clk, rst, we;
    logic [WIDTH-1:0] data_in;
    logic [$clog2(DEPTH)-1:0] addr;
    logic [WIDTH-1:0] data_out;

    // instantiate DUT
    ram #(.WIDTH(WIDTH), .DEPTH(DEPTH)) DUT (.*);

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
        addr = '0;

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
        for (int i = 0; i < DEPTH; i++) begin
            addr = i;
            data_in = i;
            we = '1;
            @(posedge clk);
            @(negedge clk);

            // print first 5 writes
            if (i < 5) begin
                $display("Writing %d to address %d", data_in, addr);
            end
        end
    endtask

    // read all addresses to memory
    task read_all();
        // saving past address
        logic [$clog2(DEPTH)-1:0] past_addr;

        for (int i = 0; i < DEPTH; i++) begin
            addr = i;
            data_in = '0;
            we = '0;
            @(posedge clk);
            @(negedge clk);

            // print first 5 reads
            if (i < 5) begin
                $display("Reading %d from address %d", data_out, addr);
            end
        end
    endtask

    // create ram_transaction object
    ram_transaction #(.WIDTH(WIDTH), .DEPTH(DEPTH)) item;

    // track failures
    int failures = 0;

    // drive inputs
    initial begin : drive_inputs

        // display that ram tb starting
        $display("Starting RAM testbench...");

        // reset DUT
        $display("Resetting DUT...");
        reset();
        $display("Reset DUT.");

        // write to all addresses and then read
        if (DIRECTED_TESTS) begin
            $display("Displaying first 5 of %d write tests...", DEPTH);
            write_all();
            $display("Displaying first 5 of %d read tests...", DEPTH);
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
            addr = item.addr;

            // display inputs
            if (i < 5) begin
                $display("Test %d at time %0t", i+1, $time);
                $display("we: %d", we);
                $display("addr: %d", addr);
                // data_in only relevant if we is high
                if (we) $display("data_in: %d", data_in);
            end

            // wait for posedge
            @(posedge clk);
            @(negedge clk);

            // display output after clock edge
            if (i < 5) begin
                $display("POSEDGE CLK");
                $display("data_out: %d", data_out);
            end
        end

        // end tests
        disable clk_gen;
        $display("%d tests finished with %d failires.", DIRECTED_TESTS ? 256*2+NUM_TESTS : NUM_TESTS, failures);

    end

    // ASSERTS!!!!!!!!! to check functionality
    // have a reference model
    logic [WIDTH-1:0] ref_mem [0:DEPTH-1];

    // reference model to mimic RAM behavior
    always_ff @(posedge clk or posedge rst) begin : ref_mem_update
        if (rst) begin
            for (int i = 0; i < DEPTH; i++) ref_mem[i] <= '0;
        end else if (we) begin
            ref_mem[addr] <= data_in;
        end
    end

    // check that reads is valid
    property out_correct_check;
        @(posedge clk) disable iff (rst) !we |=> data_out == ref_mem[$past(addr)];
    endproperty

    // check that writes work
    property write_check;
        // this property is complicated so I'll break it down
        // when we is high and followed by a read,
        // and the addr is the same for the read as with the write,
        // then we should wait a cycle for the read to happen and see that
        // that input from the write is now the output
        @(posedge clk) disable iff (rst) we ##1 (!we && (addr == $past(addr))) |=> data_out == $past(data_in,2);
    endproperty

    // calling assert properties
    assert property (write_check) else begin
        $error("ERROR with write_check: data_out=%d but supposed to be %d", data_out, $past(data_in));
        $display("Debug Info: Time=%0t, we=%b, addr=%d, data_in=%d, DUT.mem[%d]=%d", $time, we, addr, data_in, $past(addr), DUT.mem[$past(addr)]);
        failures++;
    end
    assert property (out_correct_check) else begin
        $display("ERROR with out_correct_check: out=%d but supposed to be %d", data_out, ref_mem[addr]);
        failures++;
    end

endmodule