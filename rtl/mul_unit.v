`include "ooo_pkg.v"
module mul_unit (
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
    reg s1_v,s2_v;
    reg [`ROB_BITS-1:0] s1_tag,s2_tag;
    reg [`DATA_WIDTH-1:0] s1_data,s2_data;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n||flush) begin s1_v<=0;s2_v<=0;cdb_valid<=0; end
        else begin
            s1_v<=issue_valid; s1_tag<=issue_tag;
            s1_data<=(issue_opcode==`OP_MUL)?issue_vj*issue_vk:
                      (issue_vk!=0?issue_vj/issue_vk:0);
            s2_v<=s1_v; s2_tag<=s1_tag; s2_data<=s1_data;
            cdb_valid<=s2_v; cdb_tag<=s2_tag; cdb_data<=s2_data;
        end
    end
endmodule
