// `include "component_register.sv"

module component_delay #(
    parameter WIDTH = 8,
    parameter CYCLES = 4
) (
    input logic clk, rst,
    input logic [WIDTH-1:0] data_in,
    output logic [WIDTH-1:0] data_out,
    output logic [WIDTH-1:0] data_all_out [0:CYCLES]
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
            .en(1'b1),
            .data_in(mem[i]),
            .data_out(mem[i+1])
        );
    end

    // assign input/output
    assign data_out = mem[CYCLES];
    assign mem[0] = data_in;

    // assign all outputs
    for (genvar i = 0; i <= CYCLES; i++) begin : all_out_assign
        assign data_all_out[i] = mem[i];
    end

endmodule
