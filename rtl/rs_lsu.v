`include "ooo_pkg.v"
module rs_lsu (
    input  wire                   clk, rst_n, flush,
    input  wire                   disp_valid,
    input  wire [3:0]             disp_opcode,
    input  wire [`ROB_BITS-1:0]   disp_tag,
    input  wire [`DATA_WIDTH-1:0] disp_vj, disp_vk,
    input  wire [`ROB_BITS-1:0]   disp_qj, disp_qk,
    input  wire [15:0]            disp_imm,
    output wire                   rs_full,
    input  wire                   st_pending,
    input  wire                   cdb_valid,
    input  wire [`ROB_BITS-1:0]   cdb_tag,
    input  wire [`DATA_WIDTH-1:0] cdb_data,
    output wire                   issue_valid,
    output wire [3:0]             issue_opcode,
    output wire [`ROB_BITS-1:0]   issue_tag,
    output wire [`DATA_WIDTH-1:0] issue_vj, issue_vk,
    output wire [15:0]            issue_imm,
    input  wire                   issue_ack
);
    reg                   busy [0:1];
    reg [3:0]             opc  [0:1];
    reg [`ROB_BITS-1:0]   tag  [0:1];
    reg [`DATA_WIDTH-1:0] vj   [0:1];
    reg [`DATA_WIDTH-1:0] vk   [0:1];
    reg [`ROB_BITS-1:0]   qj   [0:1];
    reg [`ROB_BITS-1:0]   qk   [0:1];
    reg [15:0]            imm  [0:1];

    assign rs_full=busy[0]&busy[1];
    wire free_slot=busy[0]?1:0;

    // LD blocked while any unexecuted ST in ROB
    wire r0=busy[0]&&qj[0]==`TAG_NONE&&qk[0]==`TAG_NONE&&!(opc[0]==`OP_LD&&st_pending);
    wire r1=busy[1]&&qj[1]==`TAG_NONE&&qk[1]==`TAG_NONE&&!(opc[1]==`OP_LD&&st_pending);
    wire any=r0|r1;
    wire rs=r0?0:1;

    assign issue_valid=any; assign issue_opcode=opc[rs];
    assign issue_tag=tag[rs]; assign issue_vj=vj[rs];
    assign issue_vk=vk[rs]; assign issue_imm=imm[rs];

    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n||flush) begin
            busy[0]<=0;busy[1]<=0;
            qj[0]<=`TAG_NONE;qk[0]<=`TAG_NONE;
            qj[1]<=`TAG_NONE;qk[1]<=`TAG_NONE;
        end else begin
            for (i=0;i<2;i=i+1) begin
                if (busy[i]&&qj[i]!=`TAG_NONE&&qj[i]==cdb_tag&&cdb_valid)
                    begin vj[i]<=cdb_data; qj[i]<=`TAG_NONE; end
                if (busy[i]&&qk[i]!=`TAG_NONE&&qk[i]==cdb_tag&&cdb_valid)
                    begin vk[i]<=cdb_data; qk[i]<=`TAG_NONE; end
            end
            if (issue_valid&&issue_ack) busy[rs]<=0;
            if (disp_valid&&!rs_full) begin
                busy[free_slot]<=1; opc[free_slot]<=disp_opcode;
                tag[free_slot]<=disp_tag;
                // CDB same-cycle capture: if CDB fires on our source tag this
                // very cycle, take the value now — the entry isn't busy yet so
                // the snoop loop above won't catch it.
                vj[free_slot] <= (cdb_valid && disp_qj!=`TAG_NONE && disp_qj==cdb_tag)
                                  ? cdb_data : disp_vj;
                vk[free_slot] <= (cdb_valid && disp_qk!=`TAG_NONE && disp_qk==cdb_tag)
                                  ? cdb_data : disp_vk;
                qj[free_slot] <= (cdb_valid && disp_qj!=`TAG_NONE && disp_qj==cdb_tag)
                                  ? `TAG_NONE : disp_qj;
                qk[free_slot] <= (cdb_valid && disp_qk!=`TAG_NONE && disp_qk==cdb_tag)
                                  ? `TAG_NONE : disp_qk;
                imm[free_slot]<=disp_imm;
            end
        end
    end
endmodule
