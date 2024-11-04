module cache_data #(
    parameter WIDTH=8,
    parameter WAYS=4,
    parameter TOTAL_SIZE=16
    ) (
    input  logic clk, rst, we,
    input  logic [$clog2(WAYS)-1:0] way,
    input  logic [$clog2(TOTAL_SIZE/WAYS)-1:0] index,
    input  logic [WIDTH-1:0] data_in,
    output logic [WIDTH-1:0] data_out
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
        end else if (we) begin
            // write on we
            mem[way][index] <= data_in;
        end
    end

    // reads are combinational
    assign data_out = mem[way][index];

endmodule