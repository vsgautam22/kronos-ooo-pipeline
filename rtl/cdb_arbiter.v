`include "ooo_pkg.v"
module cdb_arbiter (
    input  wire                   clk, rst_n, flush,
    input  wire                   alu_valid,mul_valid,lsu_valid,bru_valid,
    input  wire [`ROB_BITS-1:0]   alu_tag,mul_tag,lsu_tag,bru_tag,
    input  wire [`DATA_WIDTH-1:0] alu_data,mul_data,lsu_data,bru_data,
    output reg                    cdb_valid,
    output reg  [`ROB_BITS-1:0]   cdb_tag,
    output reg  [`DATA_WIDTH-1:0] cdb_data
);
    reg [1:0] rr;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n||flush) begin cdb_valid<=0; rr<=0; end
        else begin
            cdb_valid<=0;
            case(rr)
            0: if(alu_valid)begin cdb_valid<=1;cdb_tag<=alu_tag;cdb_data<=alu_data;rr<=1;end
               else if(mul_valid)begin cdb_valid<=1;cdb_tag<=mul_tag;cdb_data<=mul_data;rr<=2;end
               else if(lsu_valid)begin cdb_valid<=1;cdb_tag<=lsu_tag;cdb_data<=lsu_data;rr<=3;end
               else if(bru_valid)begin cdb_valid<=1;cdb_tag<=bru_tag;cdb_data<=bru_data;rr<=0;end
            1: if(mul_valid)begin cdb_valid<=1;cdb_tag<=mul_tag;cdb_data<=mul_data;rr<=2;end
               else if(lsu_valid)begin cdb_valid<=1;cdb_tag<=lsu_tag;cdb_data<=lsu_data;rr<=3;end
               else if(bru_valid)begin cdb_valid<=1;cdb_tag<=bru_tag;cdb_data<=bru_data;rr<=0;end
               else if(alu_valid)begin cdb_valid<=1;cdb_tag<=alu_tag;cdb_data<=alu_data;rr<=1;end
            2: if(lsu_valid)begin cdb_valid<=1;cdb_tag<=lsu_tag;cdb_data<=lsu_data;rr<=3;end
               else if(bru_valid)begin cdb_valid<=1;cdb_tag<=bru_tag;cdb_data<=bru_data;rr<=0;end
               else if(alu_valid)begin cdb_valid<=1;cdb_tag<=alu_tag;cdb_data<=alu_data;rr<=1;end
               else if(mul_valid)begin cdb_valid<=1;cdb_tag<=mul_tag;cdb_data<=mul_data;rr<=2;end
            3: if(bru_valid)begin cdb_valid<=1;cdb_tag<=bru_tag;cdb_data<=bru_data;rr<=0;end
               else if(alu_valid)begin cdb_valid<=1;cdb_tag<=alu_tag;cdb_data<=alu_data;rr<=1;end
               else if(mul_valid)begin cdb_valid<=1;cdb_tag<=mul_tag;cdb_data<=mul_data;rr<=2;end
               else if(lsu_valid)begin cdb_valid<=1;cdb_tag<=lsu_tag;cdb_data<=lsu_data;rr<=3;end
            endcase
        end
    end
endmodule
