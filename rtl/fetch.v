`include "ooo_pkg.v"
module fetch (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        stall,
    input  wire        flush,
    input  wire        branch_taken,
    input  wire [15:0] branch_target,
    output reg  [15:0] pc_out,
    output reg  [31:0] instr_out,
    output reg         fetch_valid
);
    reg [31:0] imem [0:255];
    initial $readmemh("tb/imem.hex", imem);

    reg [15:0] pc;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc          <= 0;
            pc_out      <= 0;
            instr_out   <= 0;
            fetch_valid <= 0;
        end else if (flush) begin
            pc          <= branch_target;
            fetch_valid <= 0;
            instr_out   <= 0;
        end else if (!stall) begin
            // Output current PC and instruction this cycle
            pc_out      <= pc;
            instr_out   <= imem[pc[7:0]];
            fetch_valid <= 1;
            pc          <= pc + 1;
        end
        // On stall: hold outputs, don't advance PC
    end
endmodule
