`include "defines.v"
module if_id (
    input wire clk,
    input wire rst,
    //取址阶段的信号
    input wire [`InstAddrBus] if_pc,
    input wire [`InstBus] if_inst,
    //暂停信号
    input wire [5:0] stall,
    //译码阶段的信号
    output reg [`InstAddrBus] id_pc,
    output reg [`InstBus] id_inst
);
    always @(posedge clk) begin
        if(rst == `RstEnable) begin
            id_pc <= `ZeroWord;
            id_inst <= `ZeroWord;
        end else if (stall[1] == `Stop && stall[2] == `NoStop) begin    //stall[1]为stop表示取值阶段暂停
            id_pc <= `ZeroWord;
            id_inst <= `ZeroWord;
        end else if (stall[1] == `NoStop) begin              //向下传递取址阶段的值
            id_pc <= if_pc;
            id_inst <= if_inst;
        end
    end
    
endmodule