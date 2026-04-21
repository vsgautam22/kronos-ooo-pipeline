`include "ooo_pkg.v"
module decode (
    input  wire        clk, rst_n, flush, stall,
    input  wire [31:0] instr,
    input  wire [15:0] pc_in,
    input  wire        fetch_valid,

    output wire [`REG_BITS-1:0]   rs1, rs2,
    input  wire [`DATA_WIDTH-1:0] rf_rd1, rf_rd2,

    output wire [`REG_BITS-1:0]   rat_rs1, rat_rs2,
    input  wire [`ROB_BITS-1:0]   rat_tag1, rat_tag2,
    input  wire                   rat_ready1, rat_ready2,
    input  wire [`DATA_WIDTH-1:0] rat_val1, rat_val2,

    input  wire                   rob_ready,
    input  wire [`ROB_BITS-1:0]   rob_tag,

    output wire                   disp_valid,
    output wire [3:0]             disp_opcode,
    output wire [`REG_BITS-1:0]   disp_rd,
    output wire [15:0]            disp_pc,
    output wire [`ROB_BITS-1:0]   disp_tag,
    output wire [`DATA_WIDTH-1:0] disp_vj, disp_vk,
    output wire [`ROB_BITS-1:0]   disp_qj, disp_qk,
    output wire [15:0]            disp_imm,
    output wire [1:0]             disp_fu
);
    // Decode instruction fields combinationally
    wire [3:0]  opcode = instr[31:28];
    wire [3:0]  rrd    = instr[27:24];
    wire [3:0]  rrs1   = instr[23:20];
    wire [3:0]  rrs2   = instr[19:16];
    wire [15:0] imm    = instr[15:0];

    // FU select
    reg [1:0] fu;
    always @(*) case (opcode)
        `OP_MUL, `OP_DIV:                    fu = `FU_MUL;
        `OP_LD,  `OP_ST:                     fu = `FU_LSU;
        `OP_BEQ, `OP_BNE, `OP_BLT, `OP_JMP: fu = `FU_BRU;
        default:                             fu = `FU_ALU;
    endcase

    // Drive regfile and RAT read ports combinationally
    assign rs1     = rrs1;
    assign rs2     = rrs2;
    assign rat_rs1 = rrs1;
    assign rat_rs2 = rrs2;

    // Operand resolution: RAT takes priority over regfile
    // VJ: if RAT has a pending tag use it, else use regfile
    wire [`DATA_WIDTH-1:0] vj_comb =
        (rat_tag1 != `TAG_NONE && rat_ready1) ? rat_val1 : rf_rd1;
    wire [`ROB_BITS-1:0] qj_comb =
        (rat_tag1 != `TAG_NONE && !rat_ready1) ? rat_tag1 : `TAG_NONE;

    // VK: for ADDI use sign-extended immediate; else RAT/regfile
    wire [`DATA_WIDTH-1:0] vk_comb =
        (opcode == `OP_ADDI) ? {{16{imm[15]}}, imm} :
        (rat_tag2 != `TAG_NONE && rat_ready2) ? rat_val2 : rf_rd2;
    wire [`ROB_BITS-1:0] qk_comb =
        (opcode == `OP_ADDI) ? `TAG_NONE :
        (rat_tag2 != `TAG_NONE && !rat_ready2) ? rat_tag2 : `TAG_NONE;

    // Dispatch is valid when fetch produced an instruction,
    // ROB has space, and pipeline isn't flushing or stalling
    assign disp_valid  = fetch_valid && rob_ready && !flush && !stall;
    assign disp_opcode = opcode;
    assign disp_rd     = rrd;
    assign disp_pc     = pc_in;
    assign disp_tag    = rob_tag;
    assign disp_vj     = vj_comb;
    assign disp_vk     = vk_comb;
    assign disp_qj     = qj_comb;
    assign disp_qk     = qk_comb;
    assign disp_imm    = imm;
    assign disp_fu     = fu;
endmodule
