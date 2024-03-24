`include "defines.v"
module inst_rom (
    input wire ce,
    input wire [`InstAddrBus] addr,
    output reg [`InstBus] inst
);
    //ָ��洢��
    reg [`InstBus] inst_mem[0: `InstMemNum - 1];
    //ʹ���ļ�inst_rom.data��ʼ��ָ��洢��
    initial $readmemh("D:/cs/cpu/OpenMIPS/inst_rom/inst_rom9_3.data", inst_mem);

    //����λ�ź���Чʱ����������ĵ�ַ������������rom�ж�Ӧ��Ԫ��
    always @(*) begin
        if(ce == `ChipDisable) begin
            inst <= `ZeroWord;
        end else begin
            inst <= inst_mem[addr[`InstMemNumLog2 + 1: 2]];
        end
    end

endmodule