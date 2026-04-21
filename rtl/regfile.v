`include "ooo_pkg.v"
module regfile (
    input  wire                   clk,
    input  wire                   rst_n,
    input  wire [`REG_BITS-1:0]   rs1,
    input  wire [`REG_BITS-1:0]   rs2,
    output wire [`DATA_WIDTH-1:0] rd1,
    output wire [`DATA_WIDTH-1:0] rd2,
    input  wire                   we,
    input  wire [`REG_BITS-1:0]   wd_addr,
    input  wire [`DATA_WIDTH-1:0] wd
);
    reg [`DATA_WIDTH-1:0] regs [0:15];
    integer i;
    initial for (i=0;i<16;i=i+1) regs[i]=0;
    always @(posedge clk)
        if (we && wd_addr!=0) regs[wd_addr] <= wd;
    assign rd1 = (we && wd_addr==rs1 && rs1!=0) ? wd : regs[rs1];
    assign rd2 = (we && wd_addr==rs2 && rs2!=0) ? wd : regs[rs2];
endmodule
