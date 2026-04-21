`include "ooo_pkg.v"
module rob (
    input  wire                   clk, rst_n, flush,
    input  wire                   disp_valid,
    input  wire [3:0]             disp_opcode,
    input  wire [`REG_BITS-1:0]   disp_rd,
    input  wire [15:0]            disp_pc,
    output wire                   disp_ready,
    output wire [`ROB_BITS-1:0]   disp_tag,
    input  wire                   cdb_valid,
    input  wire [`ROB_BITS-1:0]   cdb_tag,
    input  wire [`DATA_WIDTH-1:0] cdb_data,
    input  wire                   st_wb_valid,
    input  wire [`ROB_BITS-1:0]   st_wb_tag,
    input  wire [`DATA_WIDTH-1:0] st_wb_addr,
    input  wire [`DATA_WIDTH-1:0] st_wb_data,
    output wire                   commit_valid,
    output wire [`REG_BITS-1:0]   commit_rd,
    output wire [`DATA_WIDTH-1:0] commit_data,
    output wire                   commit_is_store,
    output wire [`DATA_WIDTH-1:0] commit_store_addr,
    output wire [`DATA_WIDTH-1:0] commit_store_data,
    output wire [15:0]            commit_pc,
    input  wire [`REG_BITS-1:0]   rat_rs1, rat_rs2,
    output wire [`ROB_BITS-1:0]   rat_tag1, rat_tag2,
    output wire                   rat_ready1, rat_ready2,
    output wire [`DATA_WIDTH-1:0] rat_val1, rat_val2,
    output wire                   full, empty,
    output wire                   st_pending
);
    reg                   valid   [`ROB_DEPTH-1:0];
    reg [3:0]             opcode  [`ROB_DEPTH-1:0];
    reg [`REG_BITS-1:0]   rd_r    [`ROB_DEPTH-1:0];
    reg [`DATA_WIDTH-1:0] value   [`ROB_DEPTH-1:0];
    reg                   ready   [`ROB_DEPTH-1:0];
    reg [15:0]            pc_r    [`ROB_DEPTH-1:0];
    reg [`DATA_WIDTH-1:0] st_addr [`ROB_DEPTH-1:0];
    reg [`DATA_WIDTH-1:0] st_data [`ROB_DEPTH-1:0];
    reg                   st_exec [`ROB_DEPTH-1:0];
    reg [`ROB_BITS-1:0]   head, tail;
    reg [4:0]             count;
    integer i;

    assign full       = (count==`ROB_DEPTH);
    assign empty      = (count==0);
    assign disp_ready = !full;
    assign disp_tag   = tail;

    wire do_disp    = disp_valid && !full;
    wire head_is_st = !empty && (opcode[head]==`OP_ST);
    wire head_ready = !empty && (head_is_st ? st_exec[head] : ready[head]);
    wire do_commit  = head_ready;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n||flush) begin
            head<=0; tail<=0; count<=0;
            for (i=0;i<`ROB_DEPTH;i=i+1) begin
                valid[i]<=0; ready[i]<=0; st_exec[i]<=0;
            end
        end else begin
            if (cdb_valid) begin
                value[cdb_tag] <= cdb_data;
                ready[cdb_tag] <= 1;
            end
            if (st_wb_valid) begin
                st_addr[st_wb_tag] <= st_wb_addr;
                st_data[st_wb_tag] <= st_wb_data;
                st_exec[st_wb_tag] <= 1;
                ready  [st_wb_tag] <= 1;
            end
            if (do_disp) begin
                valid  [tail]<=1; opcode[tail]<=disp_opcode;
                rd_r   [tail]<=disp_rd; value[tail]<=0;
                ready  [tail]<=0; st_exec[tail]<=0; pc_r[tail]<=disp_pc;
                tail<=(tail==`ROB_DEPTH-1)?{`ROB_BITS{1'b0}}:tail+1;
            end
            if (do_commit) begin
                valid  [head]<=0; ready[head]<=0; st_exec[head]<=0;
                rd_r   [head]<=0;
                head<=(head==`ROB_DEPTH-1)?{`ROB_BITS{1'b0}}:head+1;
            end
            case ({do_disp,do_commit})
                2'b10: count<=count+1;
                2'b01: count<=count-1;
                default: count<=count;
            endcase
        end
    end

    assign commit_valid      = do_commit;
    assign commit_rd         = rd_r[head];
    assign commit_data       = value[head];
    assign commit_is_store   = head_is_st;
    assign commit_store_addr = st_addr[head];
    assign commit_store_data = st_data[head];
    assign commit_pc         = pc_r[head];

    // st_pending: ST in ROB not yet executed by LSU
    reg st_pend_r;
    integer p;
    always @(*) begin
        st_pend_r=0;
        for (p=0;p<`ROB_DEPTH;p=p+1)
            if (valid[p] && opcode[p]==`OP_ST && !st_exec[p])
                st_pend_r=1;
    end
    assign st_pending=st_pend_r;

    // RAT: youngest matching entry wins (no found guard = last write wins)
    reg [`ROB_BITS-1:0] tag1_r, tag2_r;
    reg                 rdy1_r, rdy2_r;
    reg [`DATA_WIDTH-1:0] val1_r, val2_r;
    integer j;
    always @(*) begin
        tag1_r=`TAG_NONE; rdy1_r=0; val1_r=0;
        tag2_r=`TAG_NONE; rdy2_r=0; val2_r=0;
        for (j=0;j<`ROB_DEPTH;j=j+1) begin
            if (valid[j] && rd_r[j]==rat_rs1 && rat_rs1!=0)
                begin tag1_r=j[`ROB_BITS-1:0]; rdy1_r=ready[j]; val1_r=value[j]; end
            if (valid[j] && rd_r[j]==rat_rs2 && rat_rs2!=0)
                begin tag2_r=j[`ROB_BITS-1:0]; rdy2_r=ready[j]; val2_r=value[j]; end
        end
    end
    assign rat_tag1=tag1_r; assign rat_tag2=tag2_r;
    assign rat_ready1=rdy1_r; assign rat_ready2=rdy2_r;
    assign rat_val1=val1_r; assign rat_val2=val2_r;
endmodule
