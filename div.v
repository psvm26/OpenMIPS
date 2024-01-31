`include "defines.v"

module div (
    input wire clk,
    input wire rst,

    input wire signed_div_i,        //�Ƿ��з��ų���
    input wire [31:0] opdata1_i,    //������
    input wire [31:0] opdata2_i,    //����
    input wire start_i,             //�Ƿ�ʼ��������
    input wire annul_i,             //�Ƿ�ȡ���������㣨Ϊ1ȡ����

    output reg [63:0] result_o,     //����������
    output reg ready_o              //���������Ƿ����
);

    wire [32:0] div_temp;
    reg [5:0] cnt;
    reg [64:0] dividend;
    reg [1:0] state;
    reg [31:0] divisor;
    reg [31:0] temp_op1;
    reg [31:0] temp_op2;

    //dividend�ĵ�32λ������Ǳ��������м�������k�ε���������dividend[k:0]
    //����ľ��ǵ�ǰ�õ����м�����dividend[31:k+1]����ľ��Ǳ������л�û��
    //������������ݣ�dividend��32λ��ÿ�ε���ʱ�ı��������˴����е���minuend-n
    //���㣬���������div_temp��
    assign div_temp = {1'b0, dividend[63:32]} - {1'b0, divisor};

    always @(posedge clk) begin
        if(rst == `RstEnable) begin
            state <= `DivFree;
            ready_o <= `DivResultNotReady;
            result_o <= {`ZeroWord, `ZeroWord};
        end else begin
            case(state)
                //DivFree״̬
                //��1����ʼ�������㣬������Ϊ0������DivByZero״̬
                //��2����ʼ�������ҳ�����Ϊ0����ô����DivOn״̬����ʼ��cntΪ0��
                //    ������з��ų������ұ����������Ϊ������ô�Ա���������������λȡ���롣
                //    ����������divisor�У��������������λ������dividend�ĵ�32λ�����е�һ�ε���
                //��3��û�п�ʼ�������㣬����ready_oΪDivResultNotReady
                `DivFree: begin
                    if(start_i == `DivStart && annul_i == 1'b0) begin
                        if(opdata2_i == `ZeroWord) begin
                            state <= `DivByZero;
                        end else begin
                            state <= `DivOn;
                            cnt <= 6'b000000;
                            if(signed_div_i == 1'b1 && opdata1_i[31] == 1'b1) begin
                                temp_op1 = ~opdata1_i + 1; //������ȡ����
                            end else begin
                                temp_op1 = opdata1_i;
                            end
                            if(signed_div_i == 1'b1 && opdata2_i[31] == 1'b1) begin
                                temp_op2 = ~opdata2_i + 1; //����ȡ����
                            end else begin
                                temp_op2 = opdata2_i;
                            end
                            dividend <= {`ZeroWord, `ZeroWord};
                            dividend[32:1] <= temp_op1;
                            divisor <= temp_op2;
                        end
                    end else begin
                        ready_o <= `DivResultNotReady;
                        result_o <= {`ZeroWord, `ZeroWord};
                    end
                end
                `DivByZero: begin                           //DivByZero״̬
                    dividend <= {`ZeroWord, `ZeroWord};
                    state <= `DivEnd;
                end
                //DivOn״̬
                //��1��annul_iΪ1��������ȡ���������㣬DIVģ��ص�DivFree״̬��
                //��2��annul_iΪ0��cnt��Ϊ32����ʾ���̷�û�н��������������div_temp
                //    Ϊ�����˴ε������Ϊ0����Ϊ�����˴ε������Ϊ1��dividend�����λ
                //    ����ÿ�ε����Ľ����ͬʱ����DivOn��״̬��cnt��1��
                //��3��annul_iΪ0��cntΪ32�����̷��������з��ų����ҳ���������һ��һ����
                //    �����̷����ȡ���루�̡����������̱�����dividend�ĵ�32λ����������
                //    �ڸ�32λ������DivEnd״̬��
                `DivOn: begin
                    if(annul_i == 1'b0) begin
                        if(cnt != 6'b100000) begin
                            if(div_temp[32] == 1'b1) begin
                                //Ϊ1��ʾ�������С��0����dividend����һλ��
                                //�����ͽ���������û�в�����������λ���뵽�´ε����ı������У�
                                //ͬʱ��0׷�ӵ��м���
                                dividend <= {dividend[63:0], 1'b0};
                            end else begin
                                //Ϊ0��ʾ����������ڵ���0��
                                //����������뱻������û�в�����������λ���뵽��һ�ε����ı������У�
                                //ͬʱ��1׷�ӵ��м���
                                dividend <= {div_temp[31:0], dividend[31:0], 1'b1};
                            end
                            cnt <= cnt + 1;
                        end else begin
                            //���̷�����
                            if((signed_div_i == 1'b1) &&
                               ((opdata1_i[31] ^ opdata2_i[31]) == 1'b1)) begin
                                dividend[31:0] <= (~dividend[31:0] + 1);
                               end 
                            if((signed_div_i == 1'b1) &&
                               ((opdata1_i[31] ^ dividend[64]) == 1'b1)) begin
                                dividend[64:33] <= (~dividend[64:33] + 1);
                               end
                            state <= `DivEnd;
                            cnt <= 6'b000000;
                        end
                    end else begin
                        state <= `DivFree;
                    end
                end
                //DivEnd״̬
                //�������������result_o�Ŀ����64λ�����32λ������������32λ�����̣�
                //��������ź�ready_oΪDivResultReady����ʾ����������Ȼ��ȴ�EXģ��
                //����DivStop�źţ�������DIVģ��ص�DivFree״̬
                `DivEnd: begin
                    result_o <= {dividend[64:33], dividend[31:0]};
                    ready_o <= `DivResultReady;
                    if(start_i == `DivStop) begin
                        state <= `DivFree;
                        ready_o <= `DivResultNotReady;
                        result_o <= {`ZeroWord, `ZeroWord};
                    end
                end
            endcase
        end
    end
    
endmodule