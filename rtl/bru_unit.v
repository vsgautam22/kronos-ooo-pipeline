`include "ooo_pkg.v"
module bru_unit (
    input  wire                   clk, rst_n, flush,
    input  wire                   issue_valid,
    input  wire [3:0]             issue_opcode,
    input  wire [`ROB_BITS-1:0]   issue_tag,
    input  wire [`DATA_WIDTH-1:0] issue_vj, issue_vk,
    input  wire [15:0]            issue_imm,
    input  wire [15:0]            issue_pc,
    output wire                   issue_ack,
    output reg                    cdb_valid,
    output reg  [`ROB_BITS-1:0]   cdb_tag,
    output reg  [`DATA_WIDTH-1:0] cdb_data,
    output reg                    branch_taken,
    output reg  [15:0]            branch_target
);
    assign issue_ack=issue_valid;

    wire cond = issue_valid && (
        (issue_opcode==`OP_BEQ && issue_vj==issue_vk) ||
        (issue_opcode==`OP_BNE && issue_vj!=issue_vk) ||
        (issue_opcode==`OP_BLT && $signed(issue_vj)<$signed(issue_vk)) ||
        (issue_opcode==`OP_JMP));

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n||flush) begin
            cdb_valid<=0; branch_taken<=0; branch_target<=0;
        end else begin
            cdb_valid    <= issue_valid;
            cdb_tag      <= issue_tag;
            cdb_data     <= 0;
            branch_taken <= cond;
            if (cond)
                branch_target <= issue_pc + {{16{issue_imm[15]}},issue_imm[15:0]};
            else
                branch_target <= 16'h0;
        end
    end
endmodule
