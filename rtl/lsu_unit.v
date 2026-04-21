`include "ooo_pkg.v"
module lsu_unit (
    input  wire                   clk, rst_n, flush,
    input  wire                   issue_valid,
    input  wire [3:0]             issue_opcode,
    input  wire [`ROB_BITS-1:0]   issue_tag,
    input  wire [`DATA_WIDTH-1:0] issue_vj, issue_vk,
    input  wire [15:0]            issue_imm,
    output wire                   issue_ack,
    output reg                    st_wb_valid,
    output reg  [`ROB_BITS-1:0]   st_wb_tag,
    output reg  [`DATA_WIDTH-1:0] st_wb_addr,
    output reg  [`DATA_WIDTH-1:0] st_wb_data,
    input  wire                   commit_store,
    input  wire [`DATA_WIDTH-1:0] commit_store_addr,
    input  wire [`DATA_WIDTH-1:0] commit_store_data,
    output reg                    cdb_valid,
    output reg  [`ROB_BITS-1:0]   cdb_tag,
    output reg  [`DATA_WIDTH-1:0] cdb_data
);
    reg [`DATA_WIDTH-1:0] dmem [0:`DMEM_DEPTH-1];
    integer k;
    initial for(k=0;k<`DMEM_DEPTH;k=k+1) dmem[k]=0;

    // One-shot handshake: accept only on first cycle issue_valid goes high
    reg in_flight;
    assign issue_ack = issue_valid && !in_flight;

    wire [`DATA_WIDTH-1:0] eff_addr = issue_vj + {{16{issue_imm[15]}},issue_imm};
    wire [7:0] widx = eff_addr[9:2];

    reg s1_v; reg [3:0] s1_opc; reg [`ROB_BITS-1:0] s1_tag;
    reg [7:0] s1_idx; reg [`DATA_WIDTH-1:0] s1_vk,s1_addr;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n||flush) begin
            s1_v<=0; cdb_valid<=0; st_wb_valid<=0; in_flight<=0;
        end else begin
            // Track in-flight: set when accepted, clear when issue_valid drops
            if (issue_valid && !in_flight)      in_flight<=1;
            else if (!issue_valid)              in_flight<=0;

            // Stage 1: latch on accept
            if (issue_valid && !in_flight) begin
                s1_v<=1; s1_opc<=issue_opcode; s1_tag<=issue_tag;
                s1_idx<=widx; s1_vk<=issue_vk; s1_addr<=eff_addr;
            end else s1_v<=0;

            // Stage 2: execute
            cdb_valid<=0; st_wb_valid<=0;
            if (s1_v) begin
                if (s1_opc==`OP_LD) begin
                    cdb_valid<=1; cdb_tag<=s1_tag; cdb_data<=dmem[s1_idx];
                end else begin
                    dmem[s1_addr[9:2]]<=s1_vk;   // write dmem at execute
                    st_wb_valid<=1; st_wb_tag<=s1_tag;
                    st_wb_addr<=s1_addr; st_wb_data<=s1_vk;
                end
            end
        end
    end
endmodule
