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
`define EXE_AND         6'b100_100      //ָ��and�Ĺ�����
`define EXE_OR          6'b100_101      //ָ��or�Ĺ�����
`define EXE_XOR         6'b100_110      //ָ��xor�Ĺ�����
`define EXE_NOR         6'b100_111      //ָ��nor�Ĺ�����
`define EXE_ANDI        6'b001_100      //ָ��andi��ָ����
`define EXE_ORI         6'b001_101       //ָ��ori��ָ����
`define EXE_XORI        6'b001_110       //ָ��xori��ָ����
`define EXE_LUI         6'b001_111       //ָ��lui��ָ����

`define EXE_SLL         6'b000_000      //ָ��sll�Ĺ�����(�߼�����)
`define EXE_SLLV        6'b000_100      //ָ��sllv�Ĺ�����(�߼�����)
`define EXE_SRL         6'b000_010      //ָ��srl�Ĺ�����(�߼�����)
`define EXE_SRLV        6'b000_110      //ָ��srlv�Ĺ�����(�߼�����)
`define EXE_SRA         6'b000_011      //ָ��srv�Ĺ�����(��������)
`define EXE_SRAV        6'b000_111      //ָ��srav�Ĺ�����(��������)

`define EXE_SYNC        6'b001_111      //ָ��sync�Ĺ�����
`define EXE_NOP         6'b000_000      //ָ��nop�Ĺ�����
`define EXE_PREF        6'b110_011      //ָ��pref��ָ����
`define EXE_SPECIAL_INST 6'b000_000     //SPECIAL��ָ���ָ����


//AluOp
`define EXE_AND_OP      8'b00100100
`define EXE_OR_OP       8'b00100101
`define EXE_XOR_OP      8'b00100110
`define EXE_NOR_OP      8'b00100111
`define EXE_ANDI_OP     8'b01011001
`define EXE_ORI_OP      8'b01011010
`define EXE_XORI_OP     8'b01011011
`define EXE_LUI_OP      8'b01011100   

`define EXE_SLL_OP      8'b01111100
`define EXE_SLLV_OP     8'b00000100
`define EXE_SRL_OP      8'b00000010
`define EXE_SRLV_OP     8'b00000110
`define EXE_SRA_OP      8'b00000011
`define EXE_SRAV_OP     8'b00000111

`define EXE_NOP_OP    8'b00000000

//AluSel
`define EXE_RES_LOGIC   3'b001
`define EXE_RES_SHIFT 3'b010

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