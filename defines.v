//�����
//ȫ��
`define RstEnable       1'b1            //��λ�ź���Ч
`define RstDisable      1'b0            //��λ�ź���Ч
`define ZeroWord        32'h0000_0000   //32λ0
`define WriteEnable     1'b1            //ʹ��д
`define WriteDisable    1'b0            //��ֹд
`define ReadEnable      1'b1            //ʹ�ܶ�
`define ReadDisable     1'b0            //��ֹ��
`define AluOpBus        7:0             //���aluop_o�Ŀ��
`define AluSelBus       2:0             //���alusel_o�Ŀ��
`define InstValid       1'b0            //ָ����Ч
`define InstInvalid     1'b1            //ָ����Ч
`define True_v          1'b1            //�߼���
`define False_v         1'b0            //�߼���
`define ChipEnable      1'b1            //оƬʹ��
`define ChipDisable     1'b0            //оƬ��ֹ

//ָ�����
`define EXE_ORI         6'b001_101       //ָ��ori��ָ����
`define EXE_NOP         6'b000_000      

//AluOp
`define EXE_OR_OP       8'b0010_0101
`define EXE_NOP_OP      8'b0000_0000

//AluSel
`define EXE_RES_LOGIC   3'b001
`define EXE_RES_NOP     3'b000

//������ROM���
`define InstAddrBus     31:0            //ROM�ĵ�ַ���߿��
`define InstBus         31:0            //ROM���������߿��
`define InstMemNum      131071          //ROM�Ĵ�СΪ128KB
`define InstMemNumLog2  17              //ROMʵ��ʹ�õĵ�ַ�߿��

//ͨ�üĴ���Regfile���
`define RegAddrBus      4:0             //Regfileģ��ĵ�ַ�߿��
`define RegBus          31:0            //Regfileģ��������߿��
`define RegWidth        32              //ͨ�üĴ����Ŀ��
`define DoubleRegWidth  64              //����xx
`define DoubleRegBus    63:0            //����xx
`define RegNum          32              //ͨ�üĴ���������
`define RegNumLog2      5               //Ѱַͨ�üĴ���ʹ�õĵ�ַλ��
`define NOPRegAddr      5'b00000        