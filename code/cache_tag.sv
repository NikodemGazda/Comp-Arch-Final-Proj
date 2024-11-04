
// this module stores all the tags in the set-associative cache
module cache_tag #(
    parameter WIDTH = 8,
    parameter WAYS = 4,
    parameter TOTAL_SIZE = 16
) (
    input  logic clk,
    input  logic rst,
    input  logic we,
    // input  logic re,
    input  logic [$clog2(WAYS)-1:0] way,
    input  logic [$clog2(TOTAL_SIZE/WAYS)-1:0] index,
    input  logic [WIDTH-1:0] tag_in,
    output logic [WIDTH-1:0] tag_out [0:WAYS-1] // output tags for all ways
);

    // valid bits for each way
    logic [WIDTH-1:0] tags [0:WAYS-1][0:TOTAL_SIZE/WAYS-1];

    // synchronous reset of valid bits
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            for(int i = 0; i < WAYS; i++) begin
                for(int j = 0; j < TOTAL_SIZE/WAYS; j++) begin
                    tags[i][j] <= '0; // clear all tags on reset
                end
            end
        end else begin
            if (we) begin
                tags[way][index] <= tag_in; // write tag for the specified way and index
            end
            // if (re) begin
            //     for (int i = 0; i < WAYS-1; i++) begin
            //         tag_out[i] <= tags[i][index]; // read tag for all ways at the specified index
            //     end
            // end
        end
    end

    // reads combinational
    assign tag_out = tags[way]; // output tags for all ways

endmodule