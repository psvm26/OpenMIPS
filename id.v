`include "defines.v"
module id (
    input wire rst,
    input wire [`InstAddrBus] pc_i,         //译码阶段指令对应的地址
    input wire [`InstBus] inst_i,           //译码阶段的指令
    //读取的Regfile的值
    input wire [`RegBus] reg1_data_i,       //读寄存器端口1的输入
    input wire [`RegBus] reg2_data_i,       //读寄存器端口2的输入
    //输出到Regfile的信息
    output reg reg1_read_o,                 //读寄存器端口1的使能
    output reg reg2_read_o,                 //读寄存器端口2的使能
    output reg [`RegAddrBus] reg1_addr_o,   //读寄存器端口1的地址
    output reg [`RegAddrBus] reg2_addr_o,   //读寄存器端口2的地址
    //送到执行阶段的信息
    output reg [`AluOpBus] aluop_o,         //执行阶段运算的子类型
    output reg [`AluSelBus] alusel_o,       //执行阶段运算的类型
    output reg [`RegBus] reg1_o,            //执行阶段运算的源操作数1
    output reg [`RegBus] reg2_o,            //执行阶段运算的源操作数2
    output reg [`RegAddrBus] wd_o,          //执行阶段要写入的目的寄存器地址
    output reg wreg_o                       //执行阶段指令是否要写入寄存器
);
    
    //取得指令的指令码、功能码
    //对于ori指令判断26-31位的值即可判断是否为ori指令
    wire [5:0] op = inst_i[31:26];
    wire [4:0] op2 = inst_i[10:6];
    wire [5:0] op3 = inst_i[5:0];
    wire [4:0] op4 = inst_i[20:16];

    //保存指令执行所需要的立即数
    reg[`RegBus] imm;

    //指示指令是否有效
    reg instvalid;

    //一：对指令进行译码
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
            //初始化？
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
                `EXE_ORI:   begin                   //ori指令
                    wreg_o <= `WriteEnable;         //需要将结果写入目的寄存器
                    aluop_o <= `EXE_OR_OP;          //子类型为‘或’运算
                    alusel_o <= `EXE_RES_LOGIC;     //运算类型为逻辑运算
                    reg1_read_o <= 1'b1;            //需要regfile的读端口1
                    reg2_read_o <= 1'b0;            //不需要读端口2
                    imm <= {16'h0, inst_i[15:0]};   //需使用立即数
                    wd_o <= inst_i[20:16];          //指令执行要写的目的寄存器地址
                    instvalid <= `InstValid;        //指令有效
                end
                default:begin
                end
            endcase
        end
    end

    //二；确定进行运算的源操作数1
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

    //三：确定进行运算的源操作数1
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