`include "defines.v"
module ex (
    input wire rst,
    //译码阶段送到执行阶段的信息
    input wire [`AluOpBus] aluop_i,
    input wire [`AluSelBus] alusel_i,
    input wire [`RegBus] reg1_i,
    input wire [`RegBus] reg2_i,
    input wire [`RegAddrBus] wd_i,
    input wire wreg_i,
    //HILO模块给出的HI、LO寄存器的值
    input wire [`RegBus] hi_i,
    input wire [`RegBus] lo_i,
    //回写阶段的指令是否要写HI、LO
    input wire [`RegBus] wb_hi_i,
    input wire [`RegBus] wb_lo_i,
    input wire wb_whilo_i,
    //访存阶段的指令是否要写HI、LO
    input wire [`RegBus] mem_hi_i,
    input wire [`RegBus] mem_lo_i,
    input wire mem_whilo_i,
    input wire [`DoubleRegBus] hilo_temp_i, //第一个执行周期得到的乘法结果
    input wire [1:0] cnt_i,                 //当前处于执行阶段的第几个时钟周期
    //来自除法模块的输入
    input wire [`DoubleRegBus] div_result_i,//除法运算结果
    input wire div_ready_i,                 //除法运算是否结束
    //处于执行阶段的指令对HI、LO的写操作请求
    output reg [`RegBus] hi_o,
    output reg [`RegBus] lo_o,
    output reg whilo_o,
    //执行的结果
    output reg [`RegAddrBus] wd_o,  //要写入的寄存器地址
    output reg wreg_o,              //是否要写入寄存器
    output reg [`RegBus] wdata_o,   //写入寄存器的值
    output reg stallreq,
    output reg [`DoubleRegBus] hilo_temp_o, //第一个执行周期得到的乘法结果
    output reg [1:0] cnt_o,                 //下一个时钟周期处于执行阶段的第几个时钟周期
    //到除法模块的输出
    output reg [`RegBus] div_opdata1_o,     //被除数
    output reg [`RegBus] div_opdata2_o,     //除数
    output reg div_start_o,                 //是否开始除法运算
    output reg signed_div_o                 //是否是有符号除法
);

    reg [`RegBus] logicout;         //保存逻辑运算的结果
    reg [`RegBus] shiftres;         //保存移位运算的结果
    reg [`RegBus] moveres;
    reg [`RegBus] HI;               //保存HI寄存器的最新值
    reg [`RegBus] LO;               //保存LO寄存器的最新值

    wire ov_sum;                    //保存溢出情况
    wire reg1_eq_reg2;              //判断第一个操作数是否等于第二个操作数
    wire reg1_lt_reg2;              //判断第一个操作数是否小于第二个操作数
    reg [`RegBus] arithmeticres;    //保存算术运算的结果
    wire [`RegBus] reg2_i_mux;      //保存输入的第二个操作数reg2_i的补码
    wire [`RegBus] reg1_i_not;      //保存输入的第一个操作数reg1_i取反后的值
    wire [`RegBus] result_sum;      //保存加法结果
    wire [`RegBus] opdata1_mult;    //乘法操作中的被乘数
    wire [`RegBus] opdata2_mult;    //乘法操作中的乘数
    wire [`DoubleRegBus] hilo_temp; //临时保存乘法的结果，宽度为64位
    reg [`DoubleRegBus] hilo_temp1;
    reg stallreq_for_madd_msub;
    reg [`DoubleRegBus] mulres;     //保存乘法结果，宽度为64位
    reg stallreq_for_div;           //是否由于除法运算导致流水线暂停

    //减法或有符号比较，reg2_i_mux等于第二个操作数reg2_i的补码，否则等于reg2_i
    assign reg2_i_mux = ((aluop_i == `EXE_SUB_OP) ||
                         (aluop_i == `EXE_SUBU_OP)||
                         (aluop_i == `EXE_SLT_OP)) ?
                         (~reg2_i)+1 : reg2_i;

    assign result_sum = reg1_i + reg2_i_mux;

    //计算是否溢出（加法add、addi，减法sub时），正正相加为负或负负相加为正时有溢出
    assign ov_sum = ((!reg1_i[31] && !reg2_i[31]) && result_sum[31]) || 
                    ((reg1_i[31] && reg2_i[31]) && !result_sum[31]);

    //计算操作数1是否小于操作数2
    //aluop_i为`EXE_SLT_OP，有符号运算；否则直接比较reg1_i和reg2_i
    assign reg1_lt_reg2 = (aluop_i == `EXE_SLT_OP) ?
                          ((reg1_i[31] && !reg2_i[31]) ||
                          (!reg1_i[31] && !reg2_i[31] && result_sum[31]) ||
                          (reg1_i[31] && reg2_i[31] && result_sum[31])) :
                          (reg1_i < reg2_i);

    //对操作数1逐位取反，赋给reg1_i_not
    assign reg1_i_not = ~reg1_i;

    //依据不同的算术类型，给aritmeticres赋值
    always @(*) begin
        if(rst == `RstEnable) begin
            arithmeticres <= `ZeroWord;
        end else begin
            case(aluop_i)
                `EXE_SLT_OP, `EXE_SLTU_OP: begin                            //比较运算
                    arithmeticres <= reg1_lt_reg2;
                end 
                `EXE_ADD_OP, `EXE_ADDU_OP, `EXE_ADDI_OP, `EXE_ADDIU_OP: begin  //加法运算
                    arithmeticres <= result_sum;
                end
                `EXE_SUB_OP, `EXE_SUBU_OP: begin                            //减法运算
                    arithmeticres <= result_sum;
                end
                `EXE_CLZ_OP: begin                                          //计数运算clz
                    arithmeticres <= reg1_i[31] ? 0 : reg1_i[30] ? 1 :
                                     reg1_i[29] ? 2 : reg1_i[28] ? 3 :
                                     reg1_i[27] ? 4 : reg1_i[26] ? 5 : 
                                     reg1_i[25] ? 6 : reg1_i[24] ? 7 :
                                     reg1_i[23] ? 8 : reg1_i[22] ? 9 :
                                     reg1_i[21] ? 10 : reg1_i[20] ? 11 :
                                     reg1_i[19] ? 12 : reg1_i[18] ? 13 :
                                     reg1_i[17] ? 14 : reg1_i[16] ? 15 :
                                     reg1_i[15] ? 16 : reg1_i[14] ? 17 :
                                     reg1_i[13] ? 18 : reg1_i[12] ? 19 :
                                     reg1_i[11] ? 20 : reg1_i[10] ? 21 :
                                     reg1_i[9] ? 22 : reg1_i[8] ? 23 :
                                     reg1_i[7] ? 24 : reg1_i[6] ? 25 :
                                     reg1_i[5] ? 26 : reg1_i[4] ? 27 :
                                     reg1_i[3] ? 28 : reg1_i[2] ? 29 :
                                     reg1_i[1] ? 30 : reg1_i[0] ? 31 : 32;

                end
                `EXE_CLO_OP: begin
                    arithmeticres <= (reg1_i_not[31] ? 0 :
                                      reg1_i_not[30] ? 1 :
                                      reg1_i_not[29] ? 2 :
                                      reg1_i_not[28] ? 3 :
                                      reg1_i_not[27] ? 4 :
                                      reg1_i_not[26] ? 5 :
                                      reg1_i_not[25] ? 6 :
                                      reg1_i_not[24] ? 7 :
                                      reg1_i_not[23] ? 8 :
                                      reg1_i_not[22] ? 9 :
                                      reg1_i_not[21] ? 10 :
                                      reg1_i_not[20] ? 11 :
                                      reg1_i_not[19] ? 12 :
                                      reg1_i_not[18] ? 13 :
                                      reg1_i_not[17] ? 14 :
                                      reg1_i_not[16] ? 15 :
                                      reg1_i_not[15] ? 16 :
                                      reg1_i_not[14] ? 17 :
                                      reg1_i_not[13] ? 18 :
                                      reg1_i_not[12] ? 19 :
                                      reg1_i_not[11] ? 20 :
                                      reg1_i_not[10] ? 21 :
                                      reg1_i_not[9] ? 22 :
                                      reg1_i_not[8] ? 23 :
                                      reg1_i_not[7] ? 24 :
                                      reg1_i_not[6] ? 25 :
                                      reg1_i_not[5] ? 26 :
                                      reg1_i_not[4] ? 27 :
                                      reg1_i_not[3] ? 28 :
                                      reg1_i_not[2] ? 29 :
                                      reg1_i_not[1] ? 30 :
                                      reg1_i_not[0] ? 31 : 32);
                end
                default: begin
                    arithmeticres <= `ZeroWord;
                end 
            endcase
        end
    end

    //进行乘法运算
    //取乘法的乘数(有符号乘法且被乘数是负数，取补码)
    assign opdata1_mult = (((aluop_i == `EXE_MUL_OP) || (aluop_i == `EXE_MULT_OP) ||
                            (aluop_i == `EXE_MADD_OP) || (aluop_i == `EXE_MSUB_OP))
                          && (reg1_i[31] == 1'b1)) ? (~reg1_i + 1) : reg1_i;
    
    //取乘法的被乘数
    assign opdata2_mult = (((aluop_i == `EXE_MUL_OP) || (aluop_i == `EXE_MULT_OP) ||
                            (aluop_i == `EXE_MADD_OP) || (aluop_i == `EXE_MSUB_OP))
                          && (reg2_i[31] == 1'b1)) ? (~reg2_i + 1) : reg2_i;

    //得到临时乘法结果
    assign hilo_temp = opdata1_mult * opdata2_mult;

    //对临时乘法的结果进行修正，最终结果保存在mulres中
    //乘数和被乘数一正一负，需要将临时结果求补码，其余情况临时结果就是最终结果
    always @(*) begin
        if(rst == `RstEnable) begin
            mulres <= {`ZeroWord, `ZeroWord};
        end else if((aluop_i == `EXE_MULT_OP) || (aluop_i == `EXE_MUL_OP) ||
                    (aluop_i == `EXE_MADD_OP) || (aluop_i == `EXE_MSUB_OP)) begin
            if(reg1_i[31] ^ reg2_i[31] == 1'b1) begin
                mulres <= ~hilo_temp + 1;
            end else begin
                mulres <= hilo_temp;
            end
        end else begin
            mulres <= hilo_temp;
        end
    end

    //乘累加、乘累减
    always @(*) begin
        if(rst == `RstEnable) begin
            hilo_temp_o <= {`ZeroWord, `ZeroWord};
            cnt_o <= 2'b00;
            stallreq_for_madd_msub <= `NoStop;
        end else begin
            case(aluop_i)
                `EXE_MADD_OP, `EXE_MADDU_OP: begin
                    if(cnt_i == 2'b00) begin
                        hilo_temp_o <= mulres; 
                        cnt_o <= 2'b01;
                        hilo_temp1 <= {`ZeroWord, `ZeroWord};
                        stallreq_for_madd_msub <= `Stop;
                    end else if(cnt_i == 2'b01) begin
                        hilo_temp_o <= {`ZeroWord, `ZeroWord};
                        cnt_o <= 2'b10;
                        hilo_temp1 <= hilo_temp_i + {HI, LO};
                        stallreq_for_madd_msub <= `NoStop;
                    end
                end
                `EXE_MSUB_OP, `EXE_MSUBU_OP: begin
                    if(cnt_i == 2'b00) begin
                        hilo_temp_o <= ~mulres + 1; 
                        cnt_o <= 2'b01;
                        hilo_temp1 <= {`ZeroWord, `ZeroWord};
                        stallreq_for_madd_msub <= `Stop;
                    end else if(cnt_i == 2'b01) begin
                        hilo_temp_o <= {`ZeroWord, `ZeroWord};
                        cnt_o <= 2'b10;
                        hilo_temp1 <= hilo_temp_i + {HI, LO};
                        stallreq_for_madd_msub <= `NoStop;
                    end
                end
                default: begin
                    hilo_temp_o <= {`ZeroWord, `ZeroWord};
                    cnt_o <= 2'b00;
                    stallreq_for_madd_msub <= `NoStop;
                end
            endcase
        end
    end

    //输出DIV模块的控制信息，获取DIV模块的结果
    always @(*) begin
        if(rst == `RstEnable) begin
            stallreq_for_div <= `NoStop;
            div_opdata1_o <= `ZeroWord;
            div_opdata2_o <= `ZeroWord;
            div_start_o <= `DivStop;
            signed_div_o <= 1'b0;
        end else begin
            stallreq_for_div <= `NoStop;
            div_opdata1_o <= `ZeroWord;
            div_opdata2_o <= `ZeroWord;
            div_start_o <= `DivStop;
            signed_div_o <= 1'b0;
            case(aluop_i)
                `EXE_DIV_OP: begin
                    if(div_ready_i == `DivResultNotReady) begin
                        div_opdata1_o <= reg1_i;
                        div_opdata2_o <= reg2_i;
                        div_start_o <= `DivStart;
                        signed_div_o <= 1'b1;
                        stallreq_for_div <= `Stop;
                    end else if(div_ready_i == `DivResultReady) begin
                        div_opdata1_o <= reg1_i;
                        div_opdata2_o <= reg2_i;
                        div_start_o <= `DivStop;
                        signed_div_o <= 1'b1;
                        stallreq_for_div <= `NoStop;
                    end else begin
                        div_opdata1_o <= `ZeroWord;
                        div_opdata2_o <= `ZeroWord;
                        div_start_o <= `DivStop;
                        signed_div_o <= 1'b0;
                        stallreq_for_div <= `NoStop;
                    end
                end
                `EXE_DIVU_OP: begin
                    if(div_ready_i == `DivResultNotReady) begin
                        div_opdata1_o <= reg1_i;
                        div_opdata2_o <= reg2_i;
                        div_start_o <= `DivStart;
                        signed_div_o <= 1'b0;
                        stallreq_for_div <= `Stop;
                    end else if(div_ready_i == `DivResultReady) begin
                        div_opdata1_o <= reg1_i;
                        div_opdata2_o <= reg2_i;
                        div_start_o <= `DivStop;
                        signed_div_o <= 1'b0;
                        stallreq_for_div <= `NoStop;
                    end else begin
                        div_opdata1_o <= `ZeroWord;
                        div_opdata2_o <= `ZeroWord;
                        div_start_o <= `DivStop;
                        signed_div_o <= 1'b0;
                        stallreq_for_div <= `NoStop;
                    end
                end
                default: begin
                end
            endcase
        end
    end

    //暂停流水线
    always @(*) begin
        stallreq <= stallreq_for_madd_msub || stallreq_for_div;
    end

    //得到最新HILO的值
    always @(*) begin
        if(rst == `RstEnable) begin
            {HI,LO} <= {`ZeroWord,`ZeroWord};
        end else if(mem_whilo_i == `WriteEnable) begin
            {HI,LO} <= {mem_hi_i,mem_lo_i};
        end else if(wb_whilo_i == `WriteEnable) begin
            {HI,LO} <= {wb_hi_i,wb_lo_i};
        end else begin
            {HI,LO} <= {hi_i,lo_i};
        end
    end

    //MFHI、MFLO、MOVN、MOVZ指令
    always @(*) begin
        if(rst == `RstEnable) begin
            moveres <= `ZeroWord;
        end else begin
            moveres <= `ZeroWord;
            case(aluop_i)
                `EXE_MFHI_OP: begin
                    moveres <= HI;
                end
                `EXE_MFLO_OP: begin
                    moveres <= LO;
                end
                `EXE_MOVN_OP: begin
                    moveres <= reg1_i;;
                end
                `EXE_MOVZ_OP: begin
                    moveres <= reg1_i;
                end
                default: begin
                end
            endcase
        end
    end


    //一：依据aluop_i指示的子类型进行运算
    //进行逻辑运算
    always @(*) begin
        if(rst == `RstEnable) begin
            logicout <= `ZeroWord;
        end else begin
            case (aluop_i)
                `EXE_OR_OP: begin                   //逻辑或
                    logicout <= reg1_i | reg2_i;
                end
                `EXE_AND_OP: begin                  //逻辑与
                    logicout <= reg1_i & reg2_i;
                end
                `EXE_NOR_OP: begin                  //逻辑或非
                    logicout <= ~(reg1_i | reg2_i); 
                end
                `EXE_XOR_OP: begin                  //逻辑异或
                    logicout <= reg1_i ^ reg2_i;
                end
                default: begin
                    logicout <= `ZeroWord;
                end
            endcase
        end
    end

    //进行逻辑运算
    always @(*) begin
        if(rst == `RstEnable) begin
        shiftres <= `ZeroWord;
        end else begin
            case(aluop_i)
                `EXE_SLL_OP: begin                      //逻辑左移
                    shiftres <= reg2_i << reg1_i[4:0];
                end
                `EXE_SRL_OP: begin                      //逻辑右移
                    shiftres <= reg2_i >> reg1_i[4:0];
                end 
                `EXE_SRA_OP: begin                      //算术右移
                    shiftres <= ({32{reg2_i[31]}} << (6'd32 - {1'b0, reg1_i[4:0]})) 
                                | reg2_i >> reg1_i[4:0];
                end
                default: begin
                    shiftres <= `ZeroWord;
                end
            endcase 
        end
    end

    //二：依据alusel_i指示的运算类型，选择一个运算结果作为最终结果
    always @(*) begin
        wd_o <= wd_i;
        if(((aluop_i == `EXE_ADD_OP) || (aluop_i == `EXE_ADDI_OP) ||
            (aluop_i == `EXE_SUB_OP)) && (ov_sum == 1'b1)) begin
                wreg_o <= `WriteDisable;
            end else begin
                wreg_o <= wreg_i;
            end
        case (alusel_i)
            `EXE_RES_LOGIC: begin
                wdata_o <= logicout;    //选择逻辑运算
            end
            `EXE_RES_SHIFT: begin
                wdata_o <= shiftres;    //选择移位运算
            end
            `EXE_RES_MOVE: begin        
                wdata_o <= moveres;
            end
            `EXE_RES_ARITHMETIC: begin  //除乘法外简单的算术操作指令
                wdata_o <= arithmeticres;
            end 
            `EXE_RES_MUL: begin         //乘法指令mul
                wdata_o <= mulres[31:0];
            end
            default: begin
                wdata_o <= `ZeroWord;
            end
        endcase
    end

    //是MTHI、MTLO指令，需要给出whilo_o、hi_o、lo_o的值
    always @(*) begin
        if(rst == `RstEnable) begin
            whilo_o <= `WriteDisable;
            hi_o <= `ZeroWord;
            lo_o <= `ZeroWord;
        end else if((aluop_i == `EXE_MSUB_OP) || (aluop_i == `EXE_MSUBU_OP)) begin
            whilo_o <= `WriteEnable;
            hi_o <= hilo_temp1[63:32];
            lo_o <= hilo_temp1[31:0];
        end else if((aluop_i == `EXE_MADD_OP) || (aluop_i == `EXE_MADDU_OP)) begin
            whilo_o <= `WriteEnable;
            hi_o <= hilo_temp1[63:32];
            lo_o <= hilo_temp1[31:0];
        end else if((aluop_i == `EXE_MULT_OP) || (aluop_i == `EXE_MULTU_OP)) begin
            whilo_o <= `WriteEnable;
            hi_o <= mulres[63:32];
            lo_o <= mulres[31:0];
        end else if(aluop_i == `EXE_MTHI_OP) begin
            whilo_o <= `WriteEnable;
            hi_o <= reg1_i;
            lo_o <= LO;         //写hi寄存器，lo保持不变     
        end else if (aluop_i == `EXE_MTLO_OP) begin
            whilo_o <= `WriteEnable;
            hi_o <= HI;         //写lo寄存器，hi保持不变
            lo_o <= reg1_i;     
        end else if((aluop_i == `EXE_DIV_OP) || (aluop_i == `EXE_DIVU_OP)) begin
            whilo_o <= `WriteEnable;
            hi_o <= div_result_i[63:32];
            lo_o <= div_result_i[31:0];
        end else begin
            whilo_o <= `WriteDisable;
            hi_o <= `ZeroWord;
            lo_o <= `ZeroWord;
        end
    end
    
endmodule