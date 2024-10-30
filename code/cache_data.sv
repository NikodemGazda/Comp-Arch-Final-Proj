module cache_data #(
    parameter WIDTH=8,
    parameter WAYS=4,
    parameter TOTAL_SIZE=16
    ) (
    input  logic clk, rst, we, re,
    input  logic [$clog2(WAYS)-1:0] way,
    input  logic [$clog2(TOTAL_SIZE/WAYS)-1:0] index,
    input  logic [WIDTH-1:0] data_in,
    output logic [WIDTH-1:0] data_out [0:WAYS-1] // output data for all ways
);
    // memory array acting as memory
    logic [WIDTH-1:0] mem [0:WAYS-1][0:TOTAL_SIZE/WAYS-1];

    // synchronous read and write
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            // clear ram on reset
            for (int i = 0; i < WAYS; i++) begin
                for (int j = 0; j < TOTAL_SIZE/WAYS; j++) begin
                    mem[i][j] <= '0;
                end
            end
        end else begin
            // write on we, read on re
            if (we) begin
                mem[way][index] <= data_in;
            end else if (re) begin
                data_out <= mem[way][index];
            end
        end
    end

    // make reads combinational
    assign data_out = mem[index]; // output data for all ways

endmodule