`include "defines.v"
module id (
    input wire rst,
    input wire [`InstAddrBus] pc_i,         
    input wire [`InstBus] inst_i,    

    input wire[`AluOpBus] ex_aluop_i,      //处于执行阶段指令的运算子类型

    input wire [`RegBus] reg1_data_i,       
    input wire [`RegBus] reg2_data_i,       

    input wire ex_wreg_i,                   
    input wire [`RegBus] ex_wdata_i,
    input wire [`RegAddrBus] ex_wd_i,

    input wire mem_wreg_i,                   
    input wire [`RegBus] mem_wdata_i,
    input wire [`RegAddrBus] mem_wd_i, 

    //是否需要延迟槽
    input wire is_in_delayslot_i,

    output reg reg1_read_o,               
    output reg reg2_read_o,                
    output reg [`RegAddrBus] reg1_addr_o,  
    output reg [`RegAddrBus] reg2_addr_o,   
    output reg [`AluOpBus] aluop_o,         
    output reg [`AluSelBus] alusel_o,       
    output reg [`RegBus] reg1_o,            
    output reg [`RegBus] reg2_o,           
    output reg [`RegAddrBus] wd_o,          
    output reg wreg_o,
    output wire stallreq,
    output reg next_inst_in_delayslot_o,            //下一条进入译码阶段的指令是否位于延迟槽

    output reg branch_flag_o,                       //是否发生转移
    output reg [`RegBus] branch_target_address_o,   //转移的目标地址
    output reg [`RegBus] link_addr_o,               //转移指令要保存的返回地址
    output reg is_in_delayslot_o,                   //当前处于译码阶段的指令是否位于延迟槽
    output wire [`RegBus] inst_o                    //当前处于译码阶段的指令
);
    
   
    wire [5:0] op = inst_i[31:26];          //指令码
    wire [4:0] op2 = inst_i[10:6];
    wire [5:0] op3 = inst_i[5:0];           //功能码
    wire [4:0] op4 = inst_i[20:16];


    reg[`RegBus] imm;
    reg instvalid;

    wire [`RegBus] pc_plus_8;
    wire [`RegBus] pc_plus_4;

    wire [`RegBus] imm_sll2_signedext;

    reg stallreq_for_reg1_loadrelate;
    reg stallreq_for_reg2_loadrelate;
    wire pre_inst_is_load;

    assign pc_plus_8 = pc_i + 8;            //保存当前译码阶段指令后面第二条指令的地址
    assign pc_plus_4 = pc_i + 4;            //保存当前译码阶段指令后面紧接着的指令地址

    //imm_sll2_signedext对应分支指令中的offset左移两位，再符号扩展至32位的值
    assign imm_sll2_signedext = {{14{inst_i[15]}}, inst_i[15:0], 2'b00};
    assign stallreq = stallreq_for_reg1_loadrelate | stallreq_for_reg2_loadrelate;

    assign inst_o = inst_i;

    assign pre_inst_is_load = ((ex_aluop_i == `EXE_LB_OP) || 
  													(ex_aluop_i == `EXE_LBU_OP)||
  													(ex_aluop_i == `EXE_LH_OP) ||
  													(ex_aluop_i == `EXE_LHU_OP)||
  													(ex_aluop_i == `EXE_LW_OP) ||
  													(ex_aluop_i == `EXE_LWR_OP)||
  													(ex_aluop_i == `EXE_LWL_OP)||
  													(ex_aluop_i == `EXE_LL_OP) ||
  													(ex_aluop_i == `EXE_SC_OP)) ? 1'b1 : 1'b0;


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
            link_addr_o <= `ZeroWord;
            branch_target_address_o <= `ZeroWord;
            branch_flag_o <= `NotBranch;
            next_inst_in_delayslot_o <= `NotInDelaySlot;
        end else begin
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
            link_addr_o <= `ZeroWord;
            branch_target_address_o <= `ZeroWord;
            branch_flag_o <= `NotBranch;
            next_inst_in_delayslot_o <= `NotInDelaySlot;

            case(op)
                `EXE_SPECIAL_INST:  begin                       //指令码是SPECIAL
                    case(op2)
                        5'b00000:   begin
                            case(op3)                           //依据功能码判断指令
                                `EXE_OR:    begin               //or
                                    wreg_o <= `WriteEnable;         
                                    aluop_o <= `EXE_OR_OP;          
                                    alusel_o <= `EXE_RES_LOGIC;     
                                    reg1_read_o <= `ReadEnable;     
                                    reg2_read_o <= `ReadEnable;           
                                    instvalid <= `InstValid;      
                                end
                                `EXE_AND:   begin               //and
                                    wreg_o <= `WriteEnable;         
                                    aluop_o <= `EXE_AND_OP;          
                                    alusel_o <= `EXE_RES_LOGIC;     
                                    reg1_read_o <= `ReadEnable;     
                                    reg2_read_o <= `ReadEnable;           
                                    instvalid <= `InstValid;      
                                end
                                `EXE_XOR:   begin               //xor
                                    wreg_o <= `WriteEnable;         
                                    aluop_o <= `EXE_XOR_OP;          
                                    alusel_o <= `EXE_RES_LOGIC;     
                                    reg1_read_o <= `ReadEnable;     
                                    reg2_read_o <= `ReadEnable;           
                                    instvalid <= `InstValid;      
                                end
                                `EXE_NOR:   begin               //nor
                                    wreg_o <= `WriteEnable;         
                                    aluop_o <= `EXE_NOR_OP;          
                                    alusel_o <= `EXE_RES_LOGIC;     
                                    reg1_read_o <= `ReadEnable;     
                                    reg2_read_o <= `ReadEnable;           
                                    instvalid <= `InstValid;      
                                end
                                `EXE_SLLV:  begin               //sllv
                                    wreg_o <= `WriteEnable;         
                                    aluop_o <= `EXE_SLL_OP;          
                                    alusel_o <= `EXE_RES_SHIFT;     
                                    reg1_read_o <= `ReadEnable;     
                                    reg2_read_o <= `ReadEnable;           
                                    instvalid <= `InstValid;      
                                end
                                `EXE_SRLV:  begin               //srlv
                                    wreg_o <= `WriteEnable;         
                                    aluop_o <= `EXE_SRL_OP;          
                                    alusel_o <= `EXE_RES_SHIFT;     
                                    reg1_read_o <= `ReadEnable;     
                                    reg2_read_o <= `ReadEnable;           
                                    instvalid <= `InstValid;      
                                end
                                `EXE_SRAV:    begin             //srav
                                    wreg_o <= `WriteEnable;         
                                    aluop_o <= `EXE_SRA_OP;          
                                    alusel_o <= `EXE_RES_SHIFT;     
                                    reg1_read_o <= `ReadEnable;     
                                    reg2_read_o <= `ReadEnable;           
                                    instvalid <= `InstValid;      
                                end
                                `EXE_SYNC:  begin               //sync
                                    wreg_o <= `WriteDisable;         
                                    aluop_o <= `EXE_NOP_OP;          
                                    alusel_o <= `EXE_RES_NOP;     
                                    reg1_read_o <= `ReadDisable;     
                                    reg2_read_o <= `ReadEnable;           
                                    instvalid <= `InstValid;      
                                end
                                `EXE_MFHI:  begin               //mfhi
                                    wreg_o <= `WriteEnable;
                                    aluop_o <= `EXE_MFHI_OP;
                                    alusel_o <= `EXE_RES_MOVE;
                                    reg1_read_o <= `ReadDisable;
                                    reg2_read_o <= `ReadDisable;
                                    instvalid <= `InstValid;
                                end
                                `EXE_MFLO:  begin               //mflo
                                    wreg_o <= `WriteEnable;
                                    aluop_o <= `EXE_MFLO_OP;
                                    alusel_o <= `EXE_RES_MOVE;
                                    reg1_read_o <= `ReadDisable;
                                    reg2_read_o <= `ReadDisable;
                                    instvalid <= `InstValid;
                                end
                                `EXE_MTHI:  begin               //mthi
                                    wreg_o <= `WriteDisable;
                                    aluop_o <= `EXE_MTHI_OP;
                                    reg1_read_o <= `ReadEnable;
                                    reg2_read_o <= `ReadDisable;
                                    instvalid <= `InstValid;
                                end
                                `EXE_MTLO:  begin               //mtlo
                                    wreg_o <= `WriteDisable;
                                    aluop_o <= `EXE_MTLO_OP;
                                    reg1_read_o <= `ReadEnable;
                                    reg2_read_o <= `ReadDisable;
                                    instvalid <= `InstValid;
                                end
                                `EXE_MOVN:  begin               //movn
                                    aluop_o <= `EXE_MOVN_OP;
                                    alusel_o <= `EXE_RES_MOVE;
                                    reg1_read_o <= `ReadEnable;
                                    reg2_read_o <= `ReadEnable;
                                    instvalid <= `InstValid;
                                    if(reg2_o != `ZeroWord) begin
                                        wreg_o <= `WriteEnable;
                                    end else begin
                                        wreg_o <= `WriteDisable;
                                    end
                                end
                                 `EXE_MOVZ:  begin              //movz
                                    aluop_o <= `EXE_MOVZ_OP;
                                    alusel_o <= `EXE_RES_MOVE;
                                    reg1_read_o <= `ReadEnable;
                                    reg2_read_o <= `ReadEnable;
                                    instvalid <= `InstValid;
                                    if(reg2_o == `ZeroWord) begin
                                        wreg_o <= `WriteEnable;
                                    end else begin
                                        wreg_o <= `WriteDisable;
                                    end
                                end
                                `EXE_SLT:  begin                //slt
                                    wreg_o <= `WriteEnable;
                                    aluop_o <= `EXE_SLT_OP;
                                    alusel_o <= `EXE_RES_ARITHMETIC; 
                                    reg1_read_o <= `ReadEnable;
                                    reg2_read_o <= `ReadEnable;
                                    instvalid <= `InstValid;
                                end
                                `EXE_SLTU:  begin                //sltu
                                    wreg_o <= `WriteEnable;
                                    aluop_o <= `EXE_SLTU_OP;
                                    alusel_o <= `EXE_RES_ARITHMETIC; 
                                    reg1_read_o <= `ReadEnable;
                                    reg2_read_o <= `ReadEnable;
                                    instvalid <= `InstValid;
                                end
                                `EXE_ADD:  begin                //add
                                    wreg_o <= `WriteEnable;
                                    aluop_o <= `EXE_ADD_OP;
                                    alusel_o <= `EXE_RES_ARITHMETIC; 
                                    reg1_read_o <= `ReadEnable;
                                    reg2_read_o <= `ReadEnable;
                                    instvalid <= `InstValid;
                                end
                                `EXE_ADDU:  begin                //addu
                                    wreg_o <= `WriteEnable;
                                    aluop_o <= `EXE_ADDU_OP;
                                    alusel_o <= `EXE_RES_ARITHMETIC; 
                                    reg1_read_o <= `ReadEnable;
                                    reg2_read_o <= `ReadEnable;
                                    instvalid <= `InstValid;
                                end
                                `EXE_SUB:  begin                //sub
                                    wreg_o <= `WriteEnable;
                                    aluop_o <= `EXE_SUB_OP;
                                    alusel_o <= `EXE_RES_ARITHMETIC; 
                                    reg1_read_o <= `ReadEnable;
                                    reg2_read_o <= `ReadEnable;
                                    instvalid <= `InstValid;
                                end
                                `EXE_SUBU:  begin                //subu
                                    wreg_o <= `WriteEnable;
                                    aluop_o <= `EXE_SUBU_OP;
                                    alusel_o <= `EXE_RES_ARITHMETIC; 
                                    reg1_read_o <= `ReadEnable;
                                    reg2_read_o <= `ReadEnable;
                                    instvalid <= `InstValid;
                                end
                                `EXE_MULT:  begin                //mult
                                    wreg_o <= `WriteDisable;
                                    aluop_o <= `EXE_MULT_OP;
                                    reg1_read_o <= `ReadEnable;
                                    reg2_read_o <= `ReadEnable;
                                    instvalid <= `InstValid;
                                end
                                `EXE_MULTU:  begin                //multu
                                    wreg_o <= `WriteDisable;
                                    aluop_o <= `EXE_MULTU_OP;
                                    reg1_read_o <= `ReadEnable;
                                    reg2_read_o <= `ReadEnable;
                                    instvalid <= `InstValid;
                                end
                                `EXE_DIV:   begin                   //div  
                                    wreg_o <= `WriteDisable;                                        wreg_o <= `WriteDisable;
                                    aluop_o <= `EXE_DIV_OP;
                                    reg1_read_o <= `ReadEnable;
                                    reg2_read_o <= `ReadEnable;
                                    instvalid <= `InstValid;
                                end
                                `EXE_DIVU:   begin                  //divu
                                    wreg_o <= `WriteDisable;
                                    aluop_o <= `EXE_DIVU_OP;
                                    reg1_read_o <= `ReadEnable;
                                    reg2_read_o <= `ReadEnable;
                                    instvalid <= `InstValid;
                                end
                                `EXE_JR:    begin                   //jr
                                    wreg_o <= `WriteDisable;
                                    aluop_o <= `EXE_JR_OP;
                                    alusel_o <= `EXE_RES_JUMP_BRANCH;
                                    reg1_read_o <= `ReadEnable;
                                    reg2_read_o <= `ReadDisable;
                                    link_addr_o <= `ZeroWord;
                                    branch_target_address_o <= reg1_o;
                                    branch_flag_o <= `Branch;
                                    next_inst_in_delayslot_o <= `InDelaySlot;
                                    instvalid <= `InstValid;
                                end
                                `EXE_JALR:  begin                   //jalr
                                    wreg_o <= `WriteEnable;
                                    aluop_o <= `EXE_JALR_OP;
                                    alusel_o <= `EXE_RES_JUMP_BRANCH;
                                    reg1_read_o <= `ReadEnable;
                                    reg2_read_o <= `ReadDisable;
                                    wd_o <= inst_i[15:11];
                                    link_addr_o <= pc_plus_8;
                                    branch_target_address_o <= reg1_o;
                                    branch_flag_o <= `Branch;
                                    next_inst_in_delayslot_o <= `InDelaySlot;
                                    instvalid <= `InstValid;
                                end
                                default: begin
                                end
                            endcase
                        end
                        default: begin
                        end
                    endcase
                end
                `EXE_ORI:   begin                               //ori
                    wreg_o <= `WriteEnable;        
                    aluop_o <= `EXE_OR_OP;          
                    alusel_o <= `EXE_RES_LOGIC;     
                    reg1_read_o <= `ReadEnable;    
                    reg2_read_o <= `ReadDisable;    
                    imm <= {16'h0, inst_i[15:0]};   
                    wd_o <= inst_i[20:16];         
                    instvalid <= `InstValid;       
                end
                `EXE_ANDI:  begin                               //andi
                    wreg_o <= `WriteEnable;        
                    aluop_o <= `EXE_AND_OP;          
                    alusel_o <= `EXE_RES_LOGIC;     
                    reg1_read_o <= `ReadEnable;    
                    reg2_read_o <= `ReadDisable;    
                    imm <= {16'h0, inst_i[15:0]};   
                    wd_o <= inst_i[20:16];         
                    instvalid <= `InstValid;       
                end
                `EXE_XORI:  begin                               //xori
                    wreg_o <= `WriteEnable;        
                    aluop_o <= `EXE_XOR_OP;          
                    alusel_o <= `EXE_RES_LOGIC;     
                    reg1_read_o <= `ReadEnable;    
                    reg2_read_o <= `ReadDisable;    
                    imm <= {16'h0, inst_i[15:0]};   
                    wd_o <= inst_i[20:16];         
                    instvalid <= `InstValid;       
                end 
                `EXE_LUI:   begin                               //lui
                    wreg_o <= `WriteEnable;        
                    aluop_o <= `EXE_OR_OP;          
                    alusel_o <= `EXE_RES_LOGIC;     
                    reg1_read_o <= `ReadEnable;    
                    reg2_read_o <= `ReadDisable;    
                    imm <= {inst_i[15:0], 16'h0};   
                    wd_o <= inst_i[20:16];         
                    instvalid <= `InstValid;       
                end
                `EXE_PREF:  begin                               //pref
                    wreg_o <= `WriteDisable;        
                    aluop_o <= `EXE_NOP_OP;          
                    alusel_o <= `EXE_RES_NOP;     
                    reg1_read_o <= `ReadDisable;    
                    reg2_read_o <= `ReadDisable;             
                    instvalid <= `InstValid;       
                end
                `EXE_SLTI:   begin                               //slti
                    wreg_o <= `WriteEnable;        
                    aluop_o <= `EXE_SLT_OP;          
                    alusel_o <= `EXE_RES_ARITHMETIC;     
                    reg1_read_o <= `ReadEnable;    
                    reg2_read_o <= `ReadDisable;    
                    imm <= {{16{inst_i[15]}}, inst_i[15:0]};   
                    wd_o <= inst_i[20:16];         
                    instvalid <= `InstValid;
                end
                `EXE_SLTIU:   begin                               //sltiu
                    wreg_o <= `WriteEnable;        
                    aluop_o <= `EXE_SLTU_OP;          
                    alusel_o <= `EXE_RES_ARITHMETIC;     
                    reg1_read_o <= `ReadEnable;    
                    reg2_read_o <= `ReadDisable;    
                    imm <= {{16{inst_i[15]}}, inst_i[15:0]};   
                    wd_o <= inst_i[20:16];         
                    instvalid <= `InstValid;
                end
                `EXE_ADDI:   begin                               //addi
                    wreg_o <= `WriteEnable;        
                    aluop_o <= `EXE_ADDI_OP;          
                    alusel_o <= `EXE_RES_ARITHMETIC;     
                    reg1_read_o <= `ReadEnable;    
                    reg2_read_o <= `ReadDisable;    
                    imm <= {{16{inst_i[15]}}, inst_i[15:0]};   
                    wd_o <= inst_i[20:16];         
                    instvalid <= `InstValid;
                end
                `EXE_ADDIU:   begin                               //addiu
                    wreg_o <= `WriteEnable;        
                    aluop_o <= `EXE_ADDIU_OP;          
                    alusel_o <= `EXE_RES_ARITHMETIC;     
                    reg1_read_o <= `ReadEnable;    
                    reg2_read_o <= `ReadDisable;    
                    imm <= {{16{inst_i[15]}}, inst_i[15:0]};   
                    wd_o <= inst_i[20:16];         
                    instvalid <= `InstValid;
                end
                `EXE_SPECIAL2_INST: begin
                    case(op3)
                        `EXE_CLZ:  begin                        //clz
                                    wreg_o <= `WriteEnable;
                                    aluop_o <= `EXE_CLZ_OP;
                                    alusel_o <= `EXE_RES_ARITHMETIC; 
                                    reg1_read_o <= `ReadEnable;
                                    reg2_read_o <= `ReadDisable;
                                    instvalid <= `InstValid;
                                end 
                        `EXE_CLO:  begin                        //clo
                                    wreg_o <= `WriteEnable;
                                    aluop_o <= `EXE_CLO_OP;
                                    alusel_o <= `EXE_RES_ARITHMETIC; 
                                    reg1_read_o <= `ReadEnable;
                                    reg2_read_o <= `ReadDisable;
                                    instvalid <= `InstValid;
                                end
                        `EXE_MUL:  begin                        //mul
                                    wreg_o <= `WriteEnable;
                                    aluop_o <= `EXE_MUL_OP;
                                    alusel_o <= `EXE_RES_MUL; 
                                    reg1_read_o <= `ReadEnable;
                                    reg2_read_o <= `ReadEnable;
                                    instvalid <= `InstValid;
                                end
                        `EXE_MADD:  begin                   //madd
                            wreg_o <= `WriteDisable;
                            aluop_o <= `EXE_MADD_OP;
                            alusel_o <= `EXE_RES_MUL;
                            reg1_read_o <= `ReadEnable;
                            reg2_read_o <= `ReadEnable;
                            instvalid <= `InstValid;
                        end  
                        `EXE_MADDU: begin                   //maddu
                            wreg_o <= `WriteDisable;
                            aluop_o <= `EXE_MADDU_OP;
                            alusel_o <= `EXE_RES_MUL;
                            reg1_read_o <= `ReadEnable;
                            reg2_read_o <= `ReadEnable;
                            instvalid <= `InstValid;
                        end
                        `EXE_MSUB:  begin                   //msub
                            wreg_o <= `WriteDisable;
                            aluop_o <= `EXE_MSUB_OP;
                            alusel_o <= `EXE_RES_MUL;
                            reg1_read_o <= `ReadEnable;
                            reg2_read_o <= `ReadEnable;
                            instvalid <= `InstValid;
                        end
                        `EXE_MSUBU: begin                   //msubu
                            wreg_o <= `WriteDisable;
                            aluop_o <= `EXE_MSUBU_OP;
                            alusel_o <= `EXE_RES_MUL;
                            reg1_read_o <= `ReadEnable;
                            reg2_read_o <= `ReadEnable;
                            instvalid <= `InstValid;
                        end
                    endcase
                end
                `EXE_J: begin                               //j
                    wreg_o <= `WriteDisable;
                    aluop_o <= `EXE_J_OP;
                    alusel_o <= `EXE_RES_JUMP_BRANCH;
                    reg1_read_o <= `ReadDisable;
                    reg2_read_o <= `ReadDisable;
                    link_addr_o <= `ZeroWord;
                    branch_flag_o <= `Branch;
                    next_inst_in_delayslot_o <= `InDelaySlot;
                    instvalid <= `InstValid;
                    branch_target_address_o <= 
                                        {pc_plus_4[31:28], inst_i[25:0], 2'b00};
                end
                `EXE_JAL: begin                             //jal
                    wreg_o <= `WriteEnable;
                    aluop_o <= `EXE_JAL_OP;
                    alusel_o <= `EXE_RES_JUMP_BRANCH;
                    reg1_read_o <= `ReadDisable;
                    reg2_read_o <= `ReadDisable;
                    wd_o <= 5'b11111;
                    link_addr_o <= pc_plus_8;
                    branch_flag_o <= `Branch;
                    next_inst_in_delayslot_o <= `InDelaySlot;
                    instvalid <= `InstValid;
                    branch_target_address_o <= 
                                        {pc_plus_4[31:28], inst_i[25:0], 2'b00};
                end
                `EXE_BEQ: begin                             //beq
                    wreg_o <= `WriteDisable;
                    aluop_o <= `EXE_BEQ_OP;
                    alusel_o <= `EXE_RES_JUMP_BRANCH;
                    reg1_read_o <= `ReadEnable;
                    reg2_read_o <= `ReadEnable;
                    instvalid <= `InstValid;
                    if(reg1_o == reg2_o) begin
                        branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
                        branch_flag_o <= `Branch;
                        next_inst_in_delayslot_o <= `InDelaySlot;
                    end
                end
                `EXE_BGTZ: begin                            //bgtz
                    wreg_o <= `WriteDisable;
                    aluop_o <= `EXE_BGTZ_OP;
                    alusel_o <= `EXE_RES_JUMP_BRANCH;
                    reg1_read_o <= `ReadEnable;
                    reg2_read_o <= `ReadDisable;
                    instvalid <= `InstValid;
                    if((reg1_o[31] == 1'b0) && (reg1_o != `ZeroWord)) begin
                        branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
                        branch_flag_o <= `Branch;
                        next_inst_in_delayslot_o <= `InDelaySlot;
                    end
                end
                `EXE_BLEZ: begin                            //blez
                    wreg_o <= `WriteDisable;
                    aluop_o <= `EXE_BLEZ_OP;
                    alusel_o <= `EXE_RES_JUMP_BRANCH;
                    reg1_read_o <= `ReadEnable;
                    reg2_read_o <= `ReadDisable;
                    instvalid <= `InstValid;
                    if((reg1_o[31] == 1'b1) && (reg1_o == `ZeroWord)) begin
                        branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
                        branch_flag_o <= `Branch;
                        next_inst_in_delayslot_o <= `InDelaySlot;
                    end
                end
                `EXE_BNE: begin                             //bne
                    wreg_o <= `WriteDisable;
                    aluop_o <= `EXE_BNE_OP;
                    alusel_o <= `EXE_RES_JUMP_BRANCH;
                    reg1_read_o <= `ReadEnable;
                    reg2_read_o <= `ReadEnable;
                    instvalid <= `InstValid;
                    if(reg1_o != reg2_o) begin
                        branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
                        branch_flag_o <= `Branch;
                        next_inst_in_delayslot_o <= `InDelaySlot;
                    end
                end
                `EXE_REGIMM_INST:    begin
                    case(op4)
                        `EXE_BGEZ: begin                            //bgez
                        wreg_o <= `WriteDisable;
                        aluop_o <= `EXE_BGEZ_OP;
                        alusel_o <= `EXE_RES_JUMP_BRANCH;
                        reg1_read_o <= `ReadEnable;
                        reg2_read_o <= `ReadDisable;
                        instvalid <= `InstValid;
                        if(reg1_o[31] == 1'b0) begin
                            branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
                            branch_flag_o <= `Branch;
                            next_inst_in_delayslot_o <= `InDelaySlot;
                        end
                    end
                        `EXE_BGEZAL: begin                          //bgezal
                        wreg_o <= `WriteEnable;
                        aluop_o <= `EXE_BGEZAL_OP;
                        alusel_o <= `EXE_RES_JUMP_BRANCH;
                        reg1_read_o <= `ReadEnable;
                        reg2_read_o <= `ReadDisable;
                        link_addr_o <= pc_plus_8;
                        wd_o <= 5'b11111;
                        instvalid <= `InstValid;
                        if(reg1_o[31] == 1'b0) begin
                            branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
                            branch_flag_o <= `Branch;
                            next_inst_in_delayslot_o <= `InDelaySlot;
                        end
                    end
                        `EXE_BLTZ: begin                            //bltz
                        wreg_o <= `WriteDisable;
                        aluop_o <= `EXE_BLTZ_OP;
                        alusel_o <= `EXE_RES_JUMP_BRANCH;
                        reg1_read_o <= `ReadEnable;
                        reg2_read_o <= `ReadDisable;
                        instvalid <= `InstValid;
                        if(reg1_o[31] == 1'b1) begin
                            branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
                            branch_flag_o <= `Branch;
                            next_inst_in_delayslot_o <= `InDelaySlot;
                        end
                    end
                        `EXE_BLTZAL: begin                          //bltzal
                        wreg_o <= `WriteEnable;
                        aluop_o <= `EXE_BLTZAL_OP;
                        alusel_o <= `EXE_RES_JUMP_BRANCH;
                        reg1_read_o <= `ReadEnable;
                        reg2_read_o <= `ReadDisable;
                        link_addr_o <= pc_plus_8;
                        wd_o <= 5'b11111;
                        instvalid <= `InstValid;
                        if(reg1_o[31] == 1'b1) begin
                            branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
                            branch_flag_o <= `Branch;
                            next_inst_in_delayslot_o <= `InDelaySlot;
                        end
                    end
                    endcase
                end
                `EXE_LB:    begin                   //lb
                    wreg_o <= `WriteEnable;         
                    aluop_o <= `EXE_LB_OP;          
                    alusel_o <= `EXE_RES_LOAD_STORE;     
                    reg1_read_o <= `ReadEnable;     
                    reg2_read_o <= `ReadDisable;
                    wd_o <= inst_i[20:16];           
                    instvalid <= `InstValid;
                end
                `EXE_LBU:    begin                   //lbu
                    wreg_o <= `WriteEnable;         
                    aluop_o <= `EXE_LBU_OP;          
                    alusel_o <= `EXE_RES_LOAD_STORE;     
                    reg1_read_o <= `ReadEnable;     
                    reg2_read_o <= `ReadDisable;
                    wd_o <= inst_i[20:16];           
                    instvalid <= `InstValid;
                end
                `EXE_LH:    begin                   //lh
                    wreg_o <= `WriteEnable;         
                    aluop_o <= `EXE_LH_OP;          
                    alusel_o <= `EXE_RES_LOAD_STORE;     
                    reg1_read_o <= `ReadEnable;     
                    reg2_read_o <= `ReadDisable;
                    wd_o <= inst_i[20:16];           
                    instvalid <= `InstValid;
                end
                `EXE_LHU:    begin                   //lhu
                    wreg_o <= `WriteEnable;         
                    aluop_o <= `EXE_LHU_OP;          
                    alusel_o <= `EXE_RES_LOAD_STORE;     
                    reg1_read_o <= `ReadEnable;     
                    reg2_read_o <= `ReadDisable;
                    wd_o <= inst_i[20:16];           
                    instvalid <= `InstValid;
                end
                `EXE_LW:    begin                   //lw
                    wreg_o <= `WriteEnable;         
                    aluop_o <= `EXE_LW_OP;          
                    alusel_o <= `EXE_RES_LOAD_STORE;     
                    reg1_read_o <= `ReadEnable;     
                    reg2_read_o <= `ReadDisable;
                    wd_o <= inst_i[20:16];           
                    instvalid <= `InstValid;
                end
                `EXE_LWL:    begin                   //lwl
                    wreg_o <= `WriteEnable;         
                    aluop_o <= `EXE_LWL_OP;          
                    alusel_o <= `EXE_RES_LOAD_STORE;     
                    reg1_read_o <= `ReadEnable;     
                    reg2_read_o <= `ReadEnable;
                    wd_o <= inst_i[20:16];           
                    instvalid <= `InstValid;
                end
                `EXE_LWR:    begin                   //lwr
                    wreg_o <= `WriteEnable;         
                    aluop_o <= `EXE_LWR_OP;          
                    alusel_o <= `EXE_RES_LOAD_STORE;     
                    reg1_read_o <= `ReadEnable;     
                    reg2_read_o <= `ReadEnable;
                    wd_o <= inst_i[20:16];           
                    instvalid <= `InstValid;
                end
                `EXE_LL:     begin                   //ll
                    wreg_o <= `WriteEnable;         
                    aluop_o <= `EXE_LL_OP;          
                    alusel_o <= `EXE_RES_LOAD_STORE;     
                    reg1_read_o <= `ReadEnable;     
                    reg2_read_o <= `ReadDisable;
                    wd_o <= inst_i[20:16];           
                    instvalid <= `InstValid;
                end
                `EXE_SB:    begin                   //sb
                    wreg_o <= `WriteDisable;         
                    aluop_o <= `EXE_SB_OP;          
                    alusel_o <= `EXE_RES_LOAD_STORE;     
                    reg1_read_o <= `ReadEnable;     
                    reg2_read_o <= `ReadEnable;           
                    instvalid <= `InstValid;
                end
                `EXE_SH:    begin                   //sh
                    wreg_o <= `WriteDisable;         
                    aluop_o <= `EXE_SH_OP;          
                    alusel_o <= `EXE_RES_LOAD_STORE;     
                    reg1_read_o <= `ReadEnable;     
                    reg2_read_o <= `ReadEnable;           
                    instvalid <= `InstValid;
                end
                `EXE_SW:    begin                   //sw
                    wreg_o <= `WriteDisable;         
                    aluop_o <= `EXE_SW_OP;          
                    alusel_o <= `EXE_RES_LOAD_STORE;     
                    reg1_read_o <= `ReadEnable;     
                    reg2_read_o <= `ReadEnable;           
                    instvalid <= `InstValid;
                end
                `EXE_SWL:   begin                   //swl
                    wreg_o <= `WriteDisable;         
                    aluop_o <= `EXE_SWL_OP;          
                    alusel_o <= `EXE_RES_LOAD_STORE;     
                    reg1_read_o <= `ReadEnable;     
                    reg2_read_o <= `ReadEnable;           
                    instvalid <= `InstValid;
                end
                `EXE_SWR:   begin                   //swr
                    wreg_o <= `WriteDisable;         
                    aluop_o <= `EXE_SWR_OP;          
                    alusel_o <= `EXE_RES_LOAD_STORE;     
                    reg1_read_o <= `ReadEnable;     
                    reg2_read_o <= `ReadEnable;           
                    instvalid <= `InstValid;
                end
                `EXE_SC:    begin                   //sc
                    wreg_o <= `WriteEnable;         
                    aluop_o <= `EXE_SC_OP;          
                    alusel_o <= `EXE_RES_LOAD_STORE;     
                    reg1_read_o <= `ReadEnable;     
                    reg2_read_o <= `ReadEnable;    
                    wd_o <= inst_i[20:16];       
                    instvalid <= `InstValid;
                end
                default:begin
                end
            endcase
                
            if(inst_i[31:21] == 11'b000_0000_0000) begin
                if(op3 == `EXE_SLL) begin                       //sll
                    wreg_o <= `WriteEnable;
                    aluop_o <= `EXE_SLL_OP;
                    alusel_o <= `EXE_RES_SHIFT;
                    reg1_read_o <= `ReadDisable;
                    reg2_read_o <= `ReadEnable;
                    imm[4:0] <= inst_i[10:6];
                    wd_o <= inst_i[15:11];
                    instvalid <= `InstValid;
                end else if(op3 == `EXE_SRL) begin              //srl
                    wreg_o <= `WriteEnable;
                    aluop_o <= `EXE_SRL_OP;
                    alusel_o <= `EXE_RES_SHIFT;
                    reg1_read_o <= `ReadDisable;
                    reg2_read_o <= `ReadEnable;
                    imm[4:0] <= inst_i[10:6];
                    wd_o <= inst_i[15:11];
                    instvalid <= `InstValid;
                end else if(op3 == `EXE_SRA) begin              //sra
                    wreg_o <= `WriteEnable;
                    aluop_o <= `EXE_SRA_OP;
                    alusel_o <= `EXE_RES_SHIFT;
                    reg1_read_o <= `ReadDisable;
                    reg2_read_o <= `ReadEnable;
                    imm[4:0] <= inst_i[10:6];
                    wd_o <= inst_i[15:11];
                    instvalid <= `InstValid;
                end
            end
        end
    end

    
    always @(*) begin
        stallreq_for_reg1_loadrelate <= `NoStop;
        if(rst == `RstEnable) begin
            reg1_o <= `ZeroWord;    
        end else if(pre_inst_is_load == 1'b1 && ex_wd_i == reg1_addr_o 
								&& reg1_read_o == 1'b1 ) begin
		  stallreq_for_reg1_loadrelate <= `Stop;							
		end else if((reg1_read_o == 1'b1) && (ex_wreg_i == 1'b1) &&
                    (ex_wd_i == reg1_addr_o)) begin
            reg1_o <= ex_wdata_i;
        end else if((reg1_read_o == 1'b1) && (mem_wreg_i == 1'b1) &&
                    (mem_wd_i == reg1_addr_o)) begin
            reg1_o <= mem_wdata_i;
        end else if(reg1_read_o == 1'b1) begin
            reg1_o <= reg1_data_i;
        end else if(reg1_read_o == 1'b0) begin
            reg1_o <= imm;
        end else begin
            reg1_o <= `ZeroWord;
        end
    end

    always @(*) begin
        stallreq_for_reg2_loadrelate <= `NoStop;
        if(rst == `RstEnable) begin
            reg2_o <= `ZeroWord;
        end else if(pre_inst_is_load == 1'b1 && ex_wd_i == reg2_addr_o 
								&& reg2_read_o == 1'b1 ) begin
		  stallreq_for_reg2_loadrelate <= `Stop;			
		end else if((reg2_read_o == 1'b1) && (ex_wreg_i == 1'b1) &&
                    (ex_wd_i == reg2_addr_o)) begin
            reg2_o <= ex_wdata_i;
        end else if((reg2_read_o == 1'b1) && (mem_wreg_i == 1'b1) &&
                    (mem_wd_i == reg2_addr_o)) begin
            reg2_o <= mem_wdata_i;
        end  else if(reg2_read_o == 1'b1) begin
            reg2_o <= reg2_data_i;
        end else if(reg2_read_o == 1'b0) begin
            reg2_o <= imm;
        end else begin
            reg2_o <= `ZeroWord;
        end
    end

    //输出变量is_in_delayslot_o表示当前译码阶段指令是否是延迟槽指令
    always @(*) begin
        if(rst == `RstEnable) begin
            is_in_delayslot_o <= `NotInDelaySlot;
        end else begin
            is_in_delayslot_o <= is_in_delayslot_i;
        end
    end

endmodule