`include "ooo_pkg.v"
module alu_unit (
    input  wire                   clk, rst_n, flush,
    input  wire                   issue_valid,
    input  wire [3:0]             issue_opcode,
    input  wire [`ROB_BITS-1:0]   issue_tag,
    input  wire [`DATA_WIDTH-1:0] issue_vj, issue_vk,
    input  wire [15:0]            issue_imm,
    output wire                   issue_ack,
    output reg                    cdb_valid,
    output reg  [`ROB_BITS-1:0]   cdb_tag,
    output reg  [`DATA_WIDTH-1:0] cdb_data
);
    assign issue_ack=issue_valid;
    reg [`DATA_WIDTH-1:0] res;
    always @(*) case(issue_opcode)
        `OP_ADD,`OP_ADDI: res=issue_vj+issue_vk;
        `OP_SUB:          res=issue_vj-issue_vk;
        `OP_AND:          res=issue_vj&issue_vk;
        `OP_OR:           res=issue_vj|issue_vk;
        `OP_XOR:          res=issue_vj^issue_vk;
        `OP_SHL:          res=issue_vj<<issue_vk[4:0];
        `OP_SHR:          res=issue_vj>>issue_vk[4:0];
        default:          res=0;
    endcase
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n||flush) cdb_valid<=0;
        else begin
            cdb_valid <= issue_valid;
            cdb_tag   <= issue_tag;
            cdb_data  <= res;
        end
    end
endmodule
