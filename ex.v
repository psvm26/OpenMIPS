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
    //处于执行阶段的指令对HI、LO的写操作请求
    output reg [`RegBus] hi_o,
    output reg [`RegBus] lo_o,
    output reg whilo_o,
    //执行的结果
    output reg [`RegAddrBus] wd_o,  //要写入的寄存器地址
    output reg wreg_o,              //是否要写入寄存器
    output reg [`RegBus] wdata_o    //写入寄存器的值
);

    reg [`RegBus] logicout;         //保存逻辑运算的结果
    reg [`RegBus] shiftres;         //保存移位运算的结果
    reg [`RegBus] moveres;
    reg [`RegBus] HI;               //保存HI寄存器的最新值
    reg [`RegBus] LO;               //保存LO寄存器的最新值

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
        wreg_o <= wreg_i;
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
        end else if(aluop_i == `EXE_MTHI_OP) begin
            whilo_o <= `WriteEnable;
            hi_o <= reg1_i;
            lo_o <= LO;         //写hi寄存器，lo保持不变     
        end else if (aluop_i == `EXE_MTLO_OP) begin
            whilo_o <= `WriteEnable;
            hi_o <= HI;         //写lo寄存器，hi保持不变
            lo_o <= reg1_i;     
        end else begin
            whilo_o <= `WriteDisable;
            hi_o <= `ZeroWord;
            lo_o <= `ZeroWord;
        end
    end
    
endmodule