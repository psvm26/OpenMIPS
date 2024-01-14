`include "defines.v"
module regfile (
    input wire clk,
    input wire rst,
    //д�˿�
    input wire we,                  //дʹ��
    input wire [`RegAddrBus] waddr, //д�Ĵ�����ַ
    input wire [`RegBus] wdata,     //д����
    //���˿�1
    input wire re1,                  //��ʹ��1
    input wire [`RegAddrBus] raddr1, //���Ĵ�����ַ1
    output reg [`RegBus] rdata1,     //������1
    //���˿�2
    input wire re2,                  //��ʹ��2
    input wire [`RegAddrBus] raddr2, //���Ĵ�����ַ2
    output reg [`RegBus] rdata2      //������2
);
    //һ������32��32λ�Ĵ���
    reg [`RegBus] regs[0:`RegNum - 1];

    //����д����
    always @(posedge clk) begin
        if(rst == `RstDisable) begin
            if((we == `WriteEnable) && (waddr != `RegNumLog2'h0)) begin
                regs[waddr] <= wdata;
            end
        end
    end

    //�������˿�1
    always @(*) begin
        if(rst == `RstEnable) begin
            rdata1 <= `ZeroWord;
        end else if(raddr1 == `RegNumLog2'h0) begin
            rdata1 <= `ZeroWord;
        end else if((raddr1 == waddr) && (we == `WriteEnable)
                    && (re1 == `ReadEnable)) begin
            rdata1 <= wdata;
        end else if (re1 == `ReadEnable) begin
            rdata1 <= regs[raddr1];
        end else begin
            rdata1 <= `ZeroWord;
        end
    end

    //�ģ����˿�2
    always @(*) begin
        if(rst == `RstEnable) begin
            rdata2 <= `ZeroWord;
        end else if(raddr2 == `RegNumLog2'h0) begin
            rdata2 <= `ZeroWord;
        end else if((raddr2 == waddr) && (we == `WriteEnable)
                    && (re2 == `ReadEnable)) begin
            rdata2 <= wdata;
        end else if (re2 == `ReadEnable) begin
            rdata2 <= regs[raddr2];
        end else begin
            rdata2 <= `ZeroWord;
        end
    end
    
endmodule