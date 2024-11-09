module cache_valid #(
    parameter WAYS = 4,
    parameter TOTAL_SIZE = 16
) (
    input logic clk,
    input logic rst,
    input logic we,
    input logic [$clog2(WAYS)-1:0] way,
    input logic [$clog2(TOTAL_SIZE/WAYS)-1:0] index,
    output logic valid_out [0:WAYS-1] // output valid bits for all ways
);

    // valid bits for each way
    logic valid_bits [0:WAYS-1][0:TOTAL_SIZE/WAYS-1];

    // synchronous reset of valid bits
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            for(int i = 0; i < WAYS; i++) begin
                for(int j = 0; j < TOTAL_SIZE/WAYS; j++) begin
                    valid_bits[i][j] <= '0; // clear all valid bits on reset
                end
            end
        end else begin
            if (we) begin
                valid_bits[way][index] <= 1'b1; // set valid bit for the written way
            end
        end
    end

    // reads are combinational
    always_comb begin
        for(int i = 0; i < WAYS; i++) begin
            valid_out[i] = valid_bits[i][index]; // output valid bits for all ways
        end
    end

endmodule