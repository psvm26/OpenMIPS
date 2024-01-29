`include "defines.v"
module if_id (
    input wire clk,
    input wire rst,
    //ȡַ�׶ε��ź�
    input wire [`InstAddrBus] if_pc,
    input wire [`InstBus] if_inst,
    //��ͣ�ź�
    input wire [5:0] stall,
    //����׶ε��ź�
    output reg [`InstAddrBus] id_pc,
    output reg [`InstBus] id_inst
);
    always @(posedge clk) begin
        if(rst == `RstEnable) begin
            id_pc <= `ZeroWord;
            id_inst <= `ZeroWord;
        end else if (stall[1] == `Stop && stall[2] == `NoStop) begin    //stall[1]Ϊstop��ʾȡֵ�׶���ͣ
            id_pc <= `ZeroWord;
            id_inst <= `ZeroWord;
        end else if (stall[1] == `NoStop) begin              //���´���ȡַ�׶ε�ֵ
            id_pc <= if_pc;
            id_inst <= if_inst;
        end
    end
    
endmodule