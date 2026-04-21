`include "rtl/ooo_pkg.v"
`timescale 1ns/1ps
module ooo_tb;
    reg clk, rst_n;
    ooo_top dut(.clk(clk),.rst_n(rst_n));
    always #5 clk=~clk;
    integer pass=0,fail=0;
    task check;
        input [`REG_BITS-1:0]   reg_id;
        input [`DATA_WIDTH-1:0] expected;
        input [8*12-1:0]        label;
        begin
            if (dut.u_regfile.regs[reg_id]===expected) begin
                $display("PASS [%s] R%0d = %0d",label,reg_id,expected); pass=pass+1;
            end else begin
                $display("FAIL [%s] R%0d expected %0d, got %0d",
                    label,reg_id,expected,dut.u_regfile.regs[reg_id]); fail=fail+1;
            end
        end
    endtask
    always @(posedge clk) begin
        if (dut.commit_valid)
            $display("t=%0t COMMIT rd=R%0d val=%0d is_st=%0b st_addr=%0d st_data=%0d",
                $time,dut.commit_rd,dut.commit_data,
                dut.commit_is_store,dut.commit_store_addr,dut.commit_store_data);
        if (dut.cdb_valid)
            $display("t=%0t CDB tag=%0d val=%0d",$time,dut.cdb_tag,dut.cdb_data);
        if (dut.lsu_iv)
            $display("t=%0t LSU_ISSUE op=%0d tag=%0d vj=%0d imm=%0d",
                $time,dut.lsu_iopc,dut.lsu_itag,dut.lsu_ivj,dut.lsu_iimm);
        if (dut.lcv)
            $display("t=%0t LSU_CDB tag=%0d val=%0d",$time,dut.lct,dut.lcd);
        if (dut.commit_valid&&dut.commit_is_store)
            $display("t=%0t ST_COMMIT addr=%0d data=%0d",
                $time,dut.commit_store_addr,dut.commit_store_data);
        if (dut.branch_taken)
            $display("t=%0t BRANCH_TAKEN target=%0d",$time,dut.branch_target);
    end
    initial begin
        $dumpfile("sim/ooo_core.vcd"); $dumpvars(0,ooo_tb);
        clk=0; rst_n=0; #15 rst_n=1;
        #8000; // wait 8000ns = 800 cycles
        $display("\n=== OOO Pipeline Engine Results ===");
        check(3,  32'd8,  "ADD chain   ");
        check(5,  32'd7,  "SUB dep     ");
        check(8,  32'd20, "MUL 3-cycle ");
        check(9,  32'd99, "ADD ooo     ");
        check(12, 32'd42, "LD/ST       ");
        check(15, 32'd77, "BEQ no-take ");
        $display("\nPASS: %0d / FAIL: %0d",pass,fail);
        $finish;
    end
endmodule
