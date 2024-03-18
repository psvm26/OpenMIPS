`include "defines.v"
module pc_reg (
    input wire clk,
    input wire rst,
    input wire [5:0] stall,         //���Կ���ģ��CTRL
    //��������׶�IDģ�����Ϣ

    input wire branch_flag_i,       //�Ƿ���ת��
    input wire [`RegBus] branch_target_address_i,//ת�Ƶ���Ŀ���ַ

    output reg [`InstAddrBus] pc,   //Ҫ��ȡ��ָ���ַ
    output reg ce                    //ָ��洢��ʹ���ź�
);
    always @(posedge clk) begin
        if(rst == `RstEnable) begin
            ce <= `ChipDisable;     //��λʱ���ô�����
        end else begin
            ce <= `ChipEnable;      //��λ����������ʹ��
        end
    end 

    always @(posedge clk) begin
        if(ce == `ChipDisable) begin
            pc <= 32'h0000_0000;
        end else if(stall[0] == `NoStop) begin  //��stallΪNoStopʱpc��4������pc����
            if(branch_flag_i == `Branch) begin
                pc <= branch_target_address_i;
            end else begin
            pc <= pc + 4;           //������ʹ��ʱÿ����pc��4
            end
        end
    end
endmodule