module ram #(
    parameter WIDTH=8,
    parameter DEPTH=256
    ) (
    input  logic clk, rst, we,
    input  logic [WIDTH-1:0] data_in,
    input  logic [$clog2(DEPTH)-1:0] addr,
    output logic [WIDTH-1:0] data_out
);
    // memory array acting as RAM
    logic [WIDTH-1:0] mem [0:DEPTH-1];

    // synchronous read and write
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            // clear ram on reset
            for (int i = 0; i < DEPTH; i++) begin
                mem[i] <= '0;
            end
            data_out <= '0;
        end else begin
            // write on we
            if (we) begin
                mem[addr] <= data_in;
            end
            // read always
            data_out <= mem[addr];
        end
    end

endmodule