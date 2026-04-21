`ifndef OOO_PKG_V
`define OOO_PKG_V
`define DATA_WIDTH  32
`define REG_BITS     4
`define ROB_DEPTH   15
`define ROB_BITS     4
`define TAG_NONE    4'hF
`define DMEM_DEPTH 256
`define RS_ALU_DEPTH 4
`define RS_MUL_DEPTH 2
`define RS_LSU_DEPTH 2
`define RS_BRU_DEPTH 2
`define OP_ADD  4'h0
`define OP_ADDI 4'h1
`define OP_SUB  4'h2
`define OP_AND  4'h3
`define OP_OR   4'h4
`define OP_XOR  4'h5
`define OP_SHL  4'h6
`define OP_SHR  4'h7
`define OP_MUL  4'h8
`define OP_DIV  4'h9
`define OP_LD   4'hA
`define OP_ST   4'hB
`define OP_BEQ  4'hC
`define OP_BNE  4'hD
`define OP_BLT  4'hE
`define OP_JMP  4'hF
`define FU_ALU  2'b00
`define FU_MUL  2'b01
`define FU_LSU  2'b10
`define FU_BRU  2'b11
`endif
