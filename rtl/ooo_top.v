`include "ooo_pkg.v"
module ooo_top (input wire clk, input wire rst_n);
    wire cdb_valid; wire [`ROB_BITS-1:0] cdb_tag; wire [`DATA_WIDTH-1:0] cdb_data;
    wire branch_taken; wire [15:0] branch_target;
    wire flush=branch_taken;
    wire rob_full,rs_alu_full,rs_mul_full,rs_lsu_full,rs_bru_full;
    wire stall=rob_full|rs_alu_full|rs_mul_full|rs_lsu_full|rs_bru_full;
    wire st_pending;
    wire [31:0] instr; wire [15:0] fetch_pc; wire fetch_valid;
    wire disp_valid; wire [3:0] disp_opcode; wire [`REG_BITS-1:0] disp_rd;
    wire [15:0] disp_pc; wire [`ROB_BITS-1:0] disp_tag;
    wire [`DATA_WIDTH-1:0] disp_vj,disp_vk;
    wire [`ROB_BITS-1:0] disp_qj,disp_qk; wire [15:0] disp_imm; wire [1:0] disp_fu;
    wire disp_to_alu=disp_valid&&disp_fu==`FU_ALU;
    wire disp_to_mul=disp_valid&&disp_fu==`FU_MUL;
    wire disp_to_lsu=disp_valid&&disp_fu==`FU_LSU;
    wire disp_to_bru=disp_valid&&disp_fu==`FU_BRU;
    wire rob_disp_ready; wire [`ROB_BITS-1:0] rob_disp_tag;
    wire commit_valid; wire [`REG_BITS-1:0] commit_rd; wire [`DATA_WIDTH-1:0] commit_data;
    wire commit_is_store; wire [`DATA_WIDTH-1:0] commit_store_addr,commit_store_data;
    wire [15:0] commit_pc;
    wire st_wb_valid; wire [`ROB_BITS-1:0] st_wb_tag;
    wire [`DATA_WIDTH-1:0] st_wb_addr,st_wb_data;
    wire [`REG_BITS-1:0] rat_rs1_w,rat_rs2_w;
    wire [`ROB_BITS-1:0] rat_tag1,rat_tag2;
    wire rat_ready1,rat_ready2;
    wire [`DATA_WIDTH-1:0] rat_val1,rat_val2;
    wire [`REG_BITS-1:0] rf_rs1,rf_rs2; wire [`DATA_WIDTH-1:0] rf_rd1,rf_rd2;
    wire alu_iv,alu_ack; wire [3:0] alu_iopc; wire [`ROB_BITS-1:0] alu_itag;
    wire [`DATA_WIDTH-1:0] alu_ivj,alu_ivk; wire [15:0] alu_iimm;
    wire mul_iv,mul_ack; wire [3:0] mul_iopc; wire [`ROB_BITS-1:0] mul_itag;
    wire [`DATA_WIDTH-1:0] mul_ivj,mul_ivk; wire [15:0] mul_iimm;
    wire lsu_iv,lsu_ack; wire [3:0] lsu_iopc; wire [`ROB_BITS-1:0] lsu_itag;
    wire [`DATA_WIDTH-1:0] lsu_ivj,lsu_ivk; wire [15:0] lsu_iimm;
    wire bru_iv,bru_ack; wire [3:0] bru_iopc; wire [`ROB_BITS-1:0] bru_itag;
    wire [`DATA_WIDTH-1:0] bru_ivj,bru_ivk; wire [15:0] bru_iimm;
    wire [15:0] bru_ipc;
    wire acv; wire [`ROB_BITS-1:0] act; wire [`DATA_WIDTH-1:0] acd;
    wire mcv; wire [`ROB_BITS-1:0] mct; wire [`DATA_WIDTH-1:0] mcd;
    wire lcv; wire [`ROB_BITS-1:0] lct; wire [`DATA_WIDTH-1:0] lcd;
    wire bcv; wire [`ROB_BITS-1:0] bct; wire [`DATA_WIDTH-1:0] bcd;

    fetch u_fetch(.clk(clk),.rst_n(rst_n),.stall(stall),.flush(flush),
        .branch_taken(branch_taken),.branch_target(branch_target),
        .pc_out(fetch_pc),.instr_out(instr),.fetch_valid(fetch_valid));
    decode u_decode(.clk(clk),.rst_n(rst_n),.flush(flush),.stall(stall),
        .instr(instr),.pc_in(fetch_pc),.fetch_valid(fetch_valid),
        .rs1(rf_rs1),.rs2(rf_rs2),.rf_rd1(rf_rd1),.rf_rd2(rf_rd2),
        .rat_rs1(rat_rs1_w),.rat_rs2(rat_rs2_w),
        .rat_tag1(rat_tag1),.rat_tag2(rat_tag2),
        .rat_ready1(rat_ready1),.rat_ready2(rat_ready2),
        .rat_val1(rat_val1),.rat_val2(rat_val2),
        .rob_ready(rob_disp_ready),.rob_tag(rob_disp_tag),
        .disp_valid(disp_valid),.disp_opcode(disp_opcode),
        .disp_rd(disp_rd),.disp_pc(disp_pc),.disp_tag(disp_tag),
        .disp_vj(disp_vj),.disp_vk(disp_vk),
        .disp_qj(disp_qj),.disp_qk(disp_qk),
        .disp_imm(disp_imm),.disp_fu(disp_fu));
    regfile u_regfile(.clk(clk),.rst_n(rst_n),
        .rs1(rf_rs1),.rs2(rf_rs2),.rd1(rf_rd1),.rd2(rf_rd2),
        .we(commit_valid&&!commit_is_store),.wd_addr(commit_rd),.wd(commit_data));
    rob u_rob(.clk(clk),.rst_n(rst_n),.flush(flush),
        .disp_valid(disp_valid),.disp_opcode(disp_opcode),
        .disp_rd(disp_rd),.disp_pc(disp_pc),
        .disp_ready(rob_disp_ready),.disp_tag(rob_disp_tag),
        .cdb_valid(cdb_valid),.cdb_tag(cdb_tag),.cdb_data(cdb_data),
        .st_wb_valid(st_wb_valid),.st_wb_tag(st_wb_tag),
        .st_wb_addr(st_wb_addr),.st_wb_data(st_wb_data),
        .commit_valid(commit_valid),.commit_rd(commit_rd),
        .commit_data(commit_data),.commit_is_store(commit_is_store),
        .commit_store_addr(commit_store_addr),.commit_store_data(commit_store_data),
        .commit_pc(commit_pc),
        .rat_rs1(rat_rs1_w),.rat_rs2(rat_rs2_w),
        .rat_tag1(rat_tag1),.rat_tag2(rat_tag2),
        .rat_ready1(rat_ready1),.rat_ready2(rat_ready2),
        .rat_val1(rat_val1),.rat_val2(rat_val2),
        .full(rob_full),.empty(),.st_pending(st_pending));
    rs_alu u_rs_alu(.clk(clk),.rst_n(rst_n),.flush(flush),
        .disp_valid(disp_to_alu),.disp_opcode(disp_opcode),
        .disp_tag(disp_tag),.disp_vj(disp_vj),.disp_vk(disp_vk),
        .disp_qj(disp_qj),.disp_qk(disp_qk),.disp_imm(disp_imm),
        .rs_full(rs_alu_full),.cdb_valid(cdb_valid),.cdb_tag(cdb_tag),.cdb_data(cdb_data),
        .issue_valid(alu_iv),.issue_opcode(alu_iopc),.issue_tag(alu_itag),
        .issue_vj(alu_ivj),.issue_vk(alu_ivk),.issue_imm(alu_iimm),.issue_ack(alu_ack));
    rs_mul u_rs_mul(.clk(clk),.rst_n(rst_n),.flush(flush),
        .disp_valid(disp_to_mul),.disp_opcode(disp_opcode),
        .disp_tag(disp_tag),.disp_vj(disp_vj),.disp_vk(disp_vk),
        .disp_qj(disp_qj),.disp_qk(disp_qk),.disp_imm(disp_imm),
        .rs_full(rs_mul_full),.cdb_valid(cdb_valid),.cdb_tag(cdb_tag),.cdb_data(cdb_data),
        .issue_valid(mul_iv),.issue_opcode(mul_iopc),.issue_tag(mul_itag),
        .issue_vj(mul_ivj),.issue_vk(mul_ivk),.issue_imm(mul_iimm),.issue_ack(mul_ack));
    rs_lsu u_rs_lsu(.clk(clk),.rst_n(rst_n),.flush(flush),
        .disp_valid(disp_to_lsu),.disp_opcode(disp_opcode),
        .disp_tag(disp_tag),.disp_vj(disp_vj),.disp_vk(disp_vk),
        .disp_qj(disp_qj),.disp_qk(disp_qk),.disp_imm(disp_imm),
        .rs_full(rs_lsu_full),.st_pending(st_pending),
        .cdb_valid(cdb_valid),.cdb_tag(cdb_tag),.cdb_data(cdb_data),
        .issue_valid(lsu_iv),.issue_opcode(lsu_iopc),.issue_tag(lsu_itag),
        .issue_vj(lsu_ivj),.issue_vk(lsu_ivk),.issue_imm(lsu_iimm),.issue_ack(lsu_ack));
    rs_bru u_rs_bru(.clk(clk),.rst_n(rst_n),.flush(flush),
        .disp_valid(disp_to_bru),.disp_opcode(disp_opcode),
        .disp_tag(disp_tag),.disp_vj(disp_vj),.disp_vk(disp_vk),
        .disp_qj(disp_qj),.disp_qk(disp_qk),.disp_imm(disp_imm),
        .disp_pc(disp_pc),
        .rs_full(rs_bru_full),.cdb_valid(cdb_valid),.cdb_tag(cdb_tag),.cdb_data(cdb_data),
        .issue_valid(bru_iv),.issue_opcode(bru_iopc),.issue_tag(bru_itag),
        .issue_vj(bru_ivj),.issue_vk(bru_ivk),.issue_imm(bru_iimm),
        .issue_pc(bru_ipc),.issue_ack(bru_ack));
    alu_unit u_alu(.clk(clk),.rst_n(rst_n),.flush(flush),
        .issue_valid(alu_iv),.issue_opcode(alu_iopc),.issue_tag(alu_itag),
        .issue_vj(alu_ivj),.issue_vk(alu_ivk),.issue_imm(alu_iimm),.issue_ack(alu_ack),
        .cdb_valid(acv),.cdb_tag(act),.cdb_data(acd));
    mul_unit u_mul(.clk(clk),.rst_n(rst_n),.flush(flush),
        .issue_valid(mul_iv),.issue_opcode(mul_iopc),.issue_tag(mul_itag),
        .issue_vj(mul_ivj),.issue_vk(mul_ivk),.issue_imm(mul_iimm),.issue_ack(mul_ack),
        .cdb_valid(mcv),.cdb_tag(mct),.cdb_data(mcd));
    lsu_unit u_lsu(.clk(clk),.rst_n(rst_n),.flush(flush),
        .issue_valid(lsu_iv),.issue_opcode(lsu_iopc),.issue_tag(lsu_itag),
        .issue_vj(lsu_ivj),.issue_vk(lsu_ivk),.issue_imm(lsu_iimm),.issue_ack(lsu_ack),
        .st_wb_valid(st_wb_valid),.st_wb_tag(st_wb_tag),
        .st_wb_addr(st_wb_addr),.st_wb_data(st_wb_data),
        .commit_store(commit_valid&&commit_is_store),
        .commit_store_addr(commit_store_addr),.commit_store_data(commit_store_data),
        .cdb_valid(lcv),.cdb_tag(lct),.cdb_data(lcd));
    bru_unit u_bru(.clk(clk),.rst_n(rst_n),.flush(flush),
        .issue_valid(bru_iv),.issue_opcode(bru_iopc),.issue_tag(bru_itag),
        .issue_vj(bru_ivj),.issue_vk(bru_ivk),.issue_imm(bru_iimm),
        .issue_pc(bru_ipc),.issue_ack(bru_ack),
        .cdb_valid(bcv),.cdb_tag(bct),.cdb_data(bcd),
        .branch_taken(branch_taken),.branch_target(branch_target));
    cdb_arbiter u_cdb(.clk(clk),.rst_n(rst_n),.flush(flush),
        .alu_valid(acv),.alu_tag(act),.alu_data(acd),
        .mul_valid(mcv),.mul_tag(mct),.mul_data(mcd),
        .lsu_valid(lcv),.lsu_tag(lct),.lsu_data(lcd),
        .bru_valid(bcv),.bru_tag(bct),.bru_data(bcd),
        .cdb_valid(cdb_valid),.cdb_tag(cdb_tag),.cdb_data(cdb_data));
endmodule
