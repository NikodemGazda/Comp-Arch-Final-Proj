module component_delay #(
    parameter WIDTH = 8,
    parameter CYCLES = 4,
) (
    input logic clk, rst,
    input logic [WIDTH-1:0] data_in,
    output logic [WIDTH-1:0] data_out
);
    // array of registers to hold data
    logic [WIDTH-1:0] mem [0:CYCLES];

    // array of registers
    for (genvar i = 0; i < CYCLES; i++) begin : reg_array
        component_register #(
            .WIDTH(WIDTH)
        ) reg_array (
            .clk(clk),
            .rst(rst),
            .data_in(mem[i]),
            .data_out(mem[i+1])
        );
    end

    // assign input/output
    assign data_out = mem[CYCLES];
    assign mem[0] = data_in;

endmodule
