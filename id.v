`include "defines.v"
module id (
    input wire rst,
    input wire [`InstAddrBus] pc_i,         //����׶�ָ���Ӧ�ĵ�ַ
    input wire [`InstBus] inst_i,           //����׶ε�ָ��
    //��ȡ��Regfile��ֵ
    input wire [`RegBus] reg1_data_i,       //���Ĵ����˿�1������
    input wire [`RegBus] reg2_data_i,       //���Ĵ����˿�2������
    //�����Regfile����Ϣ
    output reg reg1_read_o,                 //���Ĵ����˿�1��ʹ��
    output reg reg2_read_o,                 //���Ĵ����˿�2��ʹ��
    output reg [`RegAddrBus] reg1_addr_o,   //���Ĵ����˿�1�ĵ�ַ
    output reg [`RegAddrBus] reg2_addr_o,   //���Ĵ����˿�2�ĵ�ַ
    //�͵�ִ�н׶ε���Ϣ
    output reg [`AluOpBus] aluop_o,         //ִ�н׶������������
    output reg [`AluSelBus] alusel_o,       //ִ�н׶����������
    output reg [`RegBus] reg1_o,            //ִ�н׶������Դ������1
    output reg [`RegBus] reg2_o,            //ִ�н׶������Դ������2
    output reg [`RegAddrBus] wd_o,          //ִ�н׶�Ҫд���Ŀ�ļĴ�����ַ
    output reg wreg_o                       //ִ�н׶�ָ���Ƿ�Ҫд��Ĵ���
);
    
    //ȡ��ָ���ָ���롢������
    //����oriָ���ж�26-31λ��ֵ�����ж��Ƿ�Ϊoriָ��
    wire [5:0] op = inst_i[31:26];
    wire [4:0] op2 = inst_i[10:6];
    wire [5:0] op3 = inst_i[5:0];
    wire [4:0] op4 = inst_i[20:16];

    //����ָ��ִ������Ҫ��������
    reg[`RegBus] imm;

    //ָʾָ���Ƿ���Ч
    reg instvalid;

    //һ����ָ���������
    always @(*) begin
        if(rst == `RstEnable) begin
            aluop_o <= `EXE_NOP_OP;
            alusel_o <= `EXE_RES_NOP;
            wd_o <= `NOPRegAddr;
            wreg_o <= `WriteDisable;
            instvalid <= `InstValid;
            reg1_read_o <= 1'b0;
            reg2_read_o <= 1'b0;
            reg1_addr_o <= `NOPRegAddr;
            reg2_addr_o <= `NOPRegAddr;
            imm <= 32'h0;
        end else begin
            //��ʼ����
            aluop_o <= `EXE_NOP_OP;
            alusel_o <= `EXE_RES_NOP;
            wd_o <= inst_i[15:11];
            wreg_o <= `WriteDisable;
            instvalid <= `InstInvalid;
            reg1_read_o <= 1'b0;
            reg2_read_o <= 1'b0;
            reg1_addr_o <= inst_i[25:21];
            reg2_addr_o <= inst_i[20:16];
            imm <= `ZeroWord;

            case(op)
                `EXE_ORI:   begin                   //oriָ��
                    wreg_o <= `WriteEnable;         //��Ҫ�����д��Ŀ�ļĴ���
                    aluop_o <= `EXE_OR_OP;          //������Ϊ��������
                    alusel_o <= `EXE_RES_LOGIC;     //��������Ϊ�߼�����
                    reg1_read_o <= 1'b1;            //��Ҫregfile�Ķ��˿�1
                    reg2_read_o <= 1'b0;            //����Ҫ���˿�2
                    imm <= {16'h0, inst_i[15:0]};   //��ʹ��������
                    wd_o <= inst_i[20:16];          //ָ��ִ��Ҫд��Ŀ�ļĴ�����ַ
                    instvalid <= `InstValid;        //ָ����Ч
                end
                default:begin
                end
            endcase
        end
    end

    //����ȷ�����������Դ������1
    always @(*) begin
        if(rst == `RstEnable) begin
            reg1_o <= `ZeroWord;
        end else if(reg1_read_o == 1'b1) begin
            reg1_o <= reg1_data_i;
        end else if(reg1_read_o == 1'b0) begin
            reg1_o <= imm;
        end else begin
            reg1_o <= `ZeroWord;
        end
    end

    //����ȷ�����������Դ������1
    always @(*) begin
        if(rst == `RstEnable) begin
            reg2_o <= `ZeroWord;
        end else if(reg2_read_o == 1'b1) begin
            reg2_o <= reg2_data_i;
        end else if(reg2_read_o == 1'b0) begin
            reg2_o <= imm;
        end else begin
            reg2_o <= `ZeroWord;
        end
    end


endmodule